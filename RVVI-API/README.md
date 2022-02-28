# RVVI-API RISC-V Verification Interface

This repository contains a draft of RVVI-API, a standard interface for lockstep
comparison between two RISC-V models for DV purposes.


----
# Overview

The RVVI-API is defined and is provided here as a header file and can be found
in the following location:
- [/include/host/rvvi/rvvi-api.h](../include/host/rvvi/rvvi-api.h) C/C++
- [/include/host/rvvi/rvvi-api.svh](../include/host/rvvi/rvvi-api.svh)
  SystemVerilog

This RVVI API can be driven directly from a test-bench, or indirectly via
instantiation of the VLG2API verilog module. It is recommended to use VLG2API
however for ease of integration, use and robustness.

There are three main phases a test harness will be in charge of:
- Initialization
- The main loop
- Shutdown

The initialization phase is as follows:
- The test harness first initializes ImperasDV specifying the reference model
  to use and a path to a test case ELF file.
- Next, the DUT can be initialized, allowing it to make use of RVVI-API
  functions if required.

The main loop then begins which will continue until a terminal state is
encountered. The loop is generally constructed as follows:
- The DUT model is stepped a variable number of cycles.
- During these cycles the tracer interface will report an instruction retirement
  or trap.
- This retirement/trap will be handled by VLG2API which will drive the RVVI-API
  interface appropriately.
- When VLG2API is being driven it will handle stepping of the reference model as
  well as triggering any comparisons between the reference model and DUT.
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
