library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_patient_table is
end tb_patient_table;

architecture sim of tb_patient_table is
    signal clk           : std_logic := '0';
    signal reset         : std_logic := '1';
    signal park_en       : std_logic := '0';
    signal park_room     : std_logic_vector(2 downto 0) := "000";
    signal park_doc      : std_logic_vector(2 downto 0) := "000";
    signal park_equip    : std_logic_vector(2 downto 0) := "000";
    signal slot_num      : std_logic_vector(2 downto 0);
    signal rel_en        : std_logic := '0';
    signal slot_sel      : std_logic_vector(1 downto 0) := "00";
    signal rel_room      : std_logic;
    signal rel_doctor    : std_logic;
    signal rel_equipment : std_logic;
    signal room_rel_idx  : std_logic_vector(2 downto 0);
    signal doc_rel_idx   : std_logic_vector(2 downto 0);
    signal equip_rel_idx : std_logic_vector(2 downto 0);
    signal occupied_mask : std_logic_vector(3 downto 0);

    constant CLK_P : time := 10 ns;
begin
    clk <= not clk after CLK_P / 2;

    uut : entity work.patient_table
        port map (
            clk           => clk,
            reset         => reset,
            park_en       => park_en,
            park_room     => park_room,
            park_doc      => park_doc,
            park_equip    => park_equip,
            slot_num      => slot_num,
            rel_en        => rel_en,
            slot_sel      => slot_sel,
            rel_room      => rel_room,
            rel_doctor    => rel_doctor,
            rel_equipment => rel_equipment,
            room_rel_idx  => room_rel_idx,
            doc_rel_idx   => doc_rel_idx,
            equip_rel_idx => equip_rel_idx,
            occupied_mask => occupied_mask
        );

    process
    begin
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);  -- reset de-asserted, table clear

        assert occupied_mask = "0000" report "FAIL: not empty after reset" severity error;

        -- Park patient 1: room=001, doc=001, equip=001
        -- Drive inputs, pulse park_en for one edge, then check on the NEXT edge.
        park_room <= "001"; park_doc <= "001"; park_equip <= "001";
        park_en <= '1';
        wait until rising_edge(clk);  -- edge A: park_en='1' captured, slot 0 written
        park_en <= '0';
        wait until rising_edge(clk);  -- edge B: outputs now stable
        assert occupied_mask(0) = '1' report "FAIL: slot 0 not occupied after park 1" severity error;

        -- Park patient 2: room=010
        park_room <= "010"; park_doc <= "010"; park_equip <= "010";
        park_en <= '1';
        wait until rising_edge(clk);
        park_en <= '0';
        wait until rising_edge(clk);
        assert occupied_mask(1) = '1' report "FAIL: slot 1 not occupied after park 2" severity error;

        -- Park patient 3: room=011
        park_room <= "011"; park_doc <= "011"; park_equip <= "011";
        park_en <= '1';
        wait until rising_edge(clk);
        park_en <= '0';
        wait until rising_edge(clk);
        assert occupied_mask(2) = '1' report "FAIL: slot 2 not occupied after park 3" severity error;

        -- Release slot 1 (slot_sel="01"): latch_room/doc/equip captured on edge A,
        -- rel_room_r='1' also set on edge A. We read rel_room between edge A and edge B.
        slot_sel <= "01";
        wait until rising_edge(clk);   -- ensure slot_sel settles
        rel_en <= '1';
        wait until rising_edge(clk);   -- edge A: rel_en='1' captured; latch updated; rel_room_r<='1'
        rel_en <= '0';
        wait for 1 ns;  -- allow delta cycles to propagate registered updates
        -- Check rel_room strobes NOW (before next edge clears them)
        assert rel_room = '1'        report "FAIL: rel_room not asserted" severity error;
        assert rel_doctor = '1'      report "FAIL: rel_doctor not asserted" severity error;
        assert rel_equipment = '1'   report "FAIL: rel_equipment not asserted" severity error;
        assert room_rel_idx = "010"  report "FAIL: room_rel_idx wrong for slot 1" severity error;
        assert doc_rel_idx  = "010"  report "FAIL: doc_rel_idx wrong for slot 1" severity error;
        assert equip_rel_idx = "010" report "FAIL: equip_rel_idx wrong for slot 1" severity error;
        wait until rising_edge(clk);  -- edge B: rel_room_r<='0' (default clear); occ(1) cleared
        wait for 1 ns;
        assert rel_room = '0'           report "FAIL: rel_room should de-assert" severity error;
        assert occupied_mask(1) = '0'   report "FAIL: slot 1 still occupied" severity error;

        -- Release slot 0 (slot_sel="00"): should return room=001
        slot_sel <= "00";
        wait until rising_edge(clk);
        rel_en <= '1';
        wait until rising_edge(clk);  -- edge A: captured
        rel_en <= '0';
        wait for 1 ns;
        assert rel_room = '1'       report "FAIL: rel_room not asserted for slot 0" severity error;
        assert room_rel_idx = "001" report "FAIL: room_rel_idx wrong for slot 0" severity error;
        wait until rising_edge(clk);
        assert occupied_mask(0) = '0' report "FAIL: slot 0 still occupied" severity error;

        -- Release on an empty slot should NOT assert strobes (slot 1 is already freed)
        slot_sel <= "01";
        wait until rising_edge(clk);
        rel_en <= '1';
        wait until rising_edge(clk);  -- edge A: rel_en captured; slot 1 empty, so no action
        rel_en <= '0';
        wait for 1 ns;
        assert rel_room = '0' report "FAIL: rel_room asserted on empty slot" severity error;

        -- Reset clears all
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);
        assert occupied_mask = "0000" report "FAIL: reset did not clear occupied_mask" severity error;

        report "tb_patient_table DONE" severity note;
        wait;
    end process;
end sim;
