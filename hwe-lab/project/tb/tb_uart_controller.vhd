library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_uart_controller is
end tb_uart_controller;

architecture sim of tb_uart_controller is
    signal clk     : std_logic := '0';
    signal reset   : std_logic := '1';
    signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_send : std_logic := '0';
    signal tx_busy : std_logic;
    signal tx_pin  : std_logic;

    -- 100 MHz / 115200 baud = 868 clocks per bit
    constant CLK_P    : time := 10 ns;
    constant BIT_TIME : time := 868 * CLK_P;  -- ~8680 ns per bit

    -- Receive one full UART frame from tx_pin, return the 8 data bits.
    -- 8N1: start(0), D0..D7, stop(1).
    -- Sample each bit at the midpoint of BIT_TIME.
    procedure recv_byte(signal pin : in std_logic;
                        variable b : out std_logic_vector(7 downto 0)) is
    begin
        -- wait for start bit (falling edge)
        wait until pin = '0';
        -- sample in middle of start bit to verify
        wait for BIT_TIME / 2;
        assert pin = '0' report "FAIL: start bit not 0" severity error;
        -- sample 8 data bits
        for i in 0 to 7 loop
            wait for BIT_TIME;
            b(i) := pin;
        end loop;
        -- stop bit
        wait for BIT_TIME;
        assert pin = '1' report "FAIL: stop bit not 1" severity error;
    end procedure;
begin
    clk <= not clk after CLK_P / 2;

    uut : entity work.uart_controller
        port map (
            clk     => clk,
            reset   => reset,
            tx_data => tx_data,
            tx_send => tx_send,
            tx_busy => tx_busy,
            tx_pin  => tx_pin
        );

    process
        variable recv : std_logic_vector(7 downto 0);
    begin
        wait for 30 ns; reset <= '0'; wait for CLK_P;

        -- idle: tx_pin should be high (mark), not busy
        assert tx_pin  = '1' report "FAIL: tx_pin not idle high after reset" severity error;
        assert tx_busy = '0' report "FAIL: tx_busy asserted at idle" severity error;

        -- send byte 0x55 = 01010101
        tx_data <= x"55";
        tx_send <= '1'; wait for CLK_P; tx_send <= '0';
        assert tx_busy = '1' report "FAIL: tx_busy not set after tx_send" severity error;

        recv_byte(tx_pin, recv);
        assert recv = x"55" report "FAIL: received wrong byte (expected 0x55)" severity error;

        -- recv_byte samples stop bit at midpoint; wait remaining half + margin for busy to clear
        wait for BIT_TIME / 2 + CLK_P * 10;
        assert tx_busy = '0' report "FAIL: tx_busy did not clear after transmission" severity error;

        -- send byte 0xA3
        tx_data <= x"A3";
        tx_send <= '1'; wait for CLK_P; tx_send <= '0';
        recv_byte(tx_pin, recv);
        assert recv = x"A3" report "FAIL: received wrong byte (expected 0xA3)" severity error;
        wait for BIT_TIME / 2 + CLK_P * 10;
        assert tx_busy = '0' report "FAIL: tx_busy stuck after second byte" severity error;

        -- send byte 0x00
        tx_data <= x"00";
        tx_send <= '1'; wait for CLK_P; tx_send <= '0';
        recv_byte(tx_pin, recv);
        assert recv = x"00" report "FAIL: received wrong byte (expected 0x00)" severity error;

        -- reset mid-transmission: send then reset
        tx_data <= x"FF";
        tx_send <= '1'; wait for CLK_P; tx_send <= '0';
        wait for BIT_TIME * 3;  -- halfway through frame
        reset <= '1'; wait for CLK_P; reset <= '0'; wait for CLK_P;
        assert tx_busy = '0' report "FAIL: tx_busy should clear on reset" severity error;
        assert tx_pin  = '1' report "FAIL: tx_pin should be idle after reset" severity error;

        report "tb_uart_controller DONE" severity note;
        wait;
    end process;
end sim;
