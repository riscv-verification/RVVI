# RVVI RISC-V Verification Interface

This is a work in progress

RVVI Specification
------------------
The following specification defines a method of observing a RISCV implementation.
Observation is required for the internal state, in addition to asynchronous event changes
on items such as Interrupts and Debug


RVVI-VLG Interface
-------------------
This interface provides internal visibility of the state of the RISC-V device.
It also provides a notifier event to indicate a change of state, following a data change.
All signals on the RVVI_state Interface are outputs from the device, for observing state transitions
and state values

**notify:**  
This is an event to indicate some change of state following the completion of an event
An event can either be an instruction (or many instructions) retiring, or
an instruction (or many instructions) causing an exception
When the notify event is asserted the signals, valid, trap and halt indicate
the current state at this notification event point.

Dependant upon how many instructions can retire (NRET) in a single cycle, each of the following variables
are sized (in width) by that NRET value, so if the architecture is able to retire 4 instructions 
within a single cycle, then the width of these variable is [4]
In addition the variables are also sized by the number of harts being handled through the interface

**valid:**  
When this signal is true at a notify event, an instruction has been successfully retired by the
device, subsequent internal state values will have been updated accordingly, this includes the 
Integer/GPR, Float/FPR, Vector/VR CSR and any other supported registers. 
The instruction address retired is indicated by the pc_rdata variable

**trap:**  
When this signal is true at a notify event, an instruction execution has undergone an exception for
some reason, this could include synchronous/asynchronous exception, or a debug request.
This event allows the reading of internal state.
The instruction address trapped is indicated by the pc_rdata variable

**halt:**  
When this signal is true at a notify event, it indicates that the hart has gone into a halted state
at this instruction

**intr:**  
When this signal is true at a notify event, it indicates that this retired instruction is the first
instruction which is part of a trap handler.

**order:**  
This signal contains the instruction count for the instruction being reported at the notifier event

**insn:**  
This signal contains the instruction word which is at the trap or valid event

**isize:**  
The size of the instruction held in insn, this should be either 2(compressed) or 4(uncompressed) 

**mode:**  
This signal indicates the operating mode (Machine, Supervisor, User)

**ixl:**  
This signal indicates the current XLEN for the given privilege mode of operation

**pc_rdata:**  
This is the address of the instruction at the trap or valid notify event

**pc_wdata:**  
This is the address of the next instruction to be executed after a trap or valid notify event

**x_addr, x_wdata, x_wb**
if x_wb is true, then an X register writeback has occured , the index is indicated by the x_addr
the value is indicated by x_wdata

**f_addr, f_wdata, f_wb**
if f_wb is true, then an F/D register writeback has occured , the index is indicated by the f_addr
the value is indicated by f_wdata

**v_addr, v_wdata, v_wb**
if v_wb is true, then a V register writeback has occured , the index is indicated by the v_addr
the value is indicated by v_wdata

**csr, csr_wb**
if the bit position within csr_wb is true, then a the position indicates a write into csr, eg if
csr_wb=0x1, then the ustatus register (address 0x000) has been written
if csr_wb=(1<<4 | 1<<0) then address 0x004 and 0x001 have been written concurrently
csr_wb=0x0 indicates no written csr.

interface RVVI_VLG #(
    parameter int ILEN  = 32,
    parameter int XLEN  = 32,
    parameter int FLEN  = 32,
    parameter int VLEN  = 256,
    parameter int NHART = 1,
    parameter int NRET  = 1
);

    //
    // RISCV output signals
    //
    event             notify;                                       // event notification for interrogation

    wire              valid            [(NHART-1):0][(NRET-1):0];   // Retired instruction
    wire [(XLEN-1):0] order            [(NHART-1):0][(NRET-1):0];   // Unique instruction order count (no gaps or reuse)
    wire [(ILEN-1):0] insn             [(NHART-1):0][(NRET-1):0];   // Instruction bit pattern
    wire              trap             [(NHART-1):0][(NRET-1):0];   // Trapped instruction
    wire              halt             [(NHART-1):0][(NRET-1):0];   // Halted  instruction
    wire              intr             [(NHART-1):0][(NRET-1):0];   // (RVFI Legacy) Flag first instruction of trap handler
    wire [1:0]        mode             [(NHART-1):0][(NRET-1):0];   // Privilege mode of operation
    wire [1:0]        ixl              [(NHART-1):0][(NRET-1):0];   // XLEN mode 32/64 bit

    wire [(XLEN-1):0] pc_rdata         [(NHART-1):0][(NRET-1):0];   // PC of insn
    wire [(XLEN-1):0] pc_wdata         [(NHART-1):0][(NRET-1):0];   // PC of next instruction

    // X Registers
    wire [4:0]        x_addr           [(NHART-1):0][(NRET-1):0];   // X register index
    wire [(XLEN-1):0] x_wdata          [(NHART-1):0][(NRET-1):0];   // X data value
    wire              x_wb             [(NHART-1):0][(NRET-1):0];   // X data writeback enable

    // F Registers                    
    wire [4:0]        f_addr           [(NHART-1):0][(NRET-1):0];   // F register index
    wire [(FLEN-1):0] f_wdata          [(NHART-1):0][(NRET-1):0];   // F data value
    wire              f_wb             [(NHART-1):0][(NRET-1):0];   // F data writeback enable

    // V Registers                    
    wire [4:0]        v_addr           [(NHART-1):0][(NRET-1):0];   // V register index
    wire [(VLEN-1):0] v_wdata          [(NHART-1):0][(NRET-1):0];   // V data value
    wire              v_wb             [(NHART-1):0][(NRET-1):0];   // V data writeback enable

    // Control & State Registers
    wire [4095:0][(XLEN-1):0]  csr     [(NHART-1):0][(NRET-1):0];   // Full CSR Address range
    wire [4095:0]              csr_wb  [(NHART-1):0][(NRET-1):0];   // CSR writeback (change) flag

    // Signals Reset & Interrupts 
    wire [63:0]       pin_mip          [(NHART-1):0][(NRET-1):0];   // Interrupts

endinterface
