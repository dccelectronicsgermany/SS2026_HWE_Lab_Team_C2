library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BCD_adder is
    port (
        A    : in  STD_LOGIC_VECTOR(3 downto 0);
        B    : in  STD_LOGIC_VECTOR(3 downto 0);
        Cin  : in  STD_LOGIC;
        S    : out STD_LOGIC_VECTOR(3 downto 0);
        Cout : out STD_LOGIC
    );
end entity BCD_adder;

architecture Structural of BCD_adder is

    signal sum     : STD_LOGIC_VECTOR(3 downto 0);
    signal c1      : STD_LOGIC;
    signal correct : STD_LOGIC;
    signal sum2    : STD_LOGIC_VECTOR(3 downto 0);
    signal c2      : STD_LOGIC;

begin

    -- First addition: A + B + Cin
    ADD1 : entity work.CR_adder(Structural)
        port map (
            A    => A,
            B    => B,
            Cin  => Cin,
            S    => sum,
            Cout => c1
        );

    -- Correction needed if sum > 9 (1001) or carry out
    correct <= c1 or (sum(3) and sum(1)) or (sum(3) and sum(2));

    -- Add 6 (0110) if correction needed
    ADD2 : entity work.CR_adder(Structural)
        port map (
            A    => sum,
            B(0) => '0',
            B(1) => correct,
            B(2) => correct,
            B(3) => '0',
            Cin  => '0',
            S    => S,
            Cout => c2
        );

    Cout <= c1 or c2;

end architecture Structural;
