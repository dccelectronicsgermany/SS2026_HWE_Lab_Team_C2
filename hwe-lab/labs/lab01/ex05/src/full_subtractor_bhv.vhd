library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_subtractor is
    port (
        A    : in  std_logic;
        B    : in  std_logic;
        Bin  : in  std_logic;  -- Borrow in
        D    : out std_logic;  -- Difference
        Bout : out std_logic   -- Borrow out
    );
end entity;

architecture Behavioral of full_subtractor is
begin
    D    <= A xor B xor Bin;
    Bout <= ((not A) and B) or ((not A) and Bin) or (B and Bin);
end architecture;