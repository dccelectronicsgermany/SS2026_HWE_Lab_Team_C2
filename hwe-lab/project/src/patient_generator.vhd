library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity patient_generator is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        btn_new     : in  std_logic;   -- BTN1: new patient trigger
        sw_severity : in  std_logic_vector(1 downto 0);  -- SW0-SW1
        sw_type     : in  std_logic_vector(1 downto 0);  -- SW2-SW3
        sw_id       : in  std_logic_vector(3 downto 0);  -- SW4-SW7
        patient_valid    : out std_logic;
        patient_id       : out std_logic_vector(3 downto 0);
        patient_type     : out std_logic_vector(1 downto 0);
        patient_severity : out std_logic_vector(1 downto 0)
    );
end patient_generator;

architecture rtl of patient_generator is
    signal btn_prev   : std_logic := '0';
    signal btn_sync0  : std_logic := '0';
    signal btn_sync1  : std_logic := '0';
begin
    -- two-stage synchroniser + rising-edge detector
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                btn_sync0 <= '0';
                btn_sync1 <= '0';
                btn_prev  <= '0';
                patient_valid <= '0';
            else
                btn_sync0 <= btn_new;
                btn_sync1 <= btn_sync0;
                btn_prev  <= btn_sync1;

                if btn_sync1 = '1' and btn_prev = '0' then
                    patient_id       <= sw_id;
                    patient_type     <= sw_type;
                    patient_severity <= sw_severity;
                    patient_valid    <= '1';
                else
                    patient_valid <= '0';
                end if;
            end if;
        end if;
    end process;
end rtl;
