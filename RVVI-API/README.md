# RVVI-API RISC-V Verification Interface

This repository contains a draft of RVVI-API, a standard interface for lockstep
comparison between two RISC-V models for DV purposes.


----
# Overview

The RVVI-API is defined and provided as C and SystemVerilog header files which
can be found in the following locations:
- [/include/host/rvvi/rvvi-api.h](../include/host/rvvi/rvvi-api.h) C/C++
- [/include/host/rvvi/rvvi-api.svh](../include/host/rvvi/rvvi-api.svh)
  SystemVerilog

The associated Doxygen documentation for the `rvvi-api.h` header file can be
browsed here:
- [www.riscv-verification.org/docs/rvvi/doxygen](https://www.riscv-verification.org/docs/rvvi/doxygen).

There are two general approaches for driving the RVVI-API interface:
- Directly from a test bench via DPI calls.
- Indirectly by a verilog module which monitors the `rvviTrace` interface (such
  as `trace2api` provided by Imperas as part of ImperasDV) and issues the
  appropriate calls.

There are three main phases a test harness will be in charge of:
- Initialization
- The main loop
  - Propagate internal state and nets
  - Notify any retirements or traps
  - Compare state to reference model
- Shutdown

The initialization phase is as follows:
- The test harness first initializes an RVVI implementation by calling
  `rvviRefInit` and specifying the reference model to use and a path to a test
  case ELF file.
- Next, the DUT can be initialized, allowing it to make calls to any of the
  RVVI-API functions if required.
- Any CSR registers which are micro architecture dependant can be marked as
  volatile, not something the reference model can predict.
- Any regions of memory that are volatile are also marked during the
  initialization phase. Volatile data will be extracted from the DUT and used by
  the reference model as it updates.
- Any CSR values that are not reported by the reference model can be identified
  at this stage so they can be excluded from comparison operations.
- Incomplete or known faulty CSRs can be masked as this stage to disregard some
  of their bits during comparison.

The main loop then begins which will continue until a terminal state is
encountered. The loop is generally constructed as follows:
- The DUT model is stepped a variable number of cycles.
- During these cycles the tracer interface will report any instruction
  retirements or traps undergone by the processors harts.
- Any changes to the processors nets (interrupt pins, etc) will also be fed to
  the RVVI-API and by extension the reference model.
- The test bench can exit when too many mismatched have occurred or a special
  halting condition has been detected.

In this manner the RVVI-API can be seen as a slave or a consumer of the DUTs
tracer interface.

The harness is also free to inspect the reference model state at any stage via
the RVVI-API functions which can allow custom comparison routines to be
constructed as needed.

The shutdown phase is very simple, giving both models a change to release any
resources they may have been using.
- The harness will issue a shutdown command to the DUT.
- The harness will issue a shutdown command to the Reference model.
