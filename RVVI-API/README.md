# RVVI-API RISC-V Verification Interface

Version 1.34

This repository contains a draft of RVVI-API, a standard interface for lockstep
comparison between two RISC-V models for DV purposes.


----
# Overview

The RVVI-API is defined and provided as a C header and SystemVerilog package
which can be found in the following locations:
- [/include/host/rvvi/rvviApi.h](../include/host/rvvi/rvviApi.h) C/C++.
- [/source/host/rvvi/rvviApiPkg.sv](../source/host/rvvi/rvviApiPkg.sv)
  SystemVerilog.

There are two general approaches for driving the RVVI-API interface:
- Directly from a test bench via DPI calls.
- Indirectly by a SystemVerilog module which monitors the `rvviTrace` interface
  (such as `trace2api` provided by Imperas as part of ImperasDV) and issues the
  appropriate calls.

There are three main phases a test harness will be in charge of:
- Initialization
- The main loop
  - Propagation of RTL internal state and nets
  - Notification of any instruction retirements or traps
  - Comparison of RTL state to reference model
- Shutdown

The initialization phase is as follows:
- Configuration options are supplied to RVVI via the `rvviRefConfigSetString`
  and `rvviRefConfigSetInt` functions as required.
  - The configuration options which can be specified are defined by the RVVI
    implementation rather than the RVVI standard. Please consult your
    implementations documentation for further details.
- The test harness then initializes the RVVI implementation by calling
  `rvviRefInit` and specifying a path to a test case ELF file to load into the
  reference model.
- Next, the DUT can be initialized, which can freely make calls to any of the
  RVVI-API functions if required.
- CSR registers can be marked as volatile as required:
  - Any CSR register which is micro architecture dependent can be marked as
    volatile, if it is not something the reference model can predict, using
    `rvviRefCsrSetVolatile`.
  - Sometimes only specific bits of a CSR register are volatile, and so the
    `rvviRefCsrSetVolatileMask` function can mark specific bits as volatile.
- CSR registers can be excluded from comparison:
  - Specific CSR registers can be disabled for comparison if required, using the
    `rvviRefCsrCompareEnable` function.
  - Specific bits within a CSR can be excluded from comparison using the
    `rvviRefCsrCompareMask`.
  - This may be necessary if a CSR register is known to be faulty or incorrect.
- Any regions of memory that are volatile are also marked during the
  initialization phase. Volatile data will be extracted from the DUT and used by
  the reference model as it updates. This can be required when dealing with
  memory mapped IO and memory mapped peripherals for example.

The main loop then begins which will continue until a terminal state is
encountered. The loop is generally constructed as follows:
- The DUT model is stepped a variable number of cycles.
- During these cycles the tracer interface will report any instruction
  retirements or traps undergone by the processors harts.
- Any changes to the processors nets (interrupt pins, etc) will also be fed to
  the RVVI-API and by extension the reference model.
- On an instruction retirement event, the testbench can use the RVVI-API to
  perform a comparison between its communicated state and that of the
  reference model.
  - Any mismatches will be reported to the user for investigation.
- The test bench can exit when too many mismatched have occurred or a defined
  halting condition has been detected.

In this manner the RVVI-API can be seen as a slave or a consumer of the DUTs
tracer interface.

The harness is also free to inspect the reference model state at any stage via
specific RVVI-API functions (`rvviRefPcGet`, `rvviRefGprGet`, etc) which can
allow custom comparison routines to be constructed as needed.

The shutdown phase is very simple, giving both models a chance to release any
resources they may have been using.
- The harness will issue a shutdown command to the DUT.
- The harness will issue a shutdown command to the Reference model via
  `rvviRefShutdown`.
