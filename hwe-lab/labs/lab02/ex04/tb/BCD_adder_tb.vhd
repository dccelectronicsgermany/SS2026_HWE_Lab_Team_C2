library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BCD_adder_tb is
end entity BCD_adder_tb;

architecture testbench of BCD_adder_tb is

    signal A, B : STD_LOGIC_VECTOR(3 downto 0);
    signal Cin  : STD_LOGIC;
    signal S    : STD_LOGIC_VECTOR(3 downto 0);
    signal Cout : STD_LOGIC;

begin

    UUT : entity work.BCD_adder(Structural)
        port map (
            A    => A,
            B    => B,
            Cin  => Cin,
            S    => S,
            Cout => Cout
        );

    -- No correction needed (sum <= 9)
    A   <= "0011",           -- 3
           "0101" after 10 ns, -- 5
           "1001" after 20 ns, -- 9
           -- Correction needed (sum > 9)
           "0101" after 30 ns, -- 5
           "1001" after 40 ns, -- 9
           "1001" after 50 ns; -- 9

    B   <= "0100",           -- 4  => 3+4=7
           "0011" after 10 ns, -- 3  => 5+3=8
           "0000" after 20 ns, -- 0  => 9+0=9
           "0110" after 30 ns, -- 6  => 5+6=11 -> corrected to 1, Cout=1
           "0101" after 40 ns, -- 5  => 9+5=14 -> corrected to 4, Cout=1
           "1001" after 50 ns; -- 9  => 9+9=18 -> corrected to 8, Cout=1

    Cin <= '0',
           '0' after 10 ns,
           '0' after 20 ns,
           '0' after 30 ns,
           '0' after 40 ns,
           '0' after 50 ns;

end architecture testbench;
