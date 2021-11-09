# RISC-V Verification Interface (RVVI) Version 0.2
==================================================

This is a work in progress.

About
-----
When verifying RISC-V CPU RTL in a Verilog simulator interfaces are needed between the core RTL and the test bench.

Each RISC-V core being designed so far has implemented its own specific bespoke interface for the specific core and a specific bespoke test bench. This means with each design and testbench having its own custom interface very little re-use can be made and the process is inefficient and time consuming. More effort goes into testing than design and so it is essential going forward to make the hardware design verification (HW DV) process as efficient as possible.

The RISC-V Verification Interface (RVVI) is a definition of a series of SystemVerilog interfaces that when implemented enable testbench re-use over different cores.

This is of benefit for not just test bench re-use but also for test generators and other testing methodologies.

History
-------
This work has evolved from the experience by Imperas, EMMicro, SiLabs working with several RISC-V verification projects including its collaboration in OpenHW Group (https://github.com/openhwgroup/core-v-verif) on the Core-V range of RISC-V cores.

There is the RISC-V Formal Interface (RVFI) (https://github.com/SymbioticEDA/riscv-formal) from SymbioticEDA which is a very good interface for providing observation into a running core by streaming what is executing on the core  - but for HW DV more is needed. Hence the need for RVVI. The RVVI_status interface is very similar to the RVFI interface.

Specification
-------------
Please see the [RVVI specification document](docs/rvvi.md) in the [docs](docs) directory for details.

##
