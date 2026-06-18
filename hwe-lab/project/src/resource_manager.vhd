library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Tracks occupancy of 4 rooms, 4 doctors, and 4 equipment units.
-- The scheduler FSM calls alloc_* to claim a resource and
-- release_* to free it after treatment.
-- Outputs the index (1-4) of the first free resource, or "00" when none.

entity resource_manager is
    port (
        clk             : in  std_logic;
        reset           : in  std_logic;

        -- allocation requests from scheduler FSM
        alloc_room      : in  std_logic;
        alloc_doctor    : in  std_logic;
        alloc_equipment : in  std_logic;

        -- release requests from scheduler FSM
        rel_room        : in  std_logic;
        rel_doctor      : in  std_logic;
        rel_equipment   : in  std_logic;

        -- which resource to release (1-based index, "01".."100")
        room_rel_idx    : in  std_logic_vector(2 downto 0);
        doc_rel_idx     : in  std_logic_vector(2 downto 0);
        equip_rel_idx   : in  std_logic_vector(2 downto 0);

        -- allocated indices ("00" = none available)
        room_idx        : out std_logic_vector(2 downto 0);
        doctor_idx      : out std_logic_vector(2 downto 0);
        equipment_idx   : out std_logic_vector(2 downto 0);

        -- availability flags for safety supervisor
        rooms_busy      : out std_logic_vector(3 downto 0);
        doctors_busy    : out std_logic_vector(3 downto 0);
        equip_busy      : out std_logic_vector(3 downto 0);

        -- high when ALL resources of a type are occupied
        no_room         : out std_logic;
        no_doctor       : out std_logic;
        no_equipment    : out std_logic
    );
end resource_manager;

architecture rtl of resource_manager is
    signal rooms    : std_logic_vector(3 downto 0) := "0000"; -- bit i = room i+1 busy
    signal doctors  : std_logic_vector(3 downto 0) := "0000";
    signal equip    : std_logic_vector(3 downto 0) := "0000";

    -- first-free priority encoder: returns 3-bit 1-based index or "000"
    function first_free(busy : std_logic_vector(3 downto 0)) return std_logic_vector is
    begin
        if    busy(0) = '0' then return "001";
        elsif busy(1) = '0' then return "010";
        elsif busy(2) = '0' then return "011";
        elsif busy(3) = '0' then return "100";
        else                      return "000";
        end if;
    end function;
begin
    -- combinatorial availability outputs
    room_idx      <= first_free(rooms);
    doctor_idx    <= first_free(doctors);
    equipment_idx <= first_free(equip);

    no_room      <= '1' when rooms   = "1111" else '0';
    no_doctor    <= '1' when doctors = "1111" else '0';
    no_equipment <= '1' when equip   = "1111" else '0';

    rooms_busy   <= rooms;
    doctors_busy <= doctors;
    equip_busy   <= equip;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                rooms   <= "0000";
                doctors <= "0000";
                equip   <= "0000";
            else
                -- allocate: mark first free slot busy
                if alloc_room = '1' then
                    case first_free(rooms) is
                        when "001" => rooms(0) <= '1';
                        when "010" => rooms(1) <= '1';
                        when "011" => rooms(2) <= '1';
                        when "100" => rooms(3) <= '1';
                        when others => null;
                    end case;
                end if;

                if alloc_doctor = '1' then
                    case first_free(doctors) is
                        when "001" => doctors(0) <= '1';
                        when "010" => doctors(1) <= '1';
                        when "011" => doctors(2) <= '1';
                        when "100" => doctors(3) <= '1';
                        when others => null;
                    end case;
                end if;

                if alloc_equipment = '1' then
                    case first_free(equip) is
                        when "001" => equip(0) <= '1';
                        when "010" => equip(1) <= '1';
                        when "011" => equip(2) <= '1';
                        when "100" => equip(3) <= '1';
                        when others => null;
                    end case;
                end if;

                -- release: clear the specific slot given by index
                if rel_room = '1' then
                    case room_rel_idx is
                        when "001" => rooms(0) <= '0';
                        when "010" => rooms(1) <= '0';
                        when "011" => rooms(2) <= '0';
                        when "100" => rooms(3) <= '0';
                        when others => null;
                    end case;
                end if;

                if rel_doctor = '1' then
                    case doc_rel_idx is
                        when "001" => doctors(0) <= '0';
                        when "010" => doctors(1) <= '0';
                        when "011" => doctors(2) <= '0';
                        when "100" => doctors(3) <= '0';
                        when others => null;
                    end case;
                end if;

                if rel_equipment = '1' then
                    case equip_rel_idx is
                        when "001" => equip(0) <= '0';
                        when "010" => equip(1) <= '0';
                        when "011" => equip(2) <= '0';
                        when "100" => equip(3) <= '0';
                        when others => null;
                    end case;
                end if;
            end if;
        end if;
    end process;
end rtl;
