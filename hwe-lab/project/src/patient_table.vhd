library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Patient Table: holds up to 4 parked patients.
-- Each slot stores the room, doctor, and equipment indices assigned
-- to a patient that was dispatched but not yet released.
--
-- Park:    park_en pulse writes current room/doc/equip into the next free slot.
--          slot_num output tells the caller which slot was used (1-4).
-- Release: rel_en pulse fires release strobes to resource manager and clears slot.
--          slot_sel (SW[1:0]) chooses which slot: 00=slot1 01=slot2 10=slot3 11=slot4
-- occupied_mask: 4-bit vector, bit i = slot i occupied.
--
-- Index outputs are COMBINATORIAL from slot_sel so they are valid on the
-- same cycle the strobe fires. Strobes are registered (one-cycle pulse).

entity patient_table is
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;

        -- park interface (from scheduler FSM at BTNU press)
        park_en      : in  std_logic;
        park_room    : in  std_logic_vector(2 downto 0);
        park_doc     : in  std_logic_vector(2 downto 0);
        park_equip   : in  std_logic_vector(2 downto 0);
        slot_num     : out std_logic_vector(2 downto 0);

        -- release interface (BTND held + BTNC press)
        rel_en       : in  std_logic;
        slot_sel     : in  std_logic_vector(1 downto 0);

        -- release strobes + indices to resource manager
        rel_room     : out std_logic;
        rel_doctor   : out std_logic;
        rel_equipment: out std_logic;
        room_rel_idx : out std_logic_vector(2 downto 0);
        doc_rel_idx  : out std_logic_vector(2 downto 0);
        equip_rel_idx: out std_logic_vector(2 downto 0);

        occupied_mask: out std_logic_vector(3 downto 0)
    );
end patient_table;

architecture rtl of patient_table is
    type idx_array is array (0 to 3) of std_logic_vector(2 downto 0);

    signal rooms  : idx_array := (others => "000");
    signal docs   : idx_array := (others => "000");
    signal equips : idx_array := (others => "000");
    signal occ    : std_logic_vector(3 downto 0) := "0000";

    -- registered release strobes (one-cycle pulse)
    signal rel_room_r     : std_logic := '0';
    signal rel_doctor_r   : std_logic := '0';
    signal rel_equip_r    : std_logic := '0';

    -- latched indices: captured on rel_en cycle, held for strobe cycle
    signal latch_room     : std_logic_vector(2 downto 0) := "000";
    signal latch_doc      : std_logic_vector(2 downto 0) := "000";
    signal latch_equip    : std_logic_vector(2 downto 0) := "000";

    function first_free_slot(o : std_logic_vector(3 downto 0)) return natural is
    begin
        if    o(0) = '0' then return 0;
        elsif o(1) = '0' then return 1;
        elsif o(2) = '0' then return 2;
        elsif o(3) = '0' then return 3;
        else                   return 4;
        end if;
    end function;

begin
    occupied_mask <= occ;

    -- drive registered strobes and latched indices to outputs
    rel_room      <= rel_room_r;
    rel_doctor    <= rel_doctor_r;
    rel_equipment <= rel_equip_r;
    room_rel_idx  <= latch_room;
    doc_rel_idx   <= latch_doc;
    equip_rel_idx <= latch_equip;

    -- slot_num: next free slot (1-based), 0 if all full
    process(occ)
        variable f : natural;
    begin
        f := first_free_slot(occ);
        if f = 4 then
            slot_num <= "000";
        else
            slot_num <= std_logic_vector(to_unsigned(f + 1, 3));
        end if;
    end process;

    -- registered: park, release strobes, slot clear
    process(clk)
        variable f   : natural;
        variable sel : natural;
    begin
        if rising_edge(clk) then
            rel_room_r   <= '0';
            rel_doctor_r <= '0';
            rel_equip_r  <= '0';

            if reset = '1' then
                occ   <= "0000";
                rooms  <= (others => "000");
                docs   <= (others => "000");
                equips <= (others => "000");
            else
                if park_en = '1' then
                    f := first_free_slot(occ);
                    if f < 4 then
                        rooms(f)  <= park_room;
                        docs(f)   <= park_doc;
                        equips(f) <= park_equip;
                        occ(f)    <= '1';
                    end if;
                end if;

                if rel_en = '1' then
                    sel := to_integer(unsigned(slot_sel));
                    if occ(sel) = '1' then
                        -- latch indices BEFORE clearing so strobe cycle sees correct values
                        latch_room   <= rooms(sel);
                        latch_doc    <= docs(sel);
                        latch_equip  <= equips(sel);
                        rel_room_r   <= '1';
                        rel_doctor_r <= '1';
                        rel_equip_r  <= '1';
                        occ(sel)     <= '0';
                        rooms(sel)   <= "000";
                        docs(sel)    <= "000";
                        equips(sel)  <= "000";
                    end if;
                end if;
            end if;
        end if;
    end process;
end rtl;
