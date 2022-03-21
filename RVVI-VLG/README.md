# RVVI-VLG RISC-V Verification Interface

This is a work in progress


# Overview
----
The following specification defines a method of observing a RISC-V
implementation. Observation is required for the internal state, in addition to
asynchronous event changes on items such as Interrupts and Debug.

The RVVI-VLG interface implementation is comprised of the following files:
- [/source/host/rvvi/rvvi-vlg.sv](../source/host/rvvi/rvvi-vlg.sv)
- [/source/host/rvvi/rvvi-pkg.sv](../source/host/rvvi/rvvi-pkg.sv)


# RVVI-VLG Interface ports
----
This interface provides internal visibility of the state of the RISC-V device.
All signals on the RVVI interface are outputs from the device, for observing
state transitions and state values.

### clk
- The RVVI_VLG interface is synchronous to the positive edge of the clk signal.
  The interface should only be sampled on the positive edge of this clock
  signal.

### valid
- When this signal is true, an instruction has been retired by the device or has
  trapped, and subsequent internal state values will have been updated
  accordingly, this includes the Integer/GPR, Float/FPR, Vector/VR CSR and any
  other supported registers. The instruction address retired is indicated by the
  pc_rdata variable.

### trap
- When this signal is true along with `valid`, an instruction execution has
  undergone a synchronous exception (syscalls, etc). This event allows the
  reading of internal state. The instruction address trapped is indicated by the
  `pc_rdata` variable. If this signal is false when `valid` is asserted, then an
  instruction has retired. This signal will not be asserted during an
  asynchronous exception.

### halt
- When this signal is true, it indicates that the hart has gone into a halted
  state at this instruction.

### intr
- When this signal is true, it indicates that this retired instruction is the
  first instruction which is part of a trap handler.

### order
- This signal contains the instruction count for the instruction being reported
  during a retirement or trap event.

### insn
- This signal contains the instruction word which is at the trap or retirement
  event.

### isize
- The size of the instruction held in `insn`, this should be either
  2(compressed) or 4(uncompressed).

### mode
- This signal indicates the operating mode (Machine, Supervisor, User).

### ixl
- This signal indicates the current `XLEN` for the given privilege mode of
  operation.

### pc_rdata
- This is the address of the instruction at the point of a `valid` event (trap
  or retirement).

### pc_wdata
- This is the address of the next instruction to be executed after a trap or
  retirement event.

### x_wdata, x_wb
- If the bit position within `x_wb` is true, then the position indicates a write
  into X, eg if `x_wb=0x4`, then the register X2 has been written. If
  `x_wb=(1<<4 | 1<<1)` then register X4 and X1 have been written concurrently
  x_wb=0x0 indicates no written X register.

### f_wb, f_wdata
- If the bit position within `f_wb` is true, then the position indicates a write
  into F, eg if `f_wb=0x4`, then the register F2 has been written. If
  `f_wb=(1<<4 | 1<<1)` then register F4 and F1 have been written concurrently
  f_wb=0x0 indicates no written F register.

### v_wb, v_wdata
- If the bit position within `v_wb` is true, then the position indicates a write
  into V, eg if `v_wb=0x4`, then the register V2 has been written. If
  `v_wb=(1<<4 | 1<<1)` then register V4 and V1 have been written concurrently
  v_wb=0x0 indicates no written V register.

### csr_wb, csr
- If the bit position within `csr_wb` is true, then a the position indicates a
  write into csr, eg if `csr_wb=0x1`, then the ustatus register (address 0x000)
  has been written. If `csr_wb=(1<<4 | 1<<0)` then address 0x004 and 0x001 have
  been written concurrently csr_wb=0x0 indicates no written csr.


# RVVI-VLG Interface parameters
----

The RVVI_VLG interface takes a number of parameters which are defined as
follows:

### ILEN
- This is the maximum permissable instruction length in bits.

### XLEN
- This is the maximum permissable General purpose register size in bits.

### FLEN
- This is the maximum permissable Floating point register size in bits.

### VLEN
- This is the maximum permissable Vector register size in bits.

### NHART
- This is the number of harts that will be reported on this interface.

### ISSUE
- This is the maximum number of instructions that can be retired during a
  `valid` event.


# RVVI-VLG Interface functions
----

### net_push
- The `net_push` function is used to submit the status of a processor net to the
  RVVI_VLG interface. Nets are formed as a key/value pair, consisting of the
  net name `vname` and the net value `vvalue`.  Calls to this function will push
  these key value pairs into a fifo, which will be emptied by an RVVI interface
  consumer.

### net_pop
- The `net_pop` function is used by a consumer of the RVVI interface to receive
  any net status updates.  Net changes are popped in the order that they have
  been pushed (FIFO).  This function returns 1 when a net change has been popped
  successfully, or 0 if there was no net change to pop.
