# FPGA Calculator

A simple calculator coded in verilog HDL

## Description
The code has been successfully implemented and verified on a Xilinx Basys 3 Artix-7 FPGA Board. The code heavily uses Finite-State Machine to implement the calculator function, to check the inputs and to display numbers on the Seven-Segments Displays (SSDs) on the FPGA board. 

## Design

1. The code implements SSD multiplexing, where each displays are switch on/off consecutively at a very fast rate to display multiple digits.
3. The calculator adds two 4-bit 2's complement number and outputs a 4-bit 2's complement number. 
3. The display will show negative when the output is a negative number
4. The calculator has 2 modes, controlled by a switch. 
   * The first mode will display a pre-set number with character rolling effect.
   * The second mode is the calculator.

## Images

