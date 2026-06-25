library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Top-level: instantiates and wires all modules.
-- Board pin names follow the Nexys A7 master XDC convention.
--
-- Inputs:
--   CLK100MHZ  - 100 MHz system clock
--   CPU_RESETN - active-low reset button
--   SW[7:0]    - slide switches
--   BTNL       - new patient
--   BTNC       - step FSM
--   BTNR       - emergency override
--   BTNU       - park (skip release, keeps resources busy for multi-patient demo)
--
-- NOTE: Nexys A7 active-low reset is CPU_RESETN; invert it internally.

entity top_level is
    generic (
        CLK_FREQ : natural := 100_000_000
    );
    port (
        CLK100MHZ  : in  std_logic;
        CPU_RESETN : in  std_logic;

        SW         : in  std_logic_vector(7 downto 0);
        BTNL       : in  std_logic;   -- new patient
        BTNC       : in  std_logic;   -- step FSM
        BTNR       : in  std_logic;   -- emergency override
        BTNU       : in  std_logic;   -- park patient (save to table, keep resources busy)
        BTND       : in  std_logic;   -- release mode: BTND + SW[1:0] + BTNC releases a slot

        LED        : out std_logic_vector(15 downto 0);
        AN         : out std_logic_vector(7 downto 0);
        SEG        : out std_logic_vector(6 downto 0);
        DP         : out std_logic;

        UART_TXD_IN : out std_logic
    );
end top_level;

architecture structural of top_level is

    signal reset         : std_logic;

    -- patient generator <-> priority encoder <-> FSM
    signal pat_valid     : std_logic;
    signal pat_id        : std_logic_vector(3 downto 0);
    signal pat_type      : std_logic_vector(1 downto 0);
    signal pat_sev       : std_logic_vector(1 downto 0);
    signal priority      : std_logic_vector(2 downto 0);

    -- FSM <-> resource manager (alloc)
    signal alloc_room    : std_logic;
    signal alloc_doctor  : std_logic;
    signal alloc_equip   : std_logic;

    -- FSM release signals (normal flow: RELEASE_RESOURCES state)
    signal fsm_rel_room      : std_logic;
    signal fsm_rel_doctor    : std_logic;
    signal fsm_rel_equip     : std_logic;
    signal fsm_room_rel_idx  : std_logic_vector(2 downto 0);
    signal fsm_doc_rel_idx   : std_logic_vector(2 downto 0);
    signal fsm_equip_rel_idx : std_logic_vector(2 downto 0);

    -- merged release signals to resource manager (FSM OR patient_table)
    signal rel_room      : std_logic;
    signal rel_doctor    : std_logic;
    signal rel_equip     : std_logic;
    signal room_rel_idx  : std_logic_vector(2 downto 0);
    signal doc_rel_idx   : std_logic_vector(2 downto 0);
    signal equip_rel_idx : std_logic_vector(2 downto 0);
    signal room_idx      : std_logic_vector(2 downto 0);
    signal doctor_idx    : std_logic_vector(2 downto 0);
    signal equip_idx     : std_logic_vector(2 downto 0);
    signal no_room       : std_logic;
    signal no_doctor     : std_logic;
    signal no_equip      : std_logic;
    signal rooms_busy    : std_logic_vector(3 downto 0);
    signal doctors_busy  : std_logic_vector(3 downto 0);
    signal equip_busy    : std_logic_vector(3 downto 0);

    -- FSM outputs
    signal curr_id        : std_logic_vector(3 downto 0);
    signal curr_sev       : std_logic_vector(1 downto 0);
    signal curr_prio      : std_logic_vector(2 downto 0);
    signal curr_room      : std_logic_vector(2 downto 0);
    signal curr_doc       : std_logic_vector(2 downto 0);
    signal curr_equip     : std_logic_vector(2 downto 0);
    signal treat_active   : std_logic;
    signal crit_flag      : std_logic;
    signal fault_out      : std_logic;
    signal fsm_state_code : std_logic_vector(3 downto 0);

    -- safety supervisor
    signal fault_sv       : std_logic;
    signal alarm_sv       : std_logic;

    -- patient table
    signal park_en        : std_logic;
    signal pt_rel_room    : std_logic;
    signal pt_rel_doc     : std_logic;
    signal pt_rel_equip   : std_logic;
    signal pt_room_idx    : std_logic_vector(2 downto 0);
    signal pt_doc_idx     : std_logic_vector(2 downto 0);
    signal pt_equip_idx   : std_logic_vector(2 downto 0);
    signal occupied_mask  : std_logic_vector(3 downto 0);
    signal slot_num       : std_logic_vector(2 downto 0);

    -- release trigger: BTND synchroniser + edge + gate with BTNC
    signal btnd_sync0     : std_logic := '0';
    signal btnd_sync1     : std_logic := '0';
    signal btnc_sync0     : std_logic := '0';
    signal btnc_sync1     : std_logic := '0';
    signal btnc_prev      : std_logic := '0';
    signal btnc_pulse     : std_logic;
    signal rel_en         : std_logic;

    -- gated step signal: BTNC blocked when BTND held (release mode)
    signal btn_step_gated : std_logic;

    -- UART
    signal uart_tx_data  : std_logic_vector(7 downto 0);
    signal uart_tx_send  : std_logic;
    signal uart_tx_busy  : std_logic;

    signal uart_seq      : natural range 0 to 3 := 0;
    signal dispatch_prev : std_logic := '0';

begin
    reset <= not CPU_RESETN;
    DP    <= '1';  -- decimal point off (active low on Nexys A7)

    -- OR-merge release sources: FSM normal release OR patient_table selective release
    -- Indices: patient_table wins when it fires (FSM never fires simultaneously)
    rel_room      <= fsm_rel_room   or pt_rel_room;
    rel_doctor    <= fsm_rel_doctor or pt_rel_doc;
    rel_equip     <= fsm_rel_equip  or pt_rel_equip;
    room_rel_idx  <= pt_room_idx  when pt_rel_room   = '1' else fsm_room_rel_idx;
    doc_rel_idx   <= pt_doc_idx   when pt_rel_doc    = '1' else fsm_doc_rel_idx;
    equip_rel_idx <= pt_equip_idx when pt_rel_equip  = '1' else fsm_equip_rel_idx;

    -- rel_en: BTND held high AND BTNC rising edge -> release selected slot
    btnc_pulse    <= btnc_sync1 and (not btnc_prev);
    rel_en        <= btnd_sync1 and btnc_pulse;
    btn_step_gated <= BTNC and (not BTND);

    u_pat_gen : entity work.patient_generator
        port map (
            clk              => CLK100MHZ,
            reset            => reset,
            btn_new          => BTNL,
            sw_severity      => SW(1 downto 0),
            sw_type          => SW(3 downto 2),
            sw_id            => SW(7 downto 4),
            patient_valid    => pat_valid,
            patient_id       => pat_id,
            patient_type     => pat_type,
            patient_severity => pat_sev
        );

    u_prio : entity work.priority_encoder
        port map (
            sev_in   => pat_sev,
            type_in  => pat_type,
            prio_out => priority
        );

    u_res : entity work.resource_manager
        port map (
            clk             => CLK100MHZ,
            reset           => reset,
            alloc_room      => alloc_room,
            alloc_doctor    => alloc_doctor,
            alloc_equipment => alloc_equip,
            rel_room        => rel_room,
            rel_doctor      => rel_doctor,
            rel_equipment   => rel_equip,
            room_rel_idx    => room_rel_idx,
            doc_rel_idx     => doc_rel_idx,
            equip_rel_idx   => equip_rel_idx,
            room_idx        => room_idx,
            doctor_idx      => doctor_idx,
            equipment_idx   => equip_idx,
            rooms_busy      => rooms_busy,
            doctors_busy    => doctors_busy,
            equip_busy      => equip_busy,
            no_room         => no_room,
            no_doctor       => no_doctor,
            no_equipment    => no_equip
        );

    u_fsm : entity work.scheduler_fsm
        generic map (CLK_FREQ => CLK_FREQ)
        port map (
            clk              => CLK100MHZ,
            reset            => reset,
            patient_valid    => pat_valid,
            patient_id       => pat_id,
            patient_severity => pat_sev,
            patient_type     => pat_type,
            priority         => priority,
            no_room          => no_room,
            no_doctor        => no_doctor,
            no_equipment     => no_equip,
            room_idx         => room_idx,
            doctor_idx       => doctor_idx,
            equipment_idx    => equip_idx,
            fault_in         => fault_sv,
            btn_step         => btn_step_gated,
            btn_override     => BTNR,
            btn_park         => BTNU,
            park_en          => park_en,
            alloc_room       => alloc_room,
            alloc_doctor     => alloc_doctor,
            alloc_equipment  => alloc_equip,
            rel_room         => fsm_rel_room,
            rel_doctor       => fsm_rel_doctor,
            rel_equipment    => fsm_rel_equip,
            room_rel_idx     => fsm_room_rel_idx,
            doc_rel_idx      => fsm_doc_rel_idx,
            equip_rel_idx    => fsm_equip_rel_idx,
            curr_patient_id  => curr_id,
            curr_severity    => curr_sev,
            curr_priority    => curr_prio,
            curr_room        => curr_room,
            curr_doctor      => curr_doc,
            curr_equipment   => curr_equip,
            treatment_active => treat_active,
            critical_flag    => crit_flag,
            fault_out        => fault_out,
            fsm_state_code   => fsm_state_code
        );

    u_ptbl : entity work.patient_table
        port map (
            clk           => CLK100MHZ,
            reset         => reset,
            park_en       => park_en,
            park_room     => curr_room,
            park_doc      => curr_doc,
            park_equip    => curr_equip,
            slot_num      => slot_num,
            rel_en        => rel_en,
            slot_sel      => SW(1 downto 0),
            rel_room      => pt_rel_room,
            rel_doctor    => pt_rel_doc,
            rel_equipment => pt_rel_equip,
            room_rel_idx  => pt_room_idx,
            doc_rel_idx   => pt_doc_idx,
            equip_rel_idx => pt_equip_idx,
            occupied_mask => occupied_mask
        );

    u_safe : entity work.safety_supervisor
        port map (
            clk             => CLK100MHZ,
            reset           => reset,
            rooms_busy      => rooms_busy,
            doctors_busy    => doctors_busy,
            equip_busy      => equip_busy,
            alloc_room      => alloc_room,
            alloc_doctor    => alloc_doctor,
            alloc_equipment => alloc_equip,
            no_room         => no_room,
            no_doctor       => no_doctor,
            no_equipment    => no_equip,
            fsm_state_code  => fsm_state_code,
            fault           => fault_sv,
            alarm           => alarm_sv
        );

    u_led : entity work.led_controller
        port map (
            clk              => CLK100MHZ,
            reset            => reset,
            rooms_busy       => rooms_busy,
            doctors_busy     => doctors_busy,
            equip_busy       => equip_busy,
            critical_flag    => crit_flag,
            treatment_active => treat_active,
            fault            => fault_out,
            alarm            => alarm_sv,
            leds             => LED
        );

    u_seg : entity work.seven_segment_driver
        port map (
            clk           => CLK100MHZ,
            reset         => reset,
            patient_id    => curr_id,
            sev_level     => curr_sev,
            room_num      => curr_room,
            doctor_num    => curr_doc,
            fsm_state     => fsm_state_code,
            fault_code    => fault_out,
            critical_flag => crit_flag,
            an            => AN,
            seg           => SEG
        );

    u_uart : entity work.uart_controller
        port map (
            clk     => CLK100MHZ,
            reset   => reset,
            tx_data => uart_tx_data,
            tx_send => uart_tx_send,
            tx_busy => uart_tx_busy,
            tx_pin  => UART_TXD_IN
        );

    -- BTND + BTNC synchronisers for selective release
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            btnd_sync0 <= BTND;
            btnd_sync1 <= btnd_sync0;
            btnc_sync0 <= BTNC;
            btnc_sync1 <= btnc_sync0;
            btnc_prev  <= btnc_sync1;
        end if;
    end process;

    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            uart_tx_send  <= '0';
            dispatch_prev <= treat_active;

            if reset = '1' then
                uart_seq      <= 0;
                dispatch_prev <= '0';
            elsif treat_active = '1' and dispatch_prev = '0' then
                uart_seq <= 1;
            end if;

            if uart_tx_busy = '0' then
                case uart_seq is
                    when 1 =>
                        uart_tx_data <= x"50";  -- 'P'
                        uart_tx_send <= '1';
                        uart_seq     <= 2;
                    when 2 =>
                        case curr_id is
                            when "0000" => uart_tx_data <= x"30";
                            when "0001" => uart_tx_data <= x"31";
                            when "0010" => uart_tx_data <= x"32";
                            when "0011" => uart_tx_data <= x"33";
                            when "0100" => uart_tx_data <= x"34";
                            when "0101" => uart_tx_data <= x"35";
                            when "0110" => uart_tx_data <= x"36";
                            when "0111" => uart_tx_data <= x"37";
                            when "1000" => uart_tx_data <= x"38";
                            when "1001" => uart_tx_data <= x"39";
                            when "1010" => uart_tx_data <= x"41";
                            when "1011" => uart_tx_data <= x"42";
                            when "1100" => uart_tx_data <= x"43";
                            when "1101" => uart_tx_data <= x"44";
                            when "1110" => uart_tx_data <= x"45";
                            when others => uart_tx_data <= x"46";
                        end case;
                        uart_tx_send <= '1';
                        uart_seq     <= 3;
                    when 3 =>
                        uart_tx_data <= x"0D";  -- CR
                        uart_tx_send <= '1';
                        uart_seq     <= 0;
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

end structural;
