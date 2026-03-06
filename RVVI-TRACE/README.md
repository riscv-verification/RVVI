# RVVI-TRACE RISC-V Verification Interface

Version 1.7

This is a work in progress

----
## Overview

The following specification defines a method of observing a RISC-V
implementation. Observation of the internal state is required, in addition to
asynchronous event changes on items such as Interrupts and Debug nets.

The primary RVVI-TRACE interface, `rvviTrace`, is specified in the following
file:
- [/source/host/rvvi/rvviTrace.sv](../source/host/rvvi/rvviTrace.sv)

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

Please note that the data conveyed on this interface should not be relied upon
to persist beyond an individual event.

### `clk`
The RVVI Trace interface is synchronous to the positive edge of the clk
signal. The interface should only be sampled on the positive edge of this
clock signal.

### `valid`
When this signal is true, an event is being communicated on the RVVI-TRACE
interface. An event may be, for example, that an instruction has been retired or
has trapped, and any changed processor state will also be communicated
accordingly, this includes the Integer/GPR, Float/FPR, Vector/VR
CSR and any other supported registers. The instruction address which retired is
indicated by the pc_rdata variable.

### `order`
This signal contains the event count for the event being reported during a retirement or 
trap event. The value of order should monotonically repeat with no gaps or repeats

### `insn`
This signal contains the instruction word which is at the trap or retirement
event. The instruction word should always be reported with little-endian byte
ordering regardless of the mstatus.mbe field or endianness of the processor.

### `trap`
When this signal is true along with `valid`, instruction execution has resulted
in an exception to program execution to occur . This event allows the state of the
DUT to be conveyed between instruction retirements. The address of the
instruction which trapped is indicated by the `pc_rdata` variable. If this
signal is false when `valid` is asserted, then an instruction has instead
retired normally. State comparison will only occur upon instruction retirement (trap=0)

### `halt`
When this signal is true, it indicates that the hart has entered a halted
state as a result of executing this instruction.

### `intr`
When this signal is true, it indicates that this retired instruction is the
first instruction which is part of a trap handler.

### `mode`

The `mode` signal combined with the `mode_virt` signal indicates the operating
mode of the processor during the current RVVI event.

If the RISC-V Hypervisor Extension is absent then `mode_virt` should be set to 0
and `mode` is interpreted as follows:

| name       | `mode`  |
|------------|---------|
| USER       | 0       |
| SUPERVISOR | 1       |
| MACHINE    | 3       |

If the RISC-V Hypervisor Extension is present then the following table applies:

| name                                  | `mode`  | `mode_virt` |
|---------------------------------------|---------|-------------|
| USER                                  | 0       | 0           |
| HYPERVISOR-EXTENDED SUPERVISOR        | 1       | 0           |
| MACHINE                               | 3       | 0           |
| VIRTUAL USER                          | 0       | 1           |
| VIRTUAL SUPERVISOR                    | 1       | 1           |

All other combinations are currently undefined within the RVVI specification.

### `mode_virt`
See description for `mode`.

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
x_wb=0x0 indicates no written X register. If `x_wb` is false, then the contents
is undefined.

### `f_wdata`, `f_wb`
If the bit position within `f_wb` is true, then the position indicates a write
into F, eg if `f_wb=0x4`, then the register F2 has been written. If
`f_wb=(1<<4 | 1<<1)` then register F4 and F1 have been written concurrently
f_wb=0x0 indicates no written F register. If `f_wb` is false, then the contents
is undefined.

### `v_wdata`, `v_wb`
If the bit position within `v_wb` is true, then the position indicates a write
into V, eg if `v_wb=0x4`, then the register V2 has been written. If
`v_wb=(1<<4 | 1<<1)` then register V4 and V1 have been written concurrently
v_wb=0x0 indicates no written V register. If `v_wb` is false, then the contents
is undefined.

### `csr`, `csr_wb`
If the bit position within `csr_wb` is true, then a the position indicates a
write into csr, eg if `csr_wb=0x1`, then the ustatus register (address 0x000)
has been written. If `csr_wb=(1<<4 | 1<<0)` then address 0x004 and 0x001 have
been written concurrently csr_wb=0x0 indicates no written csr. If `csr_wb` is
false, then the contents is undefined.

### `lrsc_cancel`
If this signal is true then this indicates that the reference model should
clear any current LR/SC reservation _after_ the retirement of the current
instruction. This signal should _NOT_ be used to indicate reservation
cancellations caused by the normal operation of the `SC` instruction. Use of
this signal is only to propagate _implementation defined_ cancellations to the
reference model.

### `debug_mode`
This signal should be driven true if the current instruction retirement event
takes place when the processor is operating in debug mode. This signal should be
driven false otherwise. This is an optional signal, and should be tied to false
when unused.

### `state`

The `state` associative array is per-hart and can be used to communicate hart
specific state that doesn't otherwise have a dedicated means of conveyance.
State information is provided as a key value pair, allowing arbitrary data to
be encoded. Both key and value have string type for maximum flexibility without
data length restrictions. Value data inside the string should typically be
encoded in hexadecimal format where possible, and zero padded to the source
data width.

It is expected that such state information will be somewhat implementation
specific and so rvviTrace clients should not attempt to parse any `state`
entries that they do not recognize.

The `state` array can be used to track shadowed or multiplexed CSRs such as
the trigger `tdata` registers (debug extension) or `mireg` registers
(Smcsrind/Sscrind extension). 

#### Trigger registers

In the case of the trigger registers, the following key naming scheme should be used:
`csr_tdataX_tselectY` where X is the _tdata_ number, and Y is the trigger number in _tselect_.
i.e. `csr_tdata1_tselect0`, `csr_tdata2_tselect2`.

#### Indirect registers

In the case of the `mireg` registers the following naming scheme should be used:
`csr_miregX_miselectY` where X is the _mireg_ number, and Y is the value in `miselect`.

> Note: when X has a value of 1 it should be omitted however to match the `Smcsrind/Sscrind`
extension naming convention. e.g. `csr_mireg_miselect1`.

The same naming convention should be applied equally to the _sireg_ and _vsreg_ registers.

----
## rvviTrace Interface functions

### `client_register(logic recv_nets, logic recv_memory)`
A RVVI client can be registered using the `client_register` function. The maximum
number of clients can be set via the `CLIENTS_MAX` `rvviTrace` parameter.
the `recv_nets` and `recv_memory` parameters specify if the client should receive
net event and memory event information respectively.
The `client_register` call will return a unique client that must be provided when
making calls to `net_pop` and `mem_access_pop`.
Each client gets its own FIFO for net and memory events so that multiple clients
can operate independently.

### `net_push()`
The `net_push` function is used to submit the status of a processor net to the
`rvviTrace` interface. Net changes are formed as a key/value pair, consisting of
the net name `vname` and the net value `vvalue`. Calls to this function broadcast
net changes to all of the clients registered to receive net changes.
Net events should typically be submitted as soon as a net change on the periphery
of the DUT core.

### `net_pop()`
The `net_pop` function is used by a client of the RVVI interface to receive
any net change events. Net events are popped in the order that they have been
pushed (FIFO). This function returns 1 when a net change has been popped
successfully, or 0 if there was no net change to pop.
`net_pop` should only be called by clients that have registered to receive
net changes by setting `recv_nets` when registered.

### `mem_access_push()`
The `mem_access_push` function is used to broadcast a memory access event to
all of the rvviTrace clients registered to receive memory events.
Any memory access events should be pushed by the DUT tracer prior to asserting the
`valid` bit in rvviTrace. All pushed memory events will be associated with the
currently retiring/trapping instruction when the `valid` bit of rvviTrace is set.
Multiple memory access events can be submitted as required by the currently
retiring 

### `mem_access_pop()`
the `mem_access_pop` function is called by clients of rvviTrace that have
registered to receive memory events by setting `recv_memory`.
A value of 1 will be returned when a memory event has been returned via the
`access` output argument.

----
## Memory access records

Memory access tracing is an optional part of rvviTrace and is not required to
be implemented.

Memory access events are encapsulated in `rvvi_mem_access_t` structures.
As the DUT executes instructions that touch memory the DUT tracer can push
`rvvi_mem_access_t` structures to describe the accesses as they are made.

Multiple non-contiguous accesses can be described by pushing multiple
mem access structures for each of the partial accesses performed.

In the case that a large architectural access is broken into smaller accesses
by the DUT, each smaller access can be pushed individually.
This may occur for a number of reasons such as a unaligned load being split
into smaller aligned loads, or larger loads that straddle page / cache line
boundaries.

- How a DUT breaks up accesses (if required) is left up to the implementation.
- There is no ordering requirement, multiple accesses can be pushed in any order.
- There should not be any overlap between the access records pushed.
- Partial memory access records can be submitted for instructions that do not complete.
- All page information should be set to 0 if paging is not currently enabled.
- `gaddr` should be set to 0 when a guest address is not produced.

----
## Example waveform diagrams

A number of example waveform diagrams showing RVVI-TRACE event sequences is
provided for clarity. Please note that a reduced set of signals is shown in
these examples for the sake of brevity and a real implementation would be
expected to drive all required.

### Instruction retirement

![Instruction Retirement](../diagrams/InstructionRetirement.png)

The diagram above shows a number of instructions being retired, with GPR and CSR
register file writes being communicated as a result.

### Load address misaligned

![LoadAddressMisalignedTrap](../diagrams/LoadAddressMisalignedTrap.png)

The diagram above shows a processor taking a synchronous exception due to the
execution of a load word instruction from a non-aligned memory address.

### Environment call exception

![Environment call](../diagrams/EnvironmentCallException.png)

The diagram above shows a processor executing an ECALL instruction.

> _RISC-V privileged specification 20211203, section 3.3.1:_
>
> As ECALL and EBREAK cause synchronous exceptions, they are not considered to
> retire, and should not increment the minstret CSR.

Execution of an ECALL instruction results in a trap being raised and the
instruction does not retire. Thus a trap event should be presented on the
RVVI-TRACE interface, with the `trap` signal being asserted, and all relevant
CSRs modified by the trap being provided.

### Resume from WFI

![Resume from WFI with MSTATUS.MIE=0](../diagrams/WFIMie0.png)

The diagram above shows a processor retiring a WFI instruction. The processor
then resumes from its halted state because an interrupt net has been asserted.
Since the global interrupt enable is 0, no interrupt is taken.

![Resume from WFI with MSTATUS.MIE=1](../diagrams/WFIMie1.png)

With interrupts enabled as shown above, the processor resumes from the WFI and
branches to the trap handler.
