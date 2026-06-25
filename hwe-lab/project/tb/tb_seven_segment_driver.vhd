library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_seven_segment_driver is
end tb_seven_segment_driver;

architecture sim of tb_seven_segment_driver is
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';
    signal patient_id    : std_logic_vector(3 downto 0) := "0011";
    signal sev_level     : std_logic_vector(1 downto 0) := "10";  -- High
    signal room_num      : std_logic_vector(2 downto 0) := "010";
    signal doctor_num    : std_logic_vector(2 downto 0) := "001";
    signal fsm_state     : std_logic_vector(3 downto 0) := "0100"; -- state 4
    signal fault_code    : std_logic := '0';
    signal critical_flag : std_logic := '0';
    signal an            : std_logic_vector(7 downto 0);
    signal seg           : std_logic_vector(6 downto 0);

    -- mux tick period: MUX_DIV=100_000 cycles at 10 ns each = 1 ms
    constant CLK_P    : time := 10 ns;
    constant MUX_TICK : time := 1_000_000 ns;  -- 100_000 * 10 ns

    -- Wait until a given anode goes active (low)
    procedure wait_for_digit(signal a : in std_logic_vector(7 downto 0);
                              digit    : natural) is
    begin
        -- poll every tick until the desired anode is low
        for i in 0 to 15 loop
            if a(digit) = '0' then return; end if;
            wait for MUX_TICK;
        end loop;
        report "TIMEOUT waiting for digit " & integer'image(digit) severity error;
    end procedure;
begin
    clk <= not clk after CLK_P / 2;

    uut : entity work.seven_segment_driver
        port map (
            clk           => clk,
            reset         => reset,
            patient_id    => patient_id,
            sev_level     => sev_level,
            room_num      => room_num,
            doctor_num    => doctor_num,
            fsm_state     => fsm_state,
            fault_code    => fault_code,
            critical_flag => critical_flag,
            an            => an,
            seg           => seg
        );

    process
    begin
        wait for 30 ns; reset <= '0';

        -- After reset: mux starts at digit 0 immediately.
        -- Wait one full mux cycle for the counter to run through all digits once.
        wait for 9 * MUX_TICK;

        -- ---- Digit 7 (AN7): FSM state code "0100" -> hex 4 -> seg "0011001" ----
        wait_for_digit(an, 7);
        assert an(7) = '0' report "FAIL: AN7 not active for digit 7" severity error;
        assert seg = "0011001" report "FAIL: seg mismatch for FSM state 4" severity error;

        -- ---- Digit 0 (AN0): patient_id "0011" -> hex 3 -> seg "0110000" ----
        wait_for_digit(an, 0);
        assert seg = "0110000" report "FAIL: seg mismatch for patient_id=3" severity error;

        -- ---- Digit 1 (AN1): sev_level "10" (High) -> letter H -> seg "0001001" ----
        wait_for_digit(an, 1);
        assert seg = "0001001" report "FAIL: seg mismatch for sev_level H" severity error;

        -- ---- Digit 2 (AN2): room_num "010" -> value 2 -> hex "0010" -> seg "0100100" ----
        wait_for_digit(an, 2);
        assert seg = "0100100" report "FAIL: seg mismatch for room_num=2" severity error;

        -- ---- Digit 3 (AN3): r label -> seg "0101111" ----
        wait_for_digit(an, 3);
        assert seg = "0101111" report "FAIL: seg mismatch for 'r' label" severity error;

        -- ---- Digit 4 (AN4): doctor_num "001" -> value 1 -> hex "0001" -> seg "1111001" ----
        wait_for_digit(an, 4);
        assert seg = "1111001" report "FAIL: seg mismatch for doctor_num=1" severity error;

        -- ---- Digit 5 (AN5): d label -> seg "0100001" ----
        wait_for_digit(an, 5);
        assert seg = "0100001" report "FAIL: seg mismatch for 'd' label" severity error;

        -- ---- Digit 6 (AN6): no critical/fault -> blank -> seg "1111111" ----
        wait_for_digit(an, 6);
        assert seg = "1111111" report "FAIL: AN6 should be blank when no critical/fault" severity error;

        -- ---- Set critical -> AN6 should show E ----
        critical_flag <= '1';
        -- wait for mux to cycle to digit 6 again
        wait_for_digit(an, 0);  -- just advance past 0
        wait_for_digit(an, 6);
        assert seg = "0000110" report "FAIL: AN6 should show E when critical_flag set" severity error;

        -- ---- Severity Critical ("11") -> letter C ----
        sev_level <= "11"; critical_flag <= '0';
        wait_for_digit(an, 0); wait_for_digit(an, 1);
        assert seg = "1000110" report "FAIL: seg mismatch for sev_level C (Critical)" severity error;

        -- ---- Severity Normal ("00") -> letter n ----
        sev_level <= "00";
        wait_for_digit(an, 0); wait_for_digit(an, 1);
        assert seg = "0101011" report "FAIL: seg mismatch for sev_level n (Normal)" severity error;

        -- ---- Severity Urgent ("01") -> letter U ----
        sev_level <= "01";
        wait_for_digit(an, 0); wait_for_digit(an, 1);
        assert seg = "1000001" report "FAIL: seg mismatch for sev_level U (Urgent)" severity error;

        report "tb_seven_segment_driver DONE" severity note;
        wait;
    end process;
end sim;
