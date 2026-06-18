library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Maps system state to 16 LEDs on the Nexys A7.
-- LED mapping (per spec):
--   LED0-3   : Room 1-4 occupancy (1 = busy)
--   LED4-7   : Doctor 1-4 occupancy
--   LED8-11  : Equipment 1-4 occupancy
--   LED12    : Critical patient active
--   LED13    : Treatment in progress
--   LED14    : Fault detected
--   LED15    : Alarm active (latched)
--
-- The alarm LED blinks at ~2 Hz to draw attention; all others are static.

entity led_controller is
    port (
        clk              : in  std_logic;
        reset            : in  std_logic;

        rooms_busy       : in  std_logic_vector(3 downto 0);
        doctors_busy     : in  std_logic_vector(3 downto 0);
        equip_busy       : in  std_logic_vector(3 downto 0);

        critical_flag    : in  std_logic;
        treatment_active : in  std_logic;
        fault            : in  std_logic;
        alarm            : in  std_logic;

        leds             : out std_logic_vector(15 downto 0)
    );
end led_controller;

architecture rtl of led_controller is
    -- 2 Hz blink: 100 MHz / (2 * 25_000_000) = 2 Hz
    constant BLINK_DIV : natural := 25_000_000;
    signal blink_cnt   : natural range 0 to BLINK_DIV - 1 := 0;
    signal blink_tog   : std_logic := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                blink_cnt <= 0;
                blink_tog <= '0';
            else
                if blink_cnt = BLINK_DIV - 1 then
                    blink_cnt <= 0;
                    blink_tog <= not blink_tog;
                else
                    blink_cnt <= blink_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    leds(3  downto 0)  <= rooms_busy;
    leds(7  downto 4)  <= doctors_busy;
    leds(11 downto 8)  <= equip_busy;
    leds(12)           <= critical_flag;
    leds(13)           <= treatment_active;
    leds(14)           <= fault;
    leds(15)           <= alarm and blink_tog;  -- blink when alarm active
end rtl;
