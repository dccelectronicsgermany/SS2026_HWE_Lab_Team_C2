library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CR_add_sub_tb is
end entity CR_add_sub_tb;

architecture testbench of CR_add_sub_tb is

    signal A, B : STD_LOGIC_VECTOR(3 downto 0);
    signal Mode : STD_LOGIC;
    signal S    : STD_LOGIC_VECTOR(3 downto 0);
    signal Cout : STD_LOGIC;

begin

    UUT : entity work.CR_add_sub(Structural)
        port map (
            A    => A,
            B    => B,
            Mode => Mode,
            S    => S,
            Cout => Cout
        );

    -- Addition (Mode=0)
    A    <= "0011",
            "0111" after 10 ns,
            "1010" after 20 ns,
            -- Subtraction (Mode=1)
            "0101" after 30 ns,
            "1000" after 40 ns,
            "0011" after 50 ns;

    B    <= "0001",
            "0001" after 10 ns,
            "0101" after 20 ns,
            "0011" after 30 ns,
            "0011" after 40 ns,
            "0011" after 50 ns;

    Mode <= '0',
            '0' after 10 ns,
            '0' after 20 ns,
            '1' after 30 ns,
            '1' after 40 ns,
            '1' after 50 ns;

end architecture testbench;
