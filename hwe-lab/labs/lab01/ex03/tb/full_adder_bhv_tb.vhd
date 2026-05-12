library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder_tb is
end entity;

architecture test of full_adder_tb is

    component full_adder
        port (
            A    : in  std_logic;
            B    : in  std_logic;
            Cin  : in  std_logic;
            S    : out std_logic;
            Cout : out std_logic
        );
    end component;

    signal A, B, Cin : std_logic := '0';
    signal S, Cout   : std_logic;

begin

    uut : full_adder
        port map (A => A, B => B, Cin => Cin, S => S, Cout => Cout);

    stim_proc : process
    begin
        -- All 8 input combinations (2³) for 100% coverage
        A <= '0'; B <= '0'; Cin <= '0'; wait for 10 ns;  -- S=0 Cout=0
        A <= '0'; B <= '0'; Cin <= '1'; wait for 10 ns;  -- S=1 Cout=0
        A <= '0'; B <= '1'; Cin <= '0'; wait for 10 ns;  -- S=1 Cout=0
        A <= '0'; B <= '1'; Cin <= '1'; wait for 10 ns;  -- S=0 Cout=1
        A <= '1'; B <= '0'; Cin <= '0'; wait for 10 ns;  -- S=1 Cout=0
        A <= '1'; B <= '0'; Cin <= '1'; wait for 10 ns;  -- S=0 Cout=1
        A <= '1'; B <= '1'; Cin <= '0'; wait for 10 ns;  -- S=0 Cout=1
        A <= '1'; B <= '1'; Cin <= '1'; wait for 10 ns;  -- S=1 Cout=1
        wait;
    end process;

end architecture;