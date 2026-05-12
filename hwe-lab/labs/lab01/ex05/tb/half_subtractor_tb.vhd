library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity half_subtractor_tb is
end entity;

architecture test of half_subtractor_tb is

    component half_subtractor
        port (
            A    : in  std_logic;
            B    : in  std_logic;
            D    : out std_logic;
            Bout : out std_logic
        );
    end component;

    signal A, B    : std_logic := '0';
    signal D, Bout : std_logic;

begin

    uut : half_subtractor
        port map (A => A, B => B, D => D, Bout => Bout);

    stim_proc : process
    begin
        -- All 4 input combinations (2²) for 100% coverage
        A <= '0'; B <= '0'; wait for 10 ns;  -- D=0 Bout=0
        A <= '0'; B <= '1'; wait for 10 ns;  -- D=1 Bout=1  (0-1, need to borrow)
        A <= '1'; B <= '0'; wait for 10 ns;  -- D=1 Bout=0
        A <= '1'; B <= '1'; wait for 10 ns;  -- D=0 Bout=0
        wait;
    end process;

end architecture;