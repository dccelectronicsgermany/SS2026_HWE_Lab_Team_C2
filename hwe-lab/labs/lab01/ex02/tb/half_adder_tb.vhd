library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity half_adder_tb is
end entity;

architecture test of half_adder_tb is

    -- Component declaration
    component half_adder
        port (
            A, B : in  std_logic;
            S    : out std_logic;
            C    : out std_logic
        );
    end component;

    -- Signals
    signal A, B : std_logic := '0';
    signal S, C : std_logic;

begin

    -- Instantiate DUT (Device Under Test)
    uut: half_adder
        port map (
            A => A,
            B => B,
            S => S,
            C => C
        );

	-- Drive inputs directly, no process needed
    A <= '0',        -- 0 ns
         '0' after 10 ns,
         '1' after 20 ns,
         '1' after 30 ns;

    B <= '0',        -- 0 ns
         '1' after 10 ns,
         '0' after 20 ns,
         '1' after 30 ns;

    -- Stimulus process
  --  stim_proc: process
  -- begin
        -- Test 00
  --     A <= '0'; B <= '0';
  --      wait for 10 ns;

        -- Test 01
  --      A <= '0'; B <= '1';
  --      wait for 10 ns;

        -- Test 10
  --      A <= '1'; B <= '0';
  --      wait for 10 ns;

        -- Test 11
  --      A <= '1'; B <= '1';
  --      wait for 10 ns;

  --      wait; -- stop simulation
--    end process;

end architecture;