library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Safety Supervisor - continuously monitors for illegal system states.
-- Fault conditions (any one triggers fault + alarm):
--   1. Double allocation: a room/doctor/equipment busy bit goes high
--      while an allocation pulse is issued for it again (caught via
--      the busy vectors from resource_manager).
--   2. Resource exhaustion: no_room / no_doctor / no_equipment while
--      CHECK_RESOURCES is active (the FSM also catches this, but the
--      supervisor provides an independent second check).
--   3. Invalid FSM state code (anything above 0x9 except 0xF=FAULT).
--
-- Outputs:
--   fault      - combinatorial fault flag -> FSM fault_in
--   alarm      - registered, stays high until reset (latching alarm)

entity safety_supervisor is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;

        -- resource occupancy
        rooms_busy   : in  std_logic_vector(3 downto 0);
        doctors_busy : in  std_logic_vector(3 downto 0);
        equip_busy   : in  std_logic_vector(3 downto 0);

        -- allocation pulses (from FSM)
        alloc_room      : in  std_logic;
        alloc_doctor    : in  std_logic;
        alloc_equipment : in  std_logic;

        -- resource exhaustion flags
        no_room      : in  std_logic;
        no_doctor    : in  std_logic;
        no_equipment : in  std_logic;

        -- FSM state code
        fsm_state_code : in  std_logic_vector(3 downto 0);

        fault        : out std_logic;
        alarm        : out std_logic
    );
end safety_supervisor;

architecture rtl of safety_supervisor is
    signal double_alloc   : std_logic;
    signal exhaustion     : std_logic;
    signal invalid_state  : std_logic;
    signal fault_comb     : std_logic;
    signal alarm_reg      : std_logic := '0';
begin
    -- double allocation: try to allocate when ALL slots are busy
    double_alloc <= (alloc_room      and rooms_busy(0)   and rooms_busy(1)   and rooms_busy(2)   and rooms_busy(3))
                 or (alloc_doctor    and doctors_busy(0) and doctors_busy(1) and doctors_busy(2) and doctors_busy(3))
                 or (alloc_equipment and equip_busy(0)   and equip_busy(1)   and equip_busy(2)   and equip_busy(3));

    -- exhaustion: no resource available when requested
    exhaustion <= no_room or no_doctor or no_equipment;

    -- invalid state code (valid range 0-9 and 15)
    invalid_state <= '1' when (unsigned(fsm_state_code) > 9
                               and fsm_state_code /= "1111") else '0';

    fault_comb <= double_alloc or invalid_state;
    fault      <= fault_comb;

    -- latching alarm: set on any fault, cleared only by reset
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                alarm_reg <= '0';
            elsif fault_comb = '1' then
                alarm_reg <= '1';
            end if;
        end if;
    end process;

    alarm <= alarm_reg;
end rtl;
