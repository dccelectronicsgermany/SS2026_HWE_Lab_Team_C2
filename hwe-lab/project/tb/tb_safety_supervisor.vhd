library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_safety_supervisor is
end tb_safety_supervisor;

architecture sim of tb_safety_supervisor is
    signal clk             : std_logic := '0';
    signal reset           : std_logic := '1';
    signal rooms_busy      : std_logic_vector(3 downto 0) := "0000";
    signal doctors_busy    : std_logic_vector(3 downto 0) := "0000";
    signal equip_busy      : std_logic_vector(3 downto 0) := "0000";
    signal alloc_room      : std_logic := '0';
    signal alloc_doctor    : std_logic := '0';
    signal alloc_equipment : std_logic := '0';
    signal no_room         : std_logic := '0';
    signal no_doctor       : std_logic := '0';
    signal no_equipment    : std_logic := '0';
    signal fsm_state_code  : std_logic_vector(3 downto 0) := "0000";
    signal fault           : std_logic;
    signal alarm           : std_logic;

    constant CLK_P : time := 10 ns;
begin
    clk <= not clk after CLK_P / 2;

    uut : entity work.safety_supervisor
        port map (
            clk             => clk,
            reset           => reset,
            rooms_busy      => rooms_busy,
            doctors_busy    => doctors_busy,
            equip_busy      => equip_busy,
            alloc_room      => alloc_room,
            alloc_doctor    => alloc_doctor,
            alloc_equipment => alloc_equipment,
            no_room         => no_room,
            no_doctor       => no_doctor,
            no_equipment    => no_equipment,
            fsm_state_code  => fsm_state_code,
            fault           => fault,
            alarm           => alarm
        );

    process
    begin
        wait for 30 ns; reset <= '0'; wait for CLK_P;

        -- no fault in clean state
        assert fault = '0' report "FAIL: fault spurious at startup" severity error;
        assert alarm = '0' report "FAIL: alarm spurious at startup" severity error;

        -- double-alloc: alloc_room while all rooms busy
        rooms_busy   <= "1111";
        alloc_room   <= '1'; wait for CLK_P; alloc_room <= '0';
        assert fault = '1' report "FAIL: double_alloc room not detected" severity error;
        wait for CLK_P;
        assert alarm = '1' report "FAIL: alarm not latched on double_alloc" severity error;
        rooms_busy <= "0000";
        wait for CLK_P;
        assert fault = '0' report "FAIL: fault should clear after condition removed" severity error;
        assert alarm = '1' report "FAIL: alarm should stay latched" severity error;

        -- reset clears alarm
        reset <= '1'; wait for CLK_P; reset <= '0'; wait for CLK_P;
        assert alarm = '0' report "FAIL: reset did not clear alarm" severity error;

        -- double-alloc: doctor
        doctors_busy <= "1111";
        alloc_doctor <= '1'; wait for CLK_P; alloc_doctor <= '0';
        assert fault = '1' report "FAIL: double_alloc doctor not detected" severity error;
        wait for CLK_P;
        assert alarm = '1' report "FAIL: alarm not latched on doctor double_alloc" severity error;
        doctors_busy <= "0000";

        reset <= '1'; wait for CLK_P; reset <= '0'; wait for CLK_P;

        -- double-alloc: equipment
        equip_busy      <= "1111";
        alloc_equipment <= '1'; wait for CLK_P; alloc_equipment <= '0';
        assert fault = '1' report "FAIL: double_alloc equip not detected" severity error;
        wait for CLK_P;
        equip_busy <= "0000";

        reset <= '1'; wait for CLK_P; reset <= '0'; wait for CLK_P;

        -- invalid FSM state code (e.g. "1010" = 10, valid max is 9, except "1111"=FAULT)
        fsm_state_code <= "1010"; wait for CLK_P;
        assert fault = '1' report "FAIL: invalid state code not detected" severity error;
        wait for CLK_P;
        assert alarm = '1' report "FAIL: alarm not latched on invalid state" severity error;

        -- code 15 (FAULT) must NOT trigger invalid_state
        reset <= '1'; wait for CLK_P; reset <= '0'; wait for CLK_P;
        fsm_state_code <= "1111"; wait for CLK_P;
        assert fault = '0' report "FAIL: FAULT code 0xF wrongly flagged as invalid" severity error;
        fsm_state_code <= "0000";

        report "tb_safety_supervisor DONE" severity note;
        wait;
    end process;
end sim;
