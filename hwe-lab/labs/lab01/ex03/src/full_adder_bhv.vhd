library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder is
    port (
        A    : in  std_logic;
        B    : in  std_logic;
        Cin  : in  std_logic;
        S    : out std_logic;
        Cout : out std_logic
    );
end entity;

architecture Behavioral of full_adder is
begin
    S    <= A xor B xor Cin;
    Cout <= (A and B) or (B and Cin) or (A and Cin);
end architecture;