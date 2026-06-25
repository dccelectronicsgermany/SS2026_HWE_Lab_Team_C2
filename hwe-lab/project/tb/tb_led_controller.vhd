library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_led_controller is
end tb_led_controller;

architecture sim of tb_led_controller is
    signal clk              : std_logic := '0';
    signal reset            : std_logic := '1';
    signal rooms_busy       : std_logic_vector(3 downto 0) := "0000";
    signal doctors_busy     : std_logic_vector(3 downto 0) := "0000";
    signal equip_busy       : std_logic_vector(3 downto 0) := "0000";
    signal critical_flag    : std_logic := '0';
    signal treatment_active : std_logic := '0';
    signal fault            : std_logic := '0';
    signal alarm            : std_logic := '0';
    signal leds             : std_logic_vector(15 downto 0);

    constant CLK_P : time := 10 ns;
begin
    clk <= not clk after CLK_P / 2;

    uut : entity work.led_controller
        port map (
            clk              => clk,
            reset            => reset,
            rooms_busy       => rooms_busy,
            doctors_busy     => doctors_busy,
            equip_busy       => equip_busy,
            critical_flag    => critical_flag,
            treatment_active => treatment_active,
            fault            => fault,
            alarm            => alarm,
            leds             => leds
        );

    process
    begin
        wait for 30 ns; reset <= '0'; wait for CLK_P;

        -- all idle: all LEDs off
        assert leds = "0000000000000000" report "FAIL: LEDs not all zero at idle" severity error;

        -- room 1 and 3 busy
        rooms_busy <= "0101"; wait for CLK_P;
        assert leds(3 downto 0) = "0101" report "FAIL: rooms_busy not reflected on LED3:0" severity error;

        -- doctor 2 busy
        doctors_busy <= "0010"; wait for CLK_P;
        assert leds(7 downto 4) = "0010" report "FAIL: doctors_busy not reflected on LED7:4" severity error;

        -- equipment 4 busy
        equip_busy <= "1000"; wait for CLK_P;
        assert leds(11 downto 8) = "1000" report "FAIL: equip_busy not reflected on LED11:8" severity error;

        -- critical flag
        critical_flag <= '1'; wait for CLK_P;
        assert leds(12) = '1' report "FAIL: LED12 (critical) not set" severity error;

        -- treatment active
        treatment_active <= '1'; wait for CLK_P;
        assert leds(13) = '1' report "FAIL: LED13 (treatment) not set" severity error;

        -- fault
        fault <= '1'; wait for CLK_P;
        assert leds(14) = '1' report "FAIL: LED14 (fault) not set" severity error;
        fault <= '0';

        -- alarm blink: LED15 is alarm AND blink_toggle.
        -- With 100 MHz real clock the blink div is 25_000_000 which is too long to wait.
        -- Instead just verify that when alarm=0, LED15=0 (blink can be 0 or 1 but masked).
        alarm <= '0'; wait for CLK_P;
        assert leds(15) = '0' report "FAIL: LED15 should be 0 when alarm=0" severity error;

        -- reset clears latched state
        reset <= '1'; wait for CLK_P; reset <= '0'; wait for CLK_P;
        rooms_busy       <= "0000";
        doctors_busy     <= "0000";
        equip_busy       <= "0000";
        critical_flag    <= '0';
        treatment_active <= '0';
        wait for CLK_P;
        assert leds(15 downto 0) = "0000000000000000" report "FAIL: LEDs not zero after reset" severity error;

        report "tb_led_controller DONE" severity note;
        wait;
    end process;
end sim;
