# RVVI-TRACE RISC-V Verification Interface

Version 1.5

This is a work in progress

----
## Overview

The following specification defines a method of observing a RISC-V
implementation. Observation of the internal state is required, in addition to
asynchronous event changes on items such as Interrupts and Debug nets.

The primary RVVI-TRACE interface, `rvviTrace`, is specified in the following
file:
- [/source/host/rvvi/rvvi-trace.sv](../source/host/rvvi/rvvi-trace.sv)

A number of illustrative waveform diagrams are provided in the [Example Waveforms](#example-waveform-diagrams) section.

----
## rvviTrace Interface parameters

The `rvviTrace` interface takes a number of parameters which are defined as follows:

| Param. Name | Description                                                                  |
| ----------- | ---------------------------------------------------------------------------- |
| `ILEN`      | The maximum permissible instruction length in bits.                          |
| `XLEN`      | The maximum permissible General purpose register size in bits.               |
| `FLEN`      | The maximum permissible Floating point register size in bits.                |
| `VLEN`      | The maximum permissible Vector register size in bits.                        |
| `NHART`     | The number of harts that will be reported on this interface.                 |
| `RETIRE`    | The maximum number of instructions that can be retired during a valid event. |

----
## rvviTrace Interface ports

This interface provides internal visibility of the state of the RISC-V device.
All signals on the RVVI interface are outputs from the device, for observing
state transitions and state values.

### `clk`
The RVVI Trace interface is synchronous to the positive edge of the clk
signal. The interface should only be sampled on the positive edge of this
clock signal.

### `valid`
When this signal is true, an instruction has been retired by the device or has
trapped, and subsequent internal state values will have been updated
accordingly, this includes the Integer/GPR, Float/FPR, Vector/VR CSR and any
other supported registers. The instruction address retired is indicated by the
pc_rdata variable.

### `order`
This signal contains the instruction count for the instruction being reported
during a retirement or trap event.

### `insn`
This signal contains the instruction word which is at the trap or retirement
event.

### `trap`
When this signal is true along with `valid`, an instruction execution has
undergone a synchronous exception (syscalls, etc). This event allows the
reading of internal state. The instruction address trapped is indicated by the
`pc_rdata` variable. If this signal is false when `valid` is asserted, then an
instruction has retired.

### `halt`
When this signal is true, it indicates that the hart has gone into a halted
state at this instruction.

### `intr`
When this signal is true, it indicates that this retired instruction is the
first instruction which is part of a trap handler.

### `mode`
This signal indicates the operating mode (Machine, Supervisor, User).

### `ixl`
This signal indicates the current `XLEN` for the given privilege mode of
operation.

### `pc_rdata`
This is the address of the instruction at the point of a `valid` event (trap
or retirement).

### `pc_wdata`
This is the address of the next instruction to be executed after a trap or
retirement event.

### `x_wdata`, `x_wb`
If the bit position within `x_wb` is true, then the position indicates a write
into X, eg if `x_wb=0x4`, then the register X2 has been written. If
`x_wb=(1<<4 | 1<<1)` then register X4 and X1 have been written concurrently
x_wb=0x0 indicates no written X register.

### `f_wdata`, `f_wb`
If the bit position within `f_wb` is true, then the position indicates a write
into F, eg if `f_wb=0x4`, then the register F2 has been written. If
`f_wb=(1<<4 | 1<<1)` then register F4 and F1 have been written concurrently
f_wb=0x0 indicates no written F register.

### `v_wdata`, `v_wb`
If the bit position within `v_wb` is true, then the position indicates a write
into V, eg if `v_wb=0x4`, then the register V2 has been written. If
`v_wb=(1<<4 | 1<<1)` then register V4 and V1 have been written concurrently
v_wb=0x0 indicates no written V register.

### `csr`, `csr_wb`
If the bit position within `csr_wb` is true, then a the position indicates a
write into csr, eg if `csr_wb=0x1`, then the ustatus register (address 0x000)
has been written. If `csr_wb=(1<<4 | 1<<0)` then address 0x004 and 0x001 have
been written concurrently csr_wb=0x0 indicates no written csr.

### `lrsc_cancel`
If this signal is true then this indicates that the reference model should
clear any current LR/SC reservation _after_ the retirement of the current
instruction. This signal should _NOT_ be used to indicate reservation
cancellations caused by the normal operation of the `SC` instruction. Use of
this signal is only to propagate _implementation defined_ cancellations to the
reference model.

----
## rvviTrace Interface functions

### `net_push()`
The `net_push` function is used to submit the status of a processor net to the
`rvviTrace` interface. Nets are formed as a key/value pair, consisting of the
net name `vname` and the net value `vvalue`. Calls to this function will push
these key value pairs into a fifo, which will be emptied by an RVVI interface
consumer.

### `net_pop()`
The `net_pop` function is used by a consumer of the RVVI interface to receive
any net status updates. Net changes are popped in the order that they have been
pushed (FIFO). This function returns 1 when a net change has been popped
successfully, or 0 if there was no net change to pop.

----
## Example waveform diagrams

A number of example waveform diagrams showing RVVI-TRACE event sequences is
provided for clarity. Please note that a reduced set of signals is shown in
these examples for the sake of brevity and a real implementation would be
expected to drive all required.

### Instruction retirement

![Instruction Retirement](../diagrams/InstructionRetirement.png)

The diagram above a number of instructions being retired, with GPR and CSR
register file writes being communicated as a result.

### Load address misaligned

![LoadAddressMisalignedTrap](../diagrams/LoadAddressMisalignedTrap.png)

The diagram above shows a processor taking a synchronous exception due to
execution of a load word instruction from a non-aligned memory address.

### Environment call exception

![Environment call](../diagrams/EnvironmentCallException.png)

The diagram above shows a processor executing of an ECALL instruction.

> _RISC-V privileged specification 20211203, section 3.3.1:_
>
> As ECALL and EBREAK cause synchronous exceptions, they are not considered to
> retire, and should not increment the minstret CSR.

Execution of an ECALL instruction results in a trap being raised and the
instruction does not retire. Thus a trap event should be presented on the
RVVI-TRACE interface, with the `trap` signal being asserted, and all relevant
CSRs modified by the trap being provided.
