library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CR_adder is
    port (
        A    : in  STD_LOGIC_VECTOR(3 downto 0);
        B    : in  STD_LOGIC_VECTOR(3 downto 0);
        Cin  : in  STD_LOGIC;
        S    : out STD_LOGIC_VECTOR(3 downto 0);
        Cout : out STD_LOGIC
    );
end entity CR_adder;

architecture Structural of CR_adder is

    signal c : STD_LOGIC_VECTOR(3 downto 1);

begin

    FA0 : entity work.full_adder(Structural)
        port map (A => A(0), B => B(0), Cin => Cin,  S => S(0), Cout => c(1));

    FA1 : entity work.full_adder(Structural)
        port map (A => A(1), B => B(1), Cin => c(1), S => S(1), Cout => c(2));

    FA2 : entity work.full_adder(Structural)
        port map (A => A(2), B => B(2), Cin => c(2), S => S(2), Cout => c(3));

    FA3 : entity work.full_adder(Structural)
        port map (A => A(3), B => B(3), Cin => c(3), S => S(3), Cout => Cout);

end architecture Structural;
