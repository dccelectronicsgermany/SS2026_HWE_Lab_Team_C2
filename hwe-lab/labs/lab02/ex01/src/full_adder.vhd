library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder is
    port (
        A    : in  STD_LOGIC;
        B    : in  STD_LOGIC;
        Cin  : in  STD_LOGIC;
        S    : out STD_LOGIC;
        Cout : out STD_LOGIC
    );
end entity full_adder;

architecture Structural of full_adder is

    component half_adder
        port (
            A : in  STD_LOGIC;
            B : in  STD_LOGIC;
            S : out STD_LOGIC;
            C : out STD_LOGIC
        );
    end component;

    signal S1 : STD_LOGIC;
    signal C1 : STD_LOGIC;
    signal C2 : STD_LOGIC;

begin

    HA1 : half_adder
        port map (
            A => A,
            B => B,
            S => S1,
            C => C1
        );

    HA2 : half_adder
        port map (
            A => S1,
            B => Cin,
            S => S,
            C => C2
        );

    Cout <= C1 or C2;

end architecture Structural;
