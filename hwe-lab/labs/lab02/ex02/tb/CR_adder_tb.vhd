library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CR_adder_tb is
end entity CR_adder_tb;

architecture testbench of CR_adder_tb is

    signal A, B : STD_LOGIC_VECTOR(3 downto 0);
    signal Cin  : STD_LOGIC;
    signal S    : STD_LOGIC_VECTOR(3 downto 0);
    signal Cout : STD_LOGIC;

begin

    UUT : entity work.CR_adder(Structural)
        port map (
            A    => A,
            B    => B,
            Cin  => Cin,
            S    => S,
            Cout => Cout
        );

    A   <= "0000",
           "0001" after 10 ns,
           "0111" after 20 ns,
           "1111" after 30 ns,
           "1010" after 40 ns,
           "1111" after 50 ns;

    B   <= "0000",
           "0001" after 10 ns,
           "0001" after 20 ns,
           "0001" after 30 ns,
           "0101" after 40 ns,
           "1111" after 50 ns;

    Cin <= '0',
           '0' after 10 ns,
           '0' after 20 ns,
           '0' after 30 ns,
           '0' after 40 ns,
           '1' after 50 ns;

end architecture testbench;
