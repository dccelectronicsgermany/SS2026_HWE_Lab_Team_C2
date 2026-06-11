library STANDARD;
use STANDARD.all;

-- ============================================================
-- File: clk_divider.vhd
-- Lab 07 - Exercise 01
-- Clock Divider using only STANDARD VHDL library
--
-- Function:
--   Generates CLK_N from CLK.
--   CLK_N is slower than CLK by approximately factor N.
--
-- Important:
--   For real FPGA use with 100 MHz clock and 1 Hz output:
--       N = 100000000
--
--   For simulation use a small value:
--       N = 10 or N = 20
-- ============================================================

entity clk_divider is
    generic (
        N : integer := 100000000
    );
    port (
        CLK   : in  bit;
        RESET : in  bit;
        CLK_N : out bit
    );
end clk_divider;

architecture Behavioral of clk_divider is
    signal counter  : integer := 0;
    signal clk_temp : bit := '0';
begin

    process (CLK, RESET)
    begin
        if RESET = '1' then
            counter  <= 0;
            clk_temp <= '0';

        elsif CLK'event and CLK = '1' then

            -- Toggle output after N/2 input clock cycles.
            -- One full CLK_N period therefore takes N input clock cycles.
            if counter = (N / 2) - 1 then
                counter  <= 0;
                clk_temp <= not clk_temp;
            else
                counter <= counter + 1;
            end if;

        end if;
    end process;

    CLK_N <= clk_temp;

end Behavioral;
