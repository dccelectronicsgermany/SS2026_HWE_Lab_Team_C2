library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity half_adder is
    port (
        A, B : in  std_logic;
        S    : out std_logic;
        C    : out std_logic
    );
end entity;

architecture Behavioral of half_adder is

begin

    S <= A xor B;
    C <= A and B;

end architecture;