library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Multiplexed 8-digit seven-segment driver for Nexys A7.
-- The Nexys A7 uses active-low anodes and active-low cathode segments.
-- Digits are time-multiplexed at ~1 kHz (100 MHz / 100000).
--
-- Digit assignments (AN7..AN0):
--   AN0 -> patient ID  (4-bit hex)
--   AN1 -> priority    (3-bit, shown as 0-4)
--   AN2 -> room number (1-4, or 0 = none)
--   AN3 -> doctor      (1-4, or 0 = none)
--   AN4 -> equipment   (1-4, or 0 = none)
--   AN5 -> FSM state   (hex 0-9, F=fault)
--   AN6 -> fault code  (0=ok, 1=fault)
--   AN7 -> system counter (free-running 0-F for life sign)

entity seven_segment_driver is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;

        patient_id   : in  std_logic_vector(3 downto 0);
        priority     : in  std_logic_vector(2 downto 0);
        room_num     : in  std_logic_vector(2 downto 0);
        doctor_num   : in  std_logic_vector(2 downto 0);
        equip_num    : in  std_logic_vector(2 downto 0);
        fsm_state    : in  std_logic_vector(3 downto 0);
        fault_code   : in  std_logic;

        an           : out std_logic_vector(7 downto 0);  -- active-low anodes
        seg          : out std_logic_vector(6 downto 0)   -- active-low segments (CA)
    );
end seven_segment_driver;

architecture rtl of seven_segment_driver is
    constant MUX_DIV : natural := 100_000;  -- 100 MHz / 100000 = 1 kHz mux rate

    signal div_cnt   : natural range 0 to MUX_DIV - 1 := 0;
    signal digit_sel : unsigned(2 downto 0) := (others => '0');
    signal sys_cnt   : unsigned(3 downto 0) := (others => '0');
    signal tick      : std_logic := '0';
    signal digit_val : std_logic_vector(3 downto 0);

    -- hex to 7-segment (active low, segment order: gfedcba)
    function hex_to_seg(h : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        case h is
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            when "1010" => return "0001000"; -- A
            when "1011" => return "0000011"; -- B
            when "1100" => return "1000110"; -- C
            when "1101" => return "0100001"; -- D
            when "1110" => return "0000110"; -- E
            when "1111" => return "0001110"; -- F
            when others => return "1111111"; -- blank
        end case;
    end function;
begin
    -- mux tick generator
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                div_cnt   <= 0;
                digit_sel <= (others => '0');
                sys_cnt   <= (others => '0');
                tick      <= '0';
            else
                tick <= '0';
                if div_cnt = MUX_DIV - 1 then
                    div_cnt   <= 0;
                    tick      <= '1';
                    digit_sel <= digit_sel + 1;
                    if digit_sel = 7 then
                        sys_cnt <= sys_cnt + 1;
                    end if;
                else
                    div_cnt <= div_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- digit data mux
    with digit_sel select digit_val <=
        patient_id                              when "000",
        '0' & priority                          when "001",
        '0' & room_num                          when "010",
        '0' & doctor_num                        when "011",
        '0' & equip_num                         when "100",
        fsm_state                               when "101",
        "000" & fault_code                      when "110",
        std_logic_vector(sys_cnt)               when "111",
        "0000"                                  when others;

    -- anode select (active low: only selected digit enabled)
    process(digit_sel)
    begin
        an <= "11111111";
        an(to_integer(digit_sel)) <= '0';
    end process;

    seg <= hex_to_seg(digit_val);
end rtl;
