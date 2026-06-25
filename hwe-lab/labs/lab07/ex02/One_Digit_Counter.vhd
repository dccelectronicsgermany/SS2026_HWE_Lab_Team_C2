-- ============================================================
-- File: One_Digit_Counter.vhd
-- Exercise 02: Decimal counter 0-9 for Nexys A7-100T
-- Note: Uses only STANDARD VHDL types: bit, bit_vector, integer.
--       No std_logic / no ieee.std_logic_1164.
-- ============================================================

entity Clock_Divider is
    port (
        clk        : in  bit;
        clear      : in  bit;
        tick_1hz   : out bit
    );
end entity Clock_Divider;

architecture Behavioral of Clock_Divider is
    -- Nexys A7 clock = 100 MHz.
    -- 100,000,000 clock cycles = 1 second.
    constant MAX_COUNT : integer := 100000000 - 1;

    signal div_counter : integer range 0 to MAX_COUNT := 0;
    signal tick_reg    : bit := '0';
begin
    tick_1hz <= tick_reg;

    process(clk, clear)
    begin
        if clear = '1' then
            div_counter <= 0;
            tick_reg    <= '0';

        elsif clk'event and clk = '1' then
            if div_counter = MAX_COUNT then
                div_counter <= 0;
                tick_reg    <= '1';      -- one-clock-cycle enable pulse
            else
                div_counter <= div_counter + 1;
                tick_reg    <= '0';
            end if;
        end if;
    end process;
end architecture Behavioral;


entity One_Digit_Counter is
    port (
        CLK100MHZ   : in  bit;
        START_STOP  : in  bit;
        CLEAR       : in  bit;

        CA          : out bit;
        CB          : out bit;
        CC          : out bit;
        CD          : out bit;
        CE          : out bit;
        CF          : out bit;
        CG          : out bit;
        DP          : out bit;

        AN          : out bit_vector(7 downto 0)
    );
end entity One_Digit_Counter;

architecture Behavioral of One_Digit_Counter is
    component Clock_Divider is
        port (
            clk        : in  bit;
            clear      : in  bit;
            tick_1hz   : out bit
        );
    end component;

    signal tick_1hz    : bit := '0';
    signal count_value : integer range 0 to 9 := 0;
    signal seg         : bit_vector(6 downto 0) := "0000001";
    -- seg order: a b c d e f g
begin
    divider_inst : Clock_Divider
        port map (
            clk      => CLK100MHZ,
            clear    => CLEAR,
            tick_1hz => tick_1hz
        );

    -- Decimal counter 0 to 9
    process(CLK100MHZ, CLEAR)
    begin
        if CLEAR = '1' then
            count_value <= 0;

        elsif CLK100MHZ'event and CLK100MHZ = '1' then
            if tick_1hz = '1' then
                if START_STOP = '1' then
                    if count_value = 9 then
                        count_value <= 0;
                    else
                        count_value <= count_value + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Active-low 7-segment decoder for Nexys A7 common-anode display
    -- seg order: a b c d e f g
    process(count_value)
    begin
        case count_value is
            when 0 => seg <= "0000001";
            when 1 => seg <= "1001111";
            when 2 => seg <= "0010010";
            when 3 => seg <= "0000110";
            when 4 => seg <= "1001100";
            when 5 => seg <= "0100100";
            when 6 => seg <= "0100000";
            when 7 => seg <= "0001111";
            when 8 => seg <= "0000000";
            when 9 => seg <= "0000100";
            when others => seg <= "1111111";
        end case;
    end process;

    CA <= seg(6);
    CB <= seg(5);
    CC <= seg(4);
    CD <= seg(3);
    CE <= seg(2);
    CF <= seg(1);
    CG <= seg(0);

    DP <= '1';             -- decimal point OFF, active-low
    AN <= "11111110";      -- enable only digit AN0, active-low
end architecture Behavioral;
