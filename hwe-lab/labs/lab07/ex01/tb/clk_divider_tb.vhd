library STANDARD;
use STANDARD.all;

-- ============================================================
-- File: clk_divider_tb.vhd
-- Testbench for clk_divider.vhd
--
-- This testbench uses N = 10 so that simulation is fast.
-- CLK period = 10 ns.
-- Expected behavior:
--   CLK_N toggles every 5 CLK cycles.
--   Therefore one complete CLK_N period = 10 CLK cycles.
-- ============================================================

entity clk_divider_tb is
end clk_divider_tb;

architecture Testbench of clk_divider_tb is

    signal CLK_tb   : bit := '0';
    signal RESET_tb : bit := '0';
    signal CLK_N_tb : bit;

    constant CLK_PERIOD : time := 10 ns;

begin

    -- Device Under Test
    DUT: entity work.clk_divider
        generic map (
            N => 10
        )
        port map (
            CLK   => CLK_tb,
            RESET => RESET_tb,
            CLK_N => CLK_N_tb
        );

    -- Main clock generation
    clock_process: process
    begin
        while now < 300 ns loop
            CLK_tb <= '0';
            wait for CLK_PERIOD / 2;
            CLK_tb <= '1';
            wait for CLK_PERIOD / 2;
        end loop;

        wait;
    end process;

    -- Reset stimulus
    stimulus_process: process
    begin
        RESET_tb <= '1';
        wait for 25 ns;

        RESET_tb <= '0';
        wait for 250 ns;

        wait;
    end process;

end Testbench;
