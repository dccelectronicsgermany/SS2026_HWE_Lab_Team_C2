library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BCDto7seg_tb is
end entity BCDto7seg_tb;

architecture testbench of BCDto7seg_tb is

    signal BCD : STD_LOGIC_VECTOR(3 downto 0);
    signal SEG : STD_LOGIC_VECTOR(6 downto 0);

begin

    UUT : entity work.BCDto7seg(Behavioral)
        port map (
            BCD => BCD,
            SEG => SEG
        );

    -- All valid BCD digits 0-9
    BCD <= "0000",
           "0001" after 10 ns,
           "0010" after 20 ns,
           "0011" after 30 ns,
           "0100" after 40 ns,
           "0101" after 50 ns,
           "0110" after 60 ns,
           "0111" after 70 ns,
           "1000" after 80 ns,
           "1001" after 90 ns;

end architecture testbench;
