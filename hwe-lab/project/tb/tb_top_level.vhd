library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Integration smoke-test for top_level.
-- CLK_FREQ=4 so treatment timer expires in a few clock cycles.
-- Scenario 1: one patient dispatched, treatment completes, resources released.
-- Scenario 2: patient dispatched then parked (BTNU) - resources stay busy.
-- Scenario 3: parked patient released via BTND+BTNC (slot 0).

entity tb_top_level is
end tb_top_level;

architecture sim of tb_top_level is
    signal CLK100MHZ   : std_logic := '0';
    signal CPU_RESETN  : std_logic := '0';  -- active-low, 0 = reset asserted
    signal SW          : std_logic_vector(7 downto 0) := (others => '0');
    signal BTNL        : std_logic := '0';
    signal BTNC        : std_logic := '0';
    signal BTNR        : std_logic := '0';
    signal BTNU        : std_logic := '0';
    signal BTND        : std_logic := '0';
    signal LED         : std_logic_vector(15 downto 0);
    signal AN          : std_logic_vector(7 downto 0);
    signal SEG         : std_logic_vector(6 downto 0);
    signal DP          : std_logic;
    signal UART_TXD_IN : std_logic;

    constant CLK_P : time := 10 ns;

    -- Press a button through the 2-stage synchronizer + edge detect (hold 5 edges).
    procedure press(signal btn : out std_logic) is
    begin
        wait until rising_edge(CLK100MHZ);
        btn <= '1';
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        btn <= '0';
        wait until rising_edge(CLK100MHZ);
    end procedure;

    -- BTND held + BTNC rising edge = selective release.
    procedure selective_release(signal d : out std_logic; signal c : out std_logic) is
    begin
        wait until rising_edge(CLK100MHZ);
        d <= '1';
        -- wait for BTND to propagate through synchronizer (2 cycles)
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        -- now press BTNC to create rel_en pulse
        c <= '1';
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        c <= '0';
        wait until rising_edge(CLK100MHZ);
        d <= '0';
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
    end procedure;
begin
    CLK100MHZ <= not CLK100MHZ after CLK_P / 2;

    uut : entity work.top_level
        generic map (CLK_FREQ => 4)
        port map (
            CLK100MHZ   => CLK100MHZ,
            CPU_RESETN  => CPU_RESETN,
            SW          => SW,
            BTNL        => BTNL,
            BTNC        => BTNC,
            BTNR        => BTNR,
            BTNU        => BTNU,
            BTND        => BTND,
            LED         => LED,
            AN          => AN,
            SEG         => SEG,
            DP          => DP,
            UART_TXD_IN => UART_TXD_IN
        );

    process
    begin
        -- release reset after a few cycles
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        CPU_RESETN <= '1';
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);

        -- ============================================================
        -- Scenario 1: full dispatch -> release cycle
        -- SW[7:4]=0101 -> patient ID=5; SW[3:2]=00 -> General; SW[1:0]=01 -> Urgent
        -- ============================================================
        SW <= "01010001";

        -- Submit new patient (BTNL = btn_new in patient_generator)
        press(BTNL);
        wait until rising_edge(CLK100MHZ);
        -- FSM should now be in RECEIVE_PATIENT (code 0001)

        press(BTNC);  -- -> TRIAGE
        wait until rising_edge(CLK100MHZ);

        press(BTNC);  -- -> CHECK_RESOURCES
        wait until rising_edge(CLK100MHZ);

        press(BTNC);  -- -> ALLOCATE_ROOM
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);

        press(BTNC);  -- -> ALLOCATE_DOCTOR
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);

        press(BTNC);  -- -> ALLOCATE_EQUIPMENT
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);

        press(BTNC);  -- -> DISPATCH_TEAM
        wait until rising_edge(CLK100MHZ);

        -- In DISPATCH_TEAM: treatment_active = LED(13)
        assert LED(13) = '1'
            report "FAIL S1: treatment_active LED not set at DISPATCH_TEAM" severity error;

        -- Room 1 should be busy: LED(0)
        assert LED(0) = '1'
            report "FAIL S1: room 1 not busy" severity error;

        press(BTNC);  -- -> MONITOR_TREATMENT
        -- Timer: CLK_FREQ=4, sev=01 -> 2*4=8 cycles; wait enough
        wait for 200 ns;
        -- Now in RELEASE_RESOURCES; step to IDLE
        press(BTNC);
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);

        -- Back in IDLE: treatment_active off, room freed
        assert LED(13) = '0' report "FAIL S1: treatment_active still set in IDLE" severity error;
        assert LED(0)  = '0' report "FAIL S1: room 1 still busy after release" severity error;

        -- ============================================================
        -- Scenario 2: dispatch then PARK (BTNU keeps resources busy)
        -- SW: ID=5, sev=10 (High), type=00
        -- ============================================================
        SW <= "01010010";
        press(BTNL);
        wait until rising_edge(CLK100MHZ);

        press(BTNC);  -- RECEIVE -> TRIAGE
        wait until rising_edge(CLK100MHZ);
        press(BTNC);  -- TRIAGE -> CHECK_RESOURCES
        wait until rising_edge(CLK100MHZ);
        press(BTNC);  -- CHECK -> ALLOCATE_ROOM
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        press(BTNC);  -- ALLOCATE_ROOM -> ALLOCATE_DOCTOR
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        press(BTNC);  -- ALLOCATE_DOCTOR -> ALLOCATE_EQUIPMENT
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);
        press(BTNC);  -- ALLOCATE_EQUIPMENT -> DISPATCH_TEAM
        wait until rising_edge(CLK100MHZ);

        -- Park patient (BTNU): returns FSM to IDLE, keeps resources busy
        press(BTNU);
        wait until rising_edge(CLK100MHZ);
        wait until rising_edge(CLK100MHZ);

        -- Room 1 should still be busy (parked)
        assert LED(0) = '1'
            report "FAIL S2: room should still be busy after park" severity error;

        -- ============================================================
        -- Scenario 3: selective release of parked slot 0 (SW[1:0]="00")
        -- ============================================================
        SW(1 downto 0) <= "00";
        wait until rising_edge(CLK100MHZ);

        selective_release(BTND, BTNC);

        -- Room 1 should now be free
        assert LED(0) = '0'
            report "FAIL S3: room 1 still busy after selective release" severity error;

        report "tb_top_level DONE" severity note;
        wait;
    end process;
end sim;
