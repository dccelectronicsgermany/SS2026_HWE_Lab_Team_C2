# Smart Hospital Dispatcher PCB

## Overview

The **Smart Hospital Dispatcher** is a custom FPGA interface board designed as part of the **Advanced Embedded Systems Laboratory** at Hamm-Lippstadt University of Applied Sciences (HSHL).

The project demonstrates the complete hardware design workflow using **Altium Designer**, from schematic capture to PCB layout and fabrication outputs. The board interfaces with a Digilent Nexys A7 FPGA development board through a custom FPGA connector and provides user inputs, displays, communication interfaces, and power management required for implementing a smart hospital dispatcher system.

---

## Project Objectives

- Design a multi-sheet schematic using Altium Designer.
- Develop a custom FPGA interface board.
- Provide regulated power supplies for FPGA operation.
- Implement user input and output peripherals.
- Produce a manufacturable two-layer PCB.
- Generate fabrication files including Gerber files and Bill of Materials (BOM).

---

## Hardware Features

### FPGA Interface
- Custom 56-pin FPGA interface header
- Compatible with Digilent Nexys A7 (Artix-7 FPGA)

### Power Supply
- 5 V DC input
- 3.3 V regulator
- 1.8 V regulator
- 1.0 V core regulator
- Decoupling capacitors for stable power delivery

### User Inputs
- 8 Slide switches
- 6 Push buttons:
  - CPU Reset
  - New Patient
  - Step FSM
  - Emergency Override
  - Release
  - Park

### User Outputs
- 16 LEDs
- Four dual-digit 7-segment displays
- Magnetic buzzer

### Communication
- UART header
- JTAG programming header

---

## Software Used

- Altium Designer Professional 26.7.1
- GitHub
- Windows 11

---

## Repository Structure

```
Smart_Hospital_Dispatcher/
│
├── Source Documents/
│   ├── 01_Power.SchDoc
│   ├── 02_FPGA_Core.SchDoc
│   ├── 03_Clock_Config_JTAG.SchDoc
│   ├── 04_Inputs.SchDoc
│   ├── 05_Outputs_LEDs.SchDoc
│   ├── 06_7Seg_Display.SchDoc
│   └── 07_Buzzer_UART.SchDoc
│
├── Smart_Hospital_Dispatcher.PcbDoc
├── Smart_Hospital_Dispatcher.PrjPcb
│
├── Documentation/
│   ├── Smart_Hospital_Dispatcher_Schematic.pdf
│   ├── Smart_Hospital_Dispatcher_PCB_Layout.pdf
│   └── Smart_Hospital_Dispatcher_BOM.xlsx
│
└── Gerber_Files/
    ├── Copper Layers
    ├── Solder Mask
    ├── Silkscreen
    ├── Paste Layers
    ├── Board Profile
    ├── PTH Drill Files
    └── NPTH Drill Files
```

---

## PCB Specifications

| Parameter | Value |
|-----------|-------|
| PCB Layers | 2 |
| Design Software | Altium Designer Professional 26.7.1 |
| Power Input | 5 V DC |
| Output Voltages | 3.3 V, 1.8 V, 1.0 V |
| FPGA Interface | 56-pin custom header |
| Technology | Through-hole & Surface Mount |

---

## Project Deliverables

- Multi-sheet schematic
- PCB layout
- Bill of Materials (BOM)
- Gerber fabrication files
- Documentation PDFs

---

## Notes

The PCB was designed for educational purposes as part of the Advanced Embedded Systems Laboratory.

The FPGA is implemented through a custom interface connector to a Digilent Nexys A7 development board rather than being mounted directly on the PCB.
