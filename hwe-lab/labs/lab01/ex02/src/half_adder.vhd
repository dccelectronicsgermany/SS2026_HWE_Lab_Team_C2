library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity half_adder is
    port (
        A, B : in  std_logic;
        S    : out std_logic;
        C    : out std_logic
    );
end entity;

architecture Structural of half_adder is

    component xor_gate is
        port (
            A, B : in  std_logic;
            Y    : out std_logic
        );
    end component;

    component and_gate is
        port (
            A, B : in  std_logic;
            Y    : out std_logic
        );
    end component;

begin

    XOR1 : xor_gate port map (A => A, B => B, Y => S);
    AND1 : and_gate port map (A => A, B => B, Y => C);

end architecture;