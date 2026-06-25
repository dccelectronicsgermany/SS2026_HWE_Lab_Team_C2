library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Multiplexed 8-digit seven-segment driver for Nexys A7.
-- The Nexys A7 uses active-low anodes and active-low cathode segments.
-- Digits are time-multiplexed at ~1 kHz (100 MHz / 100000).
--
-- Digit assignments, physically read from left to right on Nexys A7: AN7..AN0
--   AN7 -> FSM state (0-9, F=fault)
--   AN6 -> E when emergency/critical/fault is active, otherwise blank
--   AN5 -> d label for doctor
--   AN4 -> doctor number 1-4
--   AN3 -> r label for room
--   AN2 -> room number 1-4
--   AN1 -> sev_level label: n=Normal, U=Urgent, H=High, C=Critical
--   AN0 -> patient ID hex
--
-- Example display:  4 E d 1 r 2 C F
-- means FSM state 4 (ALLOCATE_ROOM), emergency/critical, doctor 1, room 2, Critical sev_level, patient F.

entity seven_segment_driver is
    port (
        clk           : in  std_logic;
        reset         : in  std_logic;

        patient_id    : in  std_logic_vector(3 downto 0);
        sev_level      : in  std_logic_vector(1 downto 0);  -- 00=Normal 01=Urgent 10=High 11=Critical
        room_num      : in  std_logic_vector(2 downto 0);
        doctor_num    : in  std_logic_vector(2 downto 0);
        fsm_state     : in  std_logic_vector(3 downto 0);
        fault_code    : in  std_logic;
        critical_flag : in  std_logic;

        an            : out std_logic_vector(7 downto 0);  -- active-low anodes
        seg           : out std_logic_vector(6 downto 0)   -- active-low segments (CA)
    );
end seven_segment_driver;

architecture rtl of seven_segment_driver is
    constant MUX_DIV : natural := 100_000;  -- 100 MHz / 100000 = 1 kHz mux rate

    signal div_cnt   : natural range 0 to MUX_DIV - 1 := 0;
    signal digit_sel : unsigned(2 downto 0) := (others => '0');
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
            when "1101" => return "0100001"; -- d / D
            when "1110" => return "0000110"; -- E
            when "1111" => return "0001110"; -- F
            when others => return "1111111"; -- blank
        end case;
    end function;

    function letter_to_seg(ch : character) return std_logic_vector is
    begin
        case ch is
            when 'd'    => return "0100001"; -- d / doctor label
            when 'r'    => return "0101111"; -- r / room label
            when 'E'    => return "0000110"; -- E / emergency label
            when 'n'    => return "0101011"; -- n / Normal
            when 'U'    => return "1000001"; -- U / Urgent
            when 'H'    => return "0001001"; -- H / High
            when 'C'    => return "1000110"; -- C / Critical
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
                tick      <= '0';
            else
                tick <= '0';
                if div_cnt = MUX_DIV - 1 then
                    div_cnt   <= 0;
                    tick      <= '1';
                    digit_sel <= digit_sel + 1;
                else
                    div_cnt <= div_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- digit data mux (label digits handled entirely in seg process)
    with digit_sel select digit_val <=
        patient_id       when "000",  -- AN0 rightmost: patient ID
        "0000"           when "001",  -- AN1: sev_level label (handled in seg process)
        '0' & room_num   when "010",  -- AN2: room number
        "0000"           when "011",  -- AN3: r label (handled in seg process)
        '0' & doctor_num when "100",  -- AN4: doctor number
        "0000"           when "101",  -- AN5: d label (handled in seg process)
        "0000"           when "110",  -- AN6: E/blank label (handled in seg process)
        fsm_state        when "111",  -- AN7 leftmost: FSM state 0-9, F=fault
        "0000"           when others;

    -- anode select (active low: one digit enabled at a time, all 8 active)
    process(digit_sel)
    begin
        an <= "11111111";
        an(to_integer(digit_sel)) <= '0';
    end process;

    -- segment pattern: label digits handled here, numeric digits via hex_to_seg
    process(digit_sel, digit_val, sev_level, critical_flag, fault_code)
    begin
        case digit_sel is
            when "001" =>   -- AN1: sev_level label
                case sev_level is
                    when "00"   => seg <= letter_to_seg('n'); -- Normal
                    when "01"   => seg <= letter_to_seg('U'); -- Urgent
                    when "10"   => seg <= letter_to_seg('H'); -- High
                    when "11"   => seg <= letter_to_seg('C'); -- Critical
                    when others => seg <= "1111111";
                end case;
            when "011" =>   -- AN3: r label
                seg <= letter_to_seg('r');
            when "101" =>   -- AN5: d label
                seg <= letter_to_seg('d');
            when "110" =>   -- AN6: E on critical or fault, blank otherwise
                if critical_flag = '1' or fault_code = '1' then
                    seg <= letter_to_seg('E');
                else
                    seg <= "1111111";
                end if;
            when others =>
                seg <= hex_to_seg(digit_val);
        end case;
    end process;

end rtl;
