library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity half_subtractor is
    port (
        A    : in  std_logic;
        B    : in  std_logic;
        D    : out std_logic;  -- Difference
        Bout : out std_logic   -- Borrow out
    );
end entity;

architecture Behavioral of half_subtractor is
begin
    D    <= A xor B;
    Bout <= (not A) and B;
end architecture;