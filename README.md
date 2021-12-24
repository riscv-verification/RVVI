# RISC-V Verification Interface (RVVI) Version 0.5
==============================================================

This is a work in progress.

About
-----
When verifying RISC-V CPU RTL in a Verilog simulator interfaces are needed between the core RTL and the test bench.

Each RISC-V core being designed so far has implemented its own specific bespoke interface for the specific core and a specific bespoke test bench. This means with each design and testbench having its own custom interface very little re-use can be made and the process is inefficient and time consuming. More effort goes into testing than design and so it is essential going forward to make the hardware design verification (HW DV) process as efficient as possible.

The RISC-V Verification Interface (RVVI) is a draft open standard that defines several of the interfaces required to bring together several of the subsystesm required for RISC-V processor DV.

By adopting these standards, components can be created that can be re-used across different design teams within a company, across different companies, and also for open source components to be developed, made available, and be included easily. 

Of course, if DV components use these standards as they are developed for one design, they can be easily used for subsequent designs in one team. 

In short standards such as RVVI make re-use possible for RISC-V processor DV.

Use of RVVI is not just of benefit for test bench re-use but also for test generators, functional coverage, and other testing methodologies.

Currently there are 3 different areas that RVVI addresses:

The core (Device Under Test) RTL Verilog interface - RVVI-VLG
-----
First is the interface to the internals of the RTL of the core's micro-architecture to provide values, state, and events related to the internal signals up to several of the testbench components. Traditionally this was done to provide tracing capabilities such as for log file writing. This interface or similar has been used to create a 'tracer'.

The RVVI-VLG interface includes capabilities for use with simple single hart in-order cores to multi-hart, multi-issue, Out-of-Order, cores with asynchonous interrupts, and debug modes etc.


The RVVI-VLG interface is defined in SystemVerilog.

The reference model DV subsystem interface - RVVI-API
-----
To verify a RISC-V core requires comparison of the Device Under Test (DUT) against a reference model. This is not as simple as just running programs on the reference and DUT and comparing PC values - it needs to take into account all ISA architectural features and options including full asynchronous operation. 

The RVVI-API interface is a set of API function calls that abstract away all details of the operation of processor reference models and decouples the test bench from anny specific reference model.

The RVVI-API is a C/C++ API and can be used with C/C++ test benches. RVVI-API also is defined with a SystemVerilog DPI wrapper to be used in SystemVerilog test benches.


Common Virtual Periherals used in the test bench - RVVI-VPI
-----
When testing a processor there are components needed in the test bench to interact with the processor - for example virtual UART to print information from the program operation, and timers to generate asynchronous interrupts.

These components are being defined so that they can be used in C/C++, SystemVerilog, test benches, and also in some cases within ISS - to allow ease of test creation.

This RVVI-VPI is currently a work in progress and  will cover: timers, interrupts, debug, random, and printer/UART capabilities.

History
-------
This work has evolved from the experience by Imperas, EMMicro, SiLabs working with several RISC-V verification projects including its collaboration in OpenHW Group (https://github.com/openhwgroup/core-v-verif) on the Core-V range of open-source RISC-V cores.

There is the RISC-V Formal Interface (RVFI) (https://github.com/SymbioticEDA/riscv-formal) from SymbioticEDA which is a very good interface for providing observation into a running core by streaming what is executing on the core (i.e. the basic tracer funtionality) - but for quality RISC-V processor DV more is needed. Hence the need for RVVI. The RVVI-VLG interface has some parts very similar to the RVFI interface.

Specification
-------------
Please see the [RVVI specification document](docs/rvvi.md) in the [docs](docs) directory for details.

##
