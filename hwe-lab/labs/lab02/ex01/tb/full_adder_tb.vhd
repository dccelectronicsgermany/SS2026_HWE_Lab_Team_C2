library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder_tb is
end entity full_adder_tb;

architecture testbench of full_adder_tb is

    component full_adder is
        port (
            A    : in  STD_LOGIC;
            B    : in  STD_LOGIC;
            Cin  : in  STD_LOGIC;
            S    : out STD_LOGIC;
            Cout : out STD_LOGIC
        );
    end component;

    signal A, B, Cin : STD_LOGIC;
    signal S, Cout   : STD_LOGIC;

begin

    UUT : full_adder
        port map (
            A    => A,
            B    => B,
            Cin  => Cin,
            S    => S,
            Cout => Cout
        );

    -- All 8 input combinations, 10ns each
    A   <= '0', '0' after 10 ns, '0' after 20 ns, '0' after 30 ns, '1' after 40 ns, '1' after 50 ns, '1' after 60 ns, '1' after 70 ns;
    B   <= '0', '0' after 10 ns, '1' after 20 ns, '1' after 30 ns, '0' after 40 ns, '0' after 50 ns, '1' after 60 ns, '1' after 70 ns;
    Cin <= '0', '1' after 10 ns, '0' after 20 ns, '1' after 30 ns, '0' after 40 ns, '1' after 50 ns, '0' after 60 ns, '1' after 70 ns;

end architecture testbench;
