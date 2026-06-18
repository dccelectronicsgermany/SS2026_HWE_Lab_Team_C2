library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Central Scheduler FSM.
-- Drives the full patient lifecycle:
--   IDLE -> RECEIVE_PATIENT -> TRIAGE -> CHECK_RESOURCES
--        -> ALLOCATE_ROOM -> ALLOCATE_DOCTOR -> ALLOCATE_EQUIPMENT
--        -> DISPATCH_TEAM -> MONITOR_TREATMENT -> RELEASE_RESOURCES -> IDLE
-- On resource exhaustion or safety fault -> FAULT state.
--
-- BTN2 (step) advances the FSM one state per press for demo purposes.
-- BTN3 (emergency override) forces severity to "11" (Critical) before TRIAGE.
-- MONITOR_TREATMENT uses a down-counter as a simulated treatment timer;
-- the counter length is proportional to severity so critical patients
-- hold the state longer, making the demo visible on LEDs.

entity scheduler_fsm is
    generic (
        CLK_FREQ : natural := 100_000_000
    );
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;

        -- patient inputs (from patient_generator / priority_encoder)
        patient_valid    : in  std_logic;
        patient_id       : in  std_logic_vector(3 downto 0);
        patient_severity : in  std_logic_vector(1 downto 0);
        patient_type     : in  std_logic_vector(1 downto 0);
        priority         : in  std_logic_vector(2 downto 0);

        -- resource availability (from resource_manager)
        no_room          : in  std_logic;
        no_doctor        : in  std_logic;
        no_equipment     : in  std_logic;
        room_idx         : in  std_logic_vector(2 downto 0);
        doctor_idx       : in  std_logic_vector(2 downto 0);
        equipment_idx    : in  std_logic_vector(2 downto 0);

        -- external fault from safety supervisor
        fault_in         : in  std_logic;

        -- buttons
        btn_step         : in  std_logic;   -- BTN2
        btn_override     : in  std_logic;   -- BTN3

        -- resource manager control signals
        alloc_room       : out std_logic;
        alloc_doctor     : out std_logic;
        alloc_equipment  : out std_logic;
        rel_room         : out std_logic;
        rel_doctor       : out std_logic;
        rel_equipment    : out std_logic;
        room_rel_idx     : out std_logic_vector(2 downto 0);
        doc_rel_idx      : out std_logic_vector(2 downto 0);
        equip_rel_idx    : out std_logic_vector(2 downto 0);

        -- current assignments (for display)
        curr_patient_id  : out std_logic_vector(3 downto 0);
        curr_priority    : out std_logic_vector(2 downto 0);
        curr_room        : out std_logic_vector(2 downto 0);
        curr_doctor      : out std_logic_vector(2 downto 0);
        curr_equipment   : out std_logic_vector(2 downto 0);

        -- status flags
        treatment_active : out std_logic;
        critical_flag    : out std_logic;
        fault_out        : out std_logic;

        -- FSM state code for 7-seg display (4 bits cover 11 states)
        fsm_state_code   : out std_logic_vector(3 downto 0)
    );
end scheduler_fsm;

architecture rtl of scheduler_fsm is

    type state_t is (
        IDLE, RECEIVE_PATIENT, TRIAGE, CHECK_RESOURCES,
        ALLOCATE_ROOM, ALLOCATE_DOCTOR, ALLOCATE_EQUIPMENT,
        DISPATCH_TEAM, MONITOR_TREATMENT, RELEASE_RESOURCES, FAULT
    );

    signal state, next_state : state_t := IDLE;

    -- latched patient info
    signal reg_id       : std_logic_vector(3 downto 0) := (others => '0');
    signal reg_sev      : std_logic_vector(1 downto 0) := (others => '0');
    signal reg_type     : std_logic_vector(1 downto 0) := (others => '0');
    signal reg_priority : std_logic_vector(2 downto 0) := (others => '0');

    -- latched resource assignments
    signal reg_room     : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_doctor   : std_logic_vector(2 downto 0) := (others => '0');
    signal reg_equip    : std_logic_vector(2 downto 0) := (others => '0');

    -- treatment timer: 1-4 × CLK_FREQ cycles (1-4 s at 100 MHz; shorter in sim)
    signal treat_cnt    : unsigned(28 downto 0) := (others => '0');
    signal treat_load   : unsigned(28 downto 0);

    -- step-button edge detector
    signal step_prev    : std_logic := '0';
    signal step_sync0   : std_logic := '0';
    signal step_sync1   : std_logic := '0';
    signal step_pulse   : std_logic;

    -- override button edge detector
    signal ovr_prev     : std_logic := '0';
    signal ovr_sync0    : std_logic := '0';
    signal ovr_sync1    : std_logic := '0';

    signal override_active : std_logic := '0';

    -- one-shot flag: prevents alloc/release pulses from firing more than once per state visit
    signal alloc_sent : std_logic := '0';

begin
    -- treatment timer load value based on severity
    treat_load <= to_unsigned(CLK_FREQ,     29) when reg_sev = "00" else
                  to_unsigned(CLK_FREQ * 2, 29) when reg_sev = "01" else
                  to_unsigned(CLK_FREQ * 3, 29) when reg_sev = "10" else
                  to_unsigned(CLK_FREQ * 4, 29);

    -- step button synchroniser + edge
    step_pulse <= step_sync1 and not step_prev;

    -- drive output registers
    curr_patient_id <= reg_id;
    curr_priority   <= reg_priority;
    curr_room       <= reg_room;
    curr_doctor     <= reg_doctor;
    curr_equipment  <= reg_equip;
    room_rel_idx    <= reg_room;
    doc_rel_idx     <= reg_doctor;
    equip_rel_idx   <= reg_equip;

    -- FSM state code for 7-seg
    with state select fsm_state_code <=
        "0000" when IDLE,
        "0001" when RECEIVE_PATIENT,
        "0010" when TRIAGE,
        "0011" when CHECK_RESOURCES,
        "0100" when ALLOCATE_ROOM,
        "0101" when ALLOCATE_DOCTOR,
        "0110" when ALLOCATE_EQUIPMENT,
        "0111" when DISPATCH_TEAM,
        "1000" when MONITOR_TREATMENT,
        "1001" when RELEASE_RESOURCES,
        "1111" when FAULT,
        "0000" when others;

    -- sequential logic
    process(clk)
    begin
        if rising_edge(clk) then
            -- default pulse outputs (de-assert every cycle)
            alloc_room      <= '0';
            alloc_doctor    <= '0';
            alloc_equipment <= '0';
            rel_room        <= '0';
            rel_doctor      <= '0';
            rel_equipment   <= '0';

            -- synchronise buttons
            step_sync0 <= btn_step;
            step_sync1 <= step_sync0;
            step_prev  <= step_sync1;

            ovr_sync0  <= btn_override;
            ovr_sync1  <= ovr_sync0;
            ovr_prev   <= ovr_sync1;

            if reset = '1' then
                state          <= IDLE;
                reg_id         <= (others => '0');
                reg_sev        <= (others => '0');
                reg_type       <= (others => '0');
                reg_priority   <= (others => '0');
                reg_room       <= (others => '0');
                reg_doctor     <= (others => '0');
                reg_equip      <= (others => '0');
                treat_cnt      <= (others => '0');
                override_active<= '0';
                treatment_active <= '0';
                critical_flag    <= '0';
                fault_out        <= '0';
                alloc_sent       <= '0';
            else
                -- emergency override latch
                if ovr_sync1 = '1' and ovr_prev = '0' then
                    override_active <= '1';
                end if;

                -- global fault injection from safety supervisor
                if fault_in = '1' and state /= FAULT then
                    state     <= FAULT;
                    fault_out <= '1';
                end if;

                case state is

                    when IDLE =>
                        treatment_active <= '0';
                        critical_flag    <= '0';
                        fault_out        <= '0';
                        if patient_valid = '1' then
                            state <= RECEIVE_PATIENT;
                        end if;

                    when RECEIVE_PATIENT =>
                        reg_id   <= patient_id;
                        reg_type <= patient_type;
                        if override_active = '1' then
                            -- latch Critical and clear flag; wait for next step to advance
                            reg_sev         <= "11";
                            override_active <= '0';
                        elsif step_pulse = '1' then
                            -- only write patient_severity if override didn't already set it
                            if reg_sev /= "11" then
                                reg_sev <= patient_severity;
                            end if;
                            state <= TRIAGE;
                        end if;

                    when TRIAGE =>
                        reg_priority <= priority;
                        critical_flag <= '1' when reg_sev = "11" else '0';
                        if step_pulse = '1' then
                            state <= CHECK_RESOURCES;
                        end if;

                    when CHECK_RESOURCES =>
                        if no_room = '1' or no_doctor = '1' or no_equipment = '1' then
                            state     <= FAULT;
                            fault_out <= '1';
                        elsif step_pulse = '1' then
                            state <= ALLOCATE_ROOM;
                        end if;

                    when ALLOCATE_ROOM =>
                        if alloc_sent = '0' then
                            alloc_room  <= '1';
                            reg_room    <= room_idx;
                            alloc_sent  <= '1';
                        end if;
                        if step_pulse = '1' then
                            alloc_sent <= '0';
                            state      <= ALLOCATE_DOCTOR;
                        end if;

                    when ALLOCATE_DOCTOR =>
                        if alloc_sent = '0' then
                            alloc_doctor <= '1';
                            reg_doctor   <= doctor_idx;
                            alloc_sent   <= '1';
                        end if;
                        if step_pulse = '1' then
                            alloc_sent <= '0';
                            state      <= ALLOCATE_EQUIPMENT;
                        end if;

                    when ALLOCATE_EQUIPMENT =>
                        if alloc_sent = '0' then
                            alloc_equipment <= '1';
                            reg_equip       <= equipment_idx;
                            alloc_sent      <= '1';
                        end if;
                        if step_pulse = '1' then
                            alloc_sent <= '0';
                            state      <= DISPATCH_TEAM;
                        end if;

                    when DISPATCH_TEAM =>
                        treatment_active <= '1';
                        treat_cnt        <= treat_load;
                        if step_pulse = '1' then
                            state <= MONITOR_TREATMENT;
                        end if;

                    when MONITOR_TREATMENT =>
                        if treat_cnt = 0 then
                            state <= RELEASE_RESOURCES;
                        else
                            treat_cnt <= treat_cnt - 1;
                        end if;

                    when RELEASE_RESOURCES =>
                        if alloc_sent = '0' then
                            rel_room         <= '1';
                            rel_doctor       <= '1';
                            rel_equipment    <= '1';
                            treatment_active <= '0';
                            alloc_sent       <= '1';
                        end if;
                        if step_pulse = '1' then
                            alloc_sent <= '0';
                            state      <= IDLE;
                        end if;

                    when FAULT =>
                        -- hold fault until reset
                        fault_out <= '1';

                    when others =>
                        state <= IDLE;

                end case;
            end if;
        end if;
    end process;
end rtl;
