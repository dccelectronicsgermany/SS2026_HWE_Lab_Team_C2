library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Converts raw severity + type into a 3-bit priority score.
-- Higher score = treated first by the scheduler.
--
-- Severity mapping (SW0-SW1):
--   11 = Critical Emergency  -> base priority 3
--   10 = High Priority       -> base priority 2
--   01 = Urgent              -> base priority 1
--   00 = Normal              -> base priority 0
--
-- Patient type adds a 1-bit boost for Heart Attack / Stroke
-- so that equal-severity cardiac/stroke cases rank above general/accident.

entity priority_encoder is
    port (
        sev_in      : in  std_logic_vector(1 downto 0);
        type_in     : in  std_logic_vector(1 downto 0);
        prio_out    : out std_logic_vector(2 downto 0)
    );
end priority_encoder;

architecture rtl of priority_encoder is
    signal base  : unsigned(1 downto 0);
    signal boost : unsigned(0 downto 0);
begin
    base  <= unsigned(sev_in);

    -- Heart Attack (11) or Stroke (10) get +1 urgency boost
    boost <= "1" when (type_in = "10" or type_in = "11") else "0";

    prio_out <= std_logic_vector(("0" & base) + ("00" & boost));
end rtl;
