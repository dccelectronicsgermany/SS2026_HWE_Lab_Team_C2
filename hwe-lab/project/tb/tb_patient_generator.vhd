library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_patient_generator is
end tb_patient_generator;

architecture sim of tb_patient_generator is
    signal clk              : std_logic := '0';
    signal reset            : std_logic := '1';
    signal btn_new          : std_logic := '0';
    signal sw_severity      : std_logic_vector(1 downto 0) := "10";
    signal sw_type          : std_logic_vector(1 downto 0) := "11";
    signal sw_id            : std_logic_vector(3 downto 0) := "0101";
    signal patient_valid    : std_logic;
    signal patient_id       : std_logic_vector(3 downto 0);
    signal patient_type     : std_logic_vector(1 downto 0);
    signal patient_severity : std_logic_vector(1 downto 0);

    constant CLK_P : time := 10 ns;
begin
    clk <= not clk after CLK_P / 2;

    uut : entity work.patient_generator
        port map (
            clk              => clk,
            reset            => reset,
            btn_new          => btn_new,
            sw_severity      => sw_severity,
            sw_type          => sw_type,
            sw_id            => sw_id,
            patient_valid    => patient_valid,
            patient_id       => patient_id,
            patient_type     => patient_type,
            patient_severity => patient_severity
        );

    process
    begin
        -- Reset for 2 edges
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);  -- reset de-asserted captured

        -- -------------------------------------------------------
        -- First press: hold btn_new high, check valid on edge 7
        -- Pipeline: btn -> sync0(e4) -> sync1(e5) -> prev(e6)
        -- detect(sync1='1', prev='0') fires on e6; valid='1' readable at e7
        -- -------------------------------------------------------
        btn_new <= '1';
        wait until rising_edge(clk);  -- e4: sync0 captures '1'
        wait until rising_edge(clk);  -- e5: sync1 captures '1'
        wait until rising_edge(clk);  -- e6: prev captures '1'; detect fires; valid registered
        wait until rising_edge(clk);  -- e7: valid='1' now readable
        -- sample while btn is still high (keeps valid asserted)
        assert patient_valid = '1'
            report "FAIL: patient_valid not asserted after button press" severity error;
        assert patient_id = "0101"
            report "FAIL: patient_id mismatch" severity error;
        assert patient_severity = "10"
            report "FAIL: patient_severity mismatch" severity error;
        assert patient_type = "11"
            report "FAIL: patient_type mismatch" severity error;

        -- Release button; valid de-asserts on next edge
        btn_new <= '0';
        wait until rising_edge(clk);  -- e8: sync0='0' propagates; but valid was only a 1-cycle pulse
        -- Actually valid goes '0' because: on e7 btn_new is still '1', sync1='1', prev='1'
        -- so on e7 detect = sync1='1' AND prev='0'? No: at e6, prev JUST became '1'.
        -- At e7: prev is now the value sync1 had at e6 = '1', so detect='0' -> valid='0' at e8.
        assert patient_valid = '0'
            report "FAIL: patient_valid should de-assert after one cycle" severity error;

        -- Wait a few cycles before next press
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- -------------------------------------------------------
        -- Second press with different switches
        -- -------------------------------------------------------
        sw_id       <= "1010";
        sw_severity <= "11";
        sw_type     <= "01";
        wait until rising_edge(clk);  -- let switch values settle

        btn_new <= '1';
        wait until rising_edge(clk);  -- sync0
        wait until rising_edge(clk);  -- sync1
        wait until rising_edge(clk);  -- detect fires
        wait until rising_edge(clk);  -- valid readable

        assert patient_valid = '1'
            report "FAIL: second press patient_valid not asserted" severity error;
        assert patient_id = "1010"
            report "FAIL: second press patient_id mismatch" severity error;
        assert patient_severity = "11"
            report "FAIL: second press severity mismatch" severity error;
        assert patient_type = "01"
            report "FAIL: second press type mismatch" severity error;

        btn_new <= '0';
        wait until rising_edge(clk);
        assert patient_valid = '0'
            report "FAIL: second press valid not de-asserted" severity error;

        report "tb_patient_generator DONE" severity note;
        wait;
    end process;
end sim;
