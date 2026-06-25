library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_resource_manager is
end tb_resource_manager;

architecture sim of tb_resource_manager is
    signal clk             : std_logic := '0';
    signal reset           : std_logic := '1';
    signal alloc_room      : std_logic := '0';
    signal alloc_doctor    : std_logic := '0';
    signal alloc_equipment : std_logic := '0';
    signal rel_room        : std_logic := '0';
    signal rel_doctor      : std_logic := '0';
    signal rel_equipment   : std_logic := '0';
    signal room_rel_idx    : std_logic_vector(2 downto 0) := "000";
    signal doc_rel_idx     : std_logic_vector(2 downto 0) := "000";
    signal equip_rel_idx   : std_logic_vector(2 downto 0) := "000";
    signal room_idx        : std_logic_vector(2 downto 0);
    signal doctor_idx      : std_logic_vector(2 downto 0);
    signal equipment_idx   : std_logic_vector(2 downto 0);
    signal rooms_busy      : std_logic_vector(3 downto 0);
    signal doctors_busy    : std_logic_vector(3 downto 0);
    signal equip_busy      : std_logic_vector(3 downto 0);
    signal no_room         : std_logic;
    signal no_doctor       : std_logic;
    signal no_equipment    : std_logic;

    constant CLK_P : time := 10 ns;

    -- Pulse a signal high for one rising-edge capture, then wait one more edge
    -- so that the registered output is stable when this procedure returns.
    procedure pulse_one(signal s : out std_logic) is
    begin
        s <= '1';
        wait until rising_edge(clk);  -- s='1' captured into registers
        s <= '0';
        wait until rising_edge(clk);  -- registered output now stable
    end procedure;
begin
    clk <= not clk after CLK_P / 2;

    uut : entity work.resource_manager
        port map (
            clk             => clk,
            reset           => reset,
            alloc_room      => alloc_room,
            alloc_doctor    => alloc_doctor,
            alloc_equipment => alloc_equipment,
            rel_room        => rel_room,
            rel_doctor      => rel_doctor,
            rel_equipment   => rel_equipment,
            room_rel_idx    => room_rel_idx,
            doc_rel_idx     => doc_rel_idx,
            equip_rel_idx   => equip_rel_idx,
            room_idx        => room_idx,
            doctor_idx      => doctor_idx,
            equipment_idx   => equipment_idx,
            rooms_busy      => rooms_busy,
            doctors_busy    => doctors_busy,
            equip_busy      => equip_busy,
            no_room         => no_room,
            no_doctor       => no_doctor,
            no_equipment    => no_equipment
        );

    process
        variable r2 : std_logic_vector(2 downto 0);
    begin
        -- hold reset a few edges
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);  -- reset de-asserted, state clean
        wait until rising_edge(clk);  -- extra settle

        assert rooms_busy = "0000" report "FAIL: rooms not clean after reset" severity error;
        assert no_room = '0' report "FAIL: no_room set at start" severity error;

        -- Allocate room 1
        pulse_one(alloc_room);
        assert rooms_busy(0) = '1' report "FAIL: room 1 not busy after alloc" severity error;
        assert room_idx = "010"    report "FAIL: room_idx should be 2 after first alloc" severity error;

        -- Capture room 2 index before allocating it
        r2 := room_idx;  -- "010"

        -- Allocate room 2
        pulse_one(alloc_room);
        assert rooms_busy(1) = '1' report "FAIL: room 2 not busy" severity error;

        -- Allocate rooms 3 and 4
        pulse_one(alloc_room);
        pulse_one(alloc_room);
        assert no_room = '1' report "FAIL: no_room not set when all busy" severity error;

        -- Release room 2 using captured index
        room_rel_idx <= r2;
        wait until rising_edge(clk);  -- let room_rel_idx settle
        pulse_one(rel_room);
        assert rooms_busy(1) = '0' report "FAIL: room 2 not released" severity error;
        assert no_room = '0' report "FAIL: no_room should clear after release" severity error;

        -- Fill all 4 doctors
        pulse_one(alloc_doctor);
        pulse_one(alloc_doctor);
        pulse_one(alloc_doctor);
        pulse_one(alloc_doctor);
        assert no_doctor = '1' report "FAIL: no_doctor not set" severity error;

        -- Release doctor index 1
        doc_rel_idx <= "001";
        wait until rising_edge(clk);
        pulse_one(rel_doctor);
        assert doctors_busy(0) = '0' report "FAIL: doctor 1 not released" severity error;
        assert no_doctor = '0' report "FAIL: no_doctor not cleared after release" severity error;

        -- Fill all 4 equipment units
        pulse_one(alloc_equipment);
        pulse_one(alloc_equipment);
        pulse_one(alloc_equipment);
        pulse_one(alloc_equipment);
        assert no_equipment = '1' report "FAIL: no_equipment not set" severity error;

        -- Reset clears everything
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);
        assert rooms_busy   = "0000" report "FAIL: reset did not clear rooms" severity error;
        assert doctors_busy = "0000" report "FAIL: reset did not clear doctors" severity error;
        assert equip_busy   = "0000" report "FAIL: reset did not clear equipment" severity error;
        assert no_room      = '0'    report "FAIL: no_room not cleared by reset" severity error;

        report "tb_resource_manager DONE" severity note;
        wait;
    end process;
end sim;
