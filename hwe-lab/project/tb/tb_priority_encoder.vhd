library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_priority_encoder is
end tb_priority_encoder;

architecture sim of tb_priority_encoder is
    signal sev_in   : std_logic_vector(1 downto 0);
    signal type_in  : std_logic_vector(1 downto 0);
    signal prio_out : std_logic_vector(2 downto 0);
begin
    uut : entity work.priority_encoder
        port map (sev_in => sev_in, type_in => type_in, prio_out => prio_out);

    process
    begin
        -- Normal + General -> 0
        sev_in <= "00"; type_in <= "00"; wait for 20 ns;
        assert prio_out = "000" report "FAIL: Normal+General" severity error;

        -- Urgent + General -> 1
        sev_in <= "01"; type_in <= "00"; wait for 20 ns;
        assert prio_out = "001" report "FAIL: Urgent+General" severity error;

        -- High + General -> 2
        sev_in <= "10"; type_in <= "00"; wait for 20 ns;
        assert prio_out = "010" report "FAIL: High+General" severity error;

        -- Critical + General -> 3
        sev_in <= "11"; type_in <= "00"; wait for 20 ns;
        assert prio_out = "011" report "FAIL: Critical+General" severity error;

        -- Normal + Stroke -> 1 (boost)
        sev_in <= "00"; type_in <= "10"; wait for 20 ns;
        assert prio_out = "001" report "FAIL: Normal+Stroke" severity error;

        -- Urgent + Heart Attack -> 2
        sev_in <= "01"; type_in <= "11"; wait for 20 ns;
        assert prio_out = "010" report "FAIL: Urgent+HeartAttack" severity error;

        -- Critical + Heart Attack -> 4 (max)
        sev_in <= "11"; type_in <= "11"; wait for 20 ns;
        assert prio_out = "100" report "FAIL: Critical+HeartAttack" severity error;

        -- High + Accident -> 2 (Accident type_in="01" does NOT get boost)
        sev_in <= "10"; type_in <= "01"; wait for 20 ns;
        assert prio_out = "010" report "FAIL: High+Accident" severity error;

        report "tb_priority_encoder DONE" severity note;
        wait;
    end process;
end sim;
