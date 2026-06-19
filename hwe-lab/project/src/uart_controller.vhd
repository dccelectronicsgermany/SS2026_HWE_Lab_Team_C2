library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- UART TX-only controller.
-- 115200 baud, 8N1, 100 MHz system clock.
-- Accepts an 8-bit byte + send strobe; serialises it.
-- The top-level sends one byte at a time; a "busy" flag
-- prevents the caller from overwriting data mid-transmission.

entity uart_controller is
    port (
        clk      : in  std_logic;
        reset    : in  std_logic;
        tx_data  : in  std_logic_vector(7 downto 0);
        tx_send  : in  std_logic;   -- 1-cycle strobe to start transmission
        tx_busy  : out std_logic;
        tx_pin   : out std_logic    -- serial output -> JA connector pin
    );
end uart_controller;

architecture rtl of uart_controller is
    -- 100 MHz / 115200 = ~868 clocks per bit
    constant BAUD_DIV : natural := 868;

    signal baud_cnt  : natural range 0 to BAUD_DIV - 1 := 0;
    signal bit_cnt   : natural range 0 to 9 := 0;  -- 1 start + 8 data + 1 stop
    signal shift_reg : std_logic_vector(9 downto 0) := (others => '1');
    signal busy      : std_logic := '0';
begin
    tx_busy <= busy;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                baud_cnt  <= 0;
                bit_cnt   <= 0;
                shift_reg <= (others => '1');
                busy      <= '0';
                tx_pin    <= '1';
            else
                if busy = '0' then
                    tx_pin <= '1';
                    if tx_send = '1' then
                        -- frame: start(0) + data[0..7] + stop(1)
                        shift_reg <= '1' & tx_data & '0';
                        baud_cnt  <= 0;
                        bit_cnt   <= 0;
                        busy      <= '1';
                    end if;
                else
                    tx_pin <= shift_reg(0);
                    if baud_cnt = BAUD_DIV - 1 then
                        baud_cnt  <= 0;
                        shift_reg <= '1' & shift_reg(9 downto 1);
                        if bit_cnt = 9 then
                            busy    <= '0';
                            bit_cnt <= 0;
                        else
                            bit_cnt <= bit_cnt + 1;
                        end if;
                    else
                        baud_cnt <= baud_cnt + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
end rtl;
