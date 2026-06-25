What we implemented:

Top module name:

One_Digit_Counter

Inputs:

CLK100MHZ
START_STOP
CLEAR

Outputs:

CA, CB, CC, CD, CE, CF, CG, DP
AN

Board connection used

Function        Nexys A7 input
Start / Stop   SW0
Clear / Reset  BTNC
Display        One digit of onboard 7-segment display
Clock          100 MHz onboard clock

Important notes

The VHDL uses only standard VHDL types:

bit
bit_vector
integer

No std_logic, no std_logic_vector, and no IEEE std_logic_1164 library are used.

The counter counts:

0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9 -> 0

When:

START_STOP = 1

the counter runs.

When:

START_STOP = 0

the counter pauses.

When:

CLEAR = 1

the counter resets to zero.

The display is active-low, as required for the Nexys A7 7-segment display.
