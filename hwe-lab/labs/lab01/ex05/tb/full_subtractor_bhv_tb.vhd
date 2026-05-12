library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_subtractor_tb is
end entity;

architecture test of full_subtractor_tb is

    component full_subtractor
        port (
            A    : in  std_logic;
            B    : in  std_logic;
            Bin  : in  std_logic;
            D    : out std_logic;
            Bout : out std_logic
        );
    end component;

    signal A, B, Bin : std_logic := '0';
    signal D, Bout   : std_logic;

begin

    uut : full_subtractor
        port map (A => A, B => B, Bin => Bin, D => D, Bout => Bout);

    stim_proc : process
    begin
        -- All 8 input combinations (2³) for 100% coverage
        A <= '0'; B <= '0'; Bin <= '0'; wait for 10 ns;  -- D=0 Bout=0
        A <= '0'; B <= '0'; Bin <= '1'; wait for 10 ns;  -- D=1 Bout=1
        A <= '0'; B <= '1'; Bin <= '0'; wait for 10 ns;  -- D=1 Bout=1
        A <= '0'; B <= '1'; Bin <= '1'; wait for 10 ns;  -- D=0 Bout=1
        A <= '1'; B <= '0'; Bin <= '0'; wait for 10 ns;  -- D=1 Bout=0
        A <= '1'; B <= '0'; Bin <= '1'; wait for 10 ns;  -- D=0 Bout=0
        A <= '1'; B <= '1'; Bin <= '0'; wait for 10 ns;  -- D=0 Bout=0
        A <= '1'; B <= '1'; Bin <= '1'; wait for 10 ns;  -- D=1 Bout=1
        wait;
    end process;

end architecture;