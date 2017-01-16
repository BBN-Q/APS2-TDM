# Version 1.0

## Features
* TCP communications with Comblock core
* templated CSR registers from VHDL-Components
* `git describe` style versioning registers with build timestamps
* Vivado 2016.3
* testbench for SATA comms latency
* no "ostrich style" timing ignores - i.e. proper CDC constraints

## Fixes
* system clock reference muxing frequencies match for 10MHz reference and 125MHz MGT clock

# Version 0.12

## Fixes
* module now boots correctly when 10 MHz reference clock is not present

# Version 0.11

## Features
* Upgraded to build on Xilinx Vivado 2015.1
* System clock now synchronized with 10 MHz reference input (if present)
* New internal trigger mode that broadcasts the message `0xFE` on a regular interval (for use as a system trigger source).
