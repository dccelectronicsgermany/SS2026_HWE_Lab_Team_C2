# FPGA-Based Smart Hospital Emergency Response Dispatcher

## Overview

This repository contains the implementation and documentation of an FPGA-based Smart Hospital Emergency Response Dispatcher developed for the Hardware Engineering Laboratory at Hochschule Hamm-Lippstadt during the Summer Semester 2026.

The system was implemented in VHDL for the Digilent Nexys A7 FPGA platform and combines digital hardware design, verification, FPGA demonstration, and Altium PCB realization.

## Team C2

- Bertrand Mungu Cho
- Daniel Chidi Chimezie
- Riwaj Ghimire
- Stephen Uzochi Obuh

## Main Features

- Patient registration and input capture
- Triage and priority encoding
- Room, doctor, and equipment allocation
- Scheduler finite-state machine
- Parking of multiple patient assignments
- Selective release of stored patients
- Emergency override
- Resource-exhaustion fault handling
- Safety supervision and alarm latching
- LED status indication
- Seven-segment display output
- UART status transmission
- Full-system reset and recovery

## Hardware Platform

- Digilent Nexys A7
- AMD Artix-7 FPGA
- 100 MHz system clock
- On-board switches, push buttons, LEDs, and seven-segment displays

## Design Structure

The FPGA design consists of ten synthesizable VHDL modules:

1. Patient acquisition
2. Priority encoder
3. Resource manager
4. Scheduler FSM
5. Patient table
6. Safety supervisor
7. LED controller
8. Seven-segment driver
9. UART controller
10. Top-level integration entity

## Verification

The project includes:

- Ten dedicated VHDL testbenches
- 114 assertion statements
- Verification of patient capture, priority mapping, allocation, release, parking, state transitions, alarms, display outputs, UART framing, and top-level integration

## Demonstrated Scenarios

The final FPGA implementation was demonstrated with the following scenarios:

1. Normal urgent-patient dispatch
2. Critical-patient handling
3. Emergency override
4. Multiple-patient parking
5. Selective patient release
6. Resource exhaustion and fault-state entry
7. Full-system reset
8. Hardware resource dashboard

## PCB Development

The Altium design package includes:

- Hierarchical schematics
- Two-layer PCB layout
- Three-dimensional PCB model
- Bill of materials
- Gerber files
- Plated and non-plated drill outputs

The PCB was developed as a manufacture-oriented design package. The final physical laboratory demonstration was performed on the Digilent Nexys A7 board.

## Tools and Technologies

- VHDL
- AMD Vivado Design Suite
- Digilent Nexys A7
- Altium Designer
- UART, 8N1, 115200 baud
- Assertion-based simulation and verification

## Project Report

The complete submitted report is available in:

`HWE_TeamC2_Final_Report_Submitted.pdf`

## Academic Context

**Course:** Hardware Engineering Laboratory  
**Institution:** Hochschule Hamm-Lippstadt  
**Semester:** Summer Semester 2026
