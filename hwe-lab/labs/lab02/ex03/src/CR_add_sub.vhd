library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CR_add_sub is
    port (
        A    : in  STD_LOGIC_VECTOR(3 downto 0);
        B    : in  STD_LOGIC_VECTOR(3 downto 0);
        Mode : in  STD_LOGIC;
        S    : out STD_LOGIC_VECTOR(3 downto 0);
        Cout : out STD_LOGIC
    );
end entity CR_add_sub;

architecture Structural of CR_add_sub is

    signal B_sel : STD_LOGIC_VECTOR(3 downto 0);

begin

    B_sel(0) <= B(0) xor Mode;
    B_sel(1) <= B(1) xor Mode;
    B_sel(2) <= B(2) xor Mode;
    B_sel(3) <= B(3) xor Mode;

    ADDER : entity work.CR_adder(Structural)
        port map (
            A    => A,
            B    => B_sel,
            Cin  => Mode,
            S    => S,
            Cout => Cout
        );

end architecture Structural;
