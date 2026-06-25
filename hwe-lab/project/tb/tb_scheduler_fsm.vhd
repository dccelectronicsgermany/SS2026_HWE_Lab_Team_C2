library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_scheduler_fsm is
end tb_scheduler_fsm;

architecture sim of tb_scheduler_fsm is
    signal clk              : std_logic := '0';
    signal reset            : std_logic := '1';
    signal patient_valid    : std_logic := '0';
    signal patient_id       : std_logic_vector(3 downto 0) := "0001";
    signal patient_severity : std_logic_vector(1 downto 0) := "01";
    signal patient_type     : std_logic_vector(1 downto 0) := "00";
    signal priority         : std_logic_vector(2 downto 0) := "001";
    signal no_room          : std_logic := '0';
    signal no_doctor        : std_logic := '0';
    signal no_equipment     : std_logic := '0';
    signal room_idx         : std_logic_vector(2 downto 0) := "001";
    signal doctor_idx       : std_logic_vector(2 downto 0) := "001";
    signal equipment_idx    : std_logic_vector(2 downto 0) := "001";
    signal fault_in         : std_logic := '0';
    signal btn_step         : std_logic := '0';
    signal btn_override     : std_logic := '0';
    signal btn_park         : std_logic := '0';
    signal park_en          : std_logic;
    signal alloc_room       : std_logic;
    signal alloc_doctor     : std_logic;
    signal alloc_equipment  : std_logic;
    signal rel_room         : std_logic;
    signal rel_doctor       : std_logic;
    signal rel_equipment    : std_logic;
    signal room_rel_idx     : std_logic_vector(2 downto 0);
    signal doc_rel_idx      : std_logic_vector(2 downto 0);
    signal equip_rel_idx    : std_logic_vector(2 downto 0);
    signal curr_patient_id  : std_logic_vector(3 downto 0);
    signal curr_severity    : std_logic_vector(1 downto 0);
    signal curr_priority    : std_logic_vector(2 downto 0);
    signal curr_room        : std_logic_vector(2 downto 0);
    signal curr_doctor      : std_logic_vector(2 downto 0);
    signal curr_equipment   : std_logic_vector(2 downto 0);
    signal treatment_active : std_logic;
    signal critical_flag    : std_logic;
    signal fault_out        : std_logic;
    signal fsm_state_code   : std_logic_vector(3 downto 0);

    constant CLK_P : time := 10 ns;

    -- Step button: must pass 2-stage sync + edge detect.
    -- Pipeline: btn->sync0 (edge N) ->sync1 (edge N+1) ->prev (edge N+2).
    -- Detect: sync1='1' AND prev='0', fires at edge N+2.
    -- Hold for 4+ cycles to guarantee one detect, then release.
    procedure do_step(signal s : out std_logic) is
    begin
        wait until rising_edge(clk);
        s <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        s <= '0';
        wait until rising_edge(clk);
    end procedure;

    procedure assert_state(expected : std_logic_vector(3 downto 0); msg : string) is
    begin
        assert fsm_state_code = expected
            report "FAIL: " & msg & " (got " & integer'image(to_integer(unsigned(fsm_state_code))) & ")" severity error;
    end procedure;
begin
    clk <= not clk after CLK_P / 2;

    uut : entity work.scheduler_fsm
        generic map (CLK_FREQ => 4)
        port map (
            clk              => clk,
            reset            => reset,
            patient_valid    => patient_valid,
            patient_id       => patient_id,
            patient_severity => patient_severity,
            patient_type     => patient_type,
            priority         => priority,
            no_room          => no_room,
            no_doctor        => no_doctor,
            no_equipment     => no_equipment,
            room_idx         => room_idx,
            doctor_idx       => doctor_idx,
            equipment_idx    => equipment_idx,
            fault_in         => fault_in,
            btn_step         => btn_step,
            btn_override     => btn_override,
            btn_park         => btn_park,
            park_en          => park_en,
            alloc_room       => alloc_room,
            alloc_doctor     => alloc_doctor,
            alloc_equipment  => alloc_equipment,
            rel_room         => rel_room,
            rel_doctor       => rel_doctor,
            rel_equipment    => rel_equipment,
            room_rel_idx     => room_rel_idx,
            doc_rel_idx      => doc_rel_idx,
            equip_rel_idx    => equip_rel_idx,
            curr_patient_id  => curr_patient_id,
            curr_severity    => curr_severity,
            curr_priority    => curr_priority,
            curr_room        => curr_room,
            curr_doctor      => curr_doctor,
            curr_equipment   => curr_equipment,
            treatment_active => treatment_active,
            critical_flag    => critical_flag,
            fault_out        => fault_out,
            fsm_state_code   => fsm_state_code
        );

    process
    begin
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);

        assert_state("0000", "not IDLE at start");

        -- IDLE -> RECEIVE_PATIENT on patient_valid
        wait until rising_edge(clk);
        patient_valid <= '1';
        wait until rising_edge(clk);
        patient_valid <= '0';
        wait until rising_edge(clk);
        assert_state("0001", "did not enter RECEIVE_PATIENT");

        -- RECEIVE_PATIENT -> TRIAGE via step
        do_step(btn_step);
        assert_state("0010", "did not reach TRIAGE");

        -- TRIAGE -> CHECK_RESOURCES
        do_step(btn_step);
        assert_state("0011", "did not reach CHECK_RESOURCES");

        -- CHECK_RESOURCES -> ALLOCATE_ROOM (resources available)
        do_step(btn_step);
        assert_state("0100", "did not reach ALLOCATE_ROOM");

        -- alloc_room fires on the first cycle in ALLOCATE_ROOM (alloc_sent=0)
        -- After do_step the FSM just entered ALLOCATE_ROOM; alloc_room fires immediately.
        -- We need one more cycle for alloc_room to have been '1':
        -- do_step already waited one cycle after releasing, so check now.
        assert alloc_room = '1' report "FAIL: alloc_room not pulsed in ALLOCATE_ROOM" severity error;

        -- ALLOCATE_ROOM -> ALLOCATE_DOCTOR
        do_step(btn_step);
        assert_state("0101", "did not reach ALLOCATE_DOCTOR");
        assert alloc_doctor = '1' report "FAIL: alloc_doctor not pulsed" severity error;

        -- ALLOCATE_DOCTOR -> ALLOCATE_EQUIPMENT
        do_step(btn_step);
        assert_state("0110", "did not reach ALLOCATE_EQUIPMENT");
        assert alloc_equipment = '1' report "FAIL: alloc_equipment not pulsed" severity error;

        -- ALLOCATE_EQUIPMENT -> DISPATCH_TEAM
        do_step(btn_step);
        assert_state("0111", "did not reach DISPATCH_TEAM");
        assert treatment_active = '1' report "FAIL: treatment_active not set at DISPATCH_TEAM" severity error;

        -- DISPATCH_TEAM -> MONITOR_TREATMENT
        do_step(btn_step);
        assert_state("1000", "did not reach MONITOR_TREATMENT");

        -- Wait for treatment timer to expire and FSM to reach RELEASE_RESOURCES.
        -- rel_room fires on the FIRST cycle in RELEASE_RESOURCES (alloc_sent=0).
        -- So: poll until state="1001", then wait one more edge for rel_room to fire.
        for i in 1 to 60 loop
            wait until rising_edge(clk);
            wait for 1 ns;
            exit when fsm_state_code = "1001";
        end loop;
        assert_state("1001", "did not reach RELEASE_RESOURCES");
        wait until rising_edge(clk);  -- first cycle in RELEASE_RESOURCES: rel_room fires
        wait for 1 ns;
        assert rel_room = '1' report "FAIL: rel_room not asserted in RELEASE_RESOURCES" severity error;

        -- RELEASE_RESOURCES -> IDLE via step
        do_step(btn_step);
        assert_state("0000", "did not return to IDLE");

        -- ---- Test: resource fault (no_room in CHECK_RESOURCES) ----
        wait until rising_edge(clk);
        patient_valid <= '1';
        wait until rising_edge(clk);
        patient_valid <= '0';
        wait until rising_edge(clk);  -- -> RECEIVE_PATIENT
        do_step(btn_step);             -- -> TRIAGE
        no_room <= '1';
        do_step(btn_step);             -- -> CHECK_RESOURCES; should fault immediately
        wait until rising_edge(clk);  -- one cycle for FSM to process no_room
        wait for 1 ns;
        assert_state("1111", "no fault triggered by no_room");
        assert fault_out = '1' report "FAIL: fault_out not set" severity error;
        no_room <= '0';

        -- Reset clears FAULT
        reset <= '1';
        wait until rising_edge(clk);
        reset <= '0';
        wait until rising_edge(clk);
        assert_state("0000", "reset did not clear FAULT state");

        -- ---- Test: BTNU park (skip release) ----
        wait until rising_edge(clk);
        patient_valid <= '1';
        wait until rising_edge(clk);
        patient_valid <= '0';
        wait until rising_edge(clk);
        do_step(btn_step);  -- -> TRIAGE
        do_step(btn_step);  -- -> CHECK_RESOURCES
        do_step(btn_step);  -- -> ALLOCATE_ROOM
        wait until rising_edge(clk);  -- alloc fires
        do_step(btn_step);  -- -> ALLOCATE_DOCTOR
        wait until rising_edge(clk);
        do_step(btn_step);  -- -> ALLOCATE_EQUIPMENT
        wait until rising_edge(clk);
        do_step(btn_step);  -- -> DISPATCH_TEAM

        -- Park via BTNU (same synchronizer pipeline as step/override).
        -- Pipeline: btn->sync0(e1)->sync1(e2)->prev(e3).
        -- park_pulse = sync1 AND NOT prev fires at e3.
        -- park_en <= '1' registered at e3, readable after delta.
        -- Keep btn_park high through edge 3; sample park_en after edge 3's delta.
        wait until rising_edge(clk);      -- e0: settle
        btn_park <= '1';
        wait until rising_edge(clk);      -- e1: sync0 <= '1'
        wait until rising_edge(clk);      -- e2: sync1 <= '1'
        wait until rising_edge(clk);      -- e3: prev <= '1'; park_pulse fires; park_en <= '1'
        wait for 1 ns;                    -- allow delta cycles to settle
        assert park_en = '1' report "FAIL: park_en not pulsed on btn_park" severity error;
        btn_park <= '0';
        wait until rising_edge(clk);      -- e4: park_en defaults to '0'
        wait for 1 ns;
        assert_state("0000", "did not return to IDLE after park");

        report "tb_scheduler_fsm DONE" severity note;
        wait;
    end process;
end sim;
