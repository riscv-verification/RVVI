# RVVI RISC-V Verification Interface
====================================


RVVI Specification
------------------
The following specification defines a method of controlling and observing a RISCV implementation, in
order to be observe internal state values, control the execution of instructions and apply input
events such as interrupts and debug requests.

The RVVI implements 2 interfaces 
RVVI_state   - RISC-V Verification Interface - State
RVVI_control - RISC-V Verification Interface - Control


RVVI_state Interface
--------------------
This interface provides internal visibility of the state of the RISC-V device.
It also provides a notifier event to indicate a change of state, following a control command
provided on the RVVI_control interface.
All signals on the RVVI_state Interface are outputs from the device, for observing state transitions
and state values

notify:
This is an event to indicate some change of state following the completion of a command on the
control interface. When the notify event is asserted the signals nret, valid, trap and halt indicate
the current state at this notification event point.
Following a notify event, the testbench can decide the next control command to be applied

valid:
When this signal is true at a notify event, an instruction has been successfully retired by the
device, and all internal state values will have been updated accordingly, this includes the 
Integer/GPR, Float/FPR, CSR and any other supported registers. 
The instruction address retired is indicated by the pc variable

trap:
When this signal is true at a notify event, an instruction execution has undergone an exception for
some reason, this could include synchronous/asynchronous exception, or a debug request.
This event allows the reading of internal state, but also gives the opportunity to change the values
on input signals, prior to continuing to an instruction retirement.
The instruction address trapped  is indicated by the pc variable

halt:
When this signal is true at a notify event, it indicates that the hart has gone into a halted state

intr:
When this signal is true at a notify event, it indicates that this retired instruction is the first
instruction which is part of a trap handler.

order:
This signal contains the instruction count for the instruction being retired at the valid event

insn:
This signal contains the instruction word which is at the trap or valid event

isize:
The size of the instruction held in insn, this should be either 2(compressed) or 4(uncompressed) 

mode:
This signal indicates the operating mode (Machine, Supervisor, User)

ixl:
This signal indicates the current XLEN for the given privilege mode of operation

decode:
This is a string containing the disassembled instruction at the time either the trap or valid notify
event occured.

pc:
This is the address of the retired instruction at a valid notify event

pcnext:
This is the address of the next instruction to be executed at a valid notify event

x, f, csr:
These arrays contain the values of the registers for the INTEGER, FLOATING-POINT, and CONTROL/STATE
The state values are updated at the notify events for trap and valid.


RVVI_control Interface
----------------------
This interface provides the testbench with a set of commands and status to indicate the progress
The interface contains functions similar to a debugger control for 
- stepi
- cont
- stop
the run control status is indicated by a state veriable, state changes are notified by an event 
notify

The control state variable is called cmd, indicating the current command in operation, this can be
one of 
IDLE, STEPI, STOP, CONT
additionally the control interface contains methods to step and run the device, for example

stepi():
Run the device until either an instruction provides a notify event of a trap or is valid, internally
the interface will set the cmd state back to IDLE when either trap or valid occurs.


In order to control the interface the following flow would be a simple use model

    typedef enum {INIT, IDLE, STEP, VALID, TRAP, HALT, DONE} state_e; 
    state_e state = INIT;
    initial state <= IDLE; // force an event on state to sensitize always @(*)
    always @(*) begin
      case (state)
        IDLE: begin
          state <= STEP;
        end
        
        STEP: begin                 // wait on retire, trap or halt
          cpu.control.stepi();      // call the method to step the device
          fork
            begin
              @cpu.state.valid;
              state <= VALID;
            end
            begin
              @cpu.state.trap;
              state <= TRAP;
            end
            begin
              @cpu.state.halt;
              state <= HALT;
            end
          join_any
          disable fork;
        end
        
        VALID: begin
          $display("Instruction has retired");
          state <= DONE;
        end
        
        TRAP: begin
          $display("Instruction has trapped");
          state <= STEP;
        end
        
        HALT: begin
          $display("Device has halted");
          state <= STEP;
        end
        
        DONE: begin
          $display("Report state");
          // cpu.state.x[] - Integer Registers
          state <= IDLE;
        end
    end


RVVI within a testbench
-----------------------
When using a testbench to run/compare 2 targets the state/control can be used to carefully control
the execution to ensure the state compares match for all instructions producing either a valid or
trap result

    typedef enum {
        INIT,
        IDLE,  // Needed to get an event on state so always block 
               // is initially entered
        
        RTL_STEP,
        RTL_VALID,
        RTL_TRAP,
        RTL_HALT,
        
        RM_STEP,
        RM_VALID,
        RM_TRAP,
        RM_HALT,
        
        CMP
    } state_e; 
    
    state_e state = INIT;
    initial state <= IDLE; // cause an event for always @*
    
    always @(*) begin
       case (state)
         IDLE: begin
             state <= RTL_STEP;
         end
         
         RTL_STEP: begin
             clknrst_if.start_clk();
             fork
                 begin
                     @step_compare_if.riscv_retire;
                     clknrst_if.stop_clk();
                     step_rtl <= 0;
                     state <= RTL_VALID;
                 end
                 begin
                     @step_compare_if.riscv_trap;
                     state <= RTL_TRAP;
                 end
                 begin
                     @step_compare_if.riscv_halt;
                     state <= RTL_HALT;
                 end
             join_any
             disable fork;
         end
    
         RTL_VALID: begin
             state <= RM_STEP;
         end
         
         RTL_TRAP: begin
             //state <= RM_STEP; // TODO: RTL/RVVI needs additional work
             state <= RTL_STEP;
         end
         
         RTL_HALT: begin
             state <= RTL_STEP;
         end
    
         RM_STEP: begin
             pushRTL2RM("ret_rtl");
             `CV32E40P_OVP_RVCTL.stepi();
             fork
                 begin
                     @step_compare_if.ovp_cpu_valid;
                     ->`CV32E40P_TRACER.ovp_retire;
                     state <= RM_VALID;
                 end
                 begin
                     @step_compare_if.ovp_cpu_trap;
                     state <= RM_TRAP;
                 end
                 begin
                     @step_compare_if.ovp_cpu_halt;
                     state <= RM_HALT;
                 end
             join_any
             disable fork;
         end
    
         RM_VALID: begin
             state <= CMP;
         end
         
         RM_TRAP: begin
             //state <= CMP; // TODO: needs enabling after RTL/RVVI fix
             state <= RM_STEP;
         end
         
         RM_HALT: begin
             state <= RM_STEP;
         end
    
         CMP: begin 
              compare();
              step_rtl <= 1;
              ->ev_compare;
              instruction_count += 1;           
              //state <= RTL_STEP;
              state <= IDLE;
         end
       endcase // case (state)
    end
 


