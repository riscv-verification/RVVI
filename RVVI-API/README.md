# RVVI-API

This repository contains a draft of RVVI-API, a standard interface for lockstep comparison between two RISC-V models for DV purposes.


----
# Overview

The RVVI-API is defined and is provided here as a header file and can be found in the following location:
- [include/host/rvvi/rvvi-api.h](include/host/rvvi/rvvi-api.h)    C/C++
- [include/host/rvvi/rvvi-api.svh](include/host/rvvi/rvvi-api.svh) SystemVerilog

The diagram below shows a simplified sequence diagram of the RVVI-API interface and how each of the three pieces of a verification environment interface.

![Overview Image](/RVVI-API/images/overview.jpg)

The test harness shown in the center is in charge of coordinating the sequence of events during testing.
The DUT shown on the left will primarily be a RISC-V core written in Verilog.
The reference model on the right is more complex and consists of a number of distinct elements:
- A golden reference model with all the required features and accuracy.
- A mirror of the DUT state, which is updated via the `rvvi...Set` functions.
- A comparator module which can compare the simulator and mirrored DUT state.

There are three main phases a harness will be in charge of:
- Initialization
- The main loop
- Shutdown

The initialization phase is as follows:
- The test harness first initializes the DUT supplying a path to a test case ELF file.
- The reference subsystem will be initialized, again supplying a path to the same test case ELF file.
- The reference subsystem is informed of any configuration options.

The main loop then begins which will continue until either the terminal state is encountered (pass) or a mismatch is detected (fail).  The loop is generally constructed as follows:
- The DUT model is requested to step until an event occurs.
  - During this call, the DUT will inform the harness of any state changes.
  - The harness will then forward the state changes to the reference model.
- The harness then asks the reference model to step until it encounters the next event.
- After both models have stepped, the harness asks the reference model to compare its state with that of is mirror of the DUT state.
- Simulation will end if a mismatch occurs or both models reached a terminal state, otherwise the main loop will continue.

The shutdown phase is very simple, giving both models a change to release any resources they may have been using.
- The harness will issue a shutdown command to the DUT.
- The harness will issue a shutdown command to the Reference model.

Note: In this context, an event is considered an instruction retirement or a exception being raised.

Note: The harness is also free to inspect the DUT state changes that are received via the `rvvi...Get` callbacks to decide if testing should halt.  This would allow certain instruction sequences or memory access patterns be used as a signal to halt testing.
