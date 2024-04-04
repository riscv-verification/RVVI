/*
 * Copyright (c) 2005-2024 Imperas Software Ltd., www.imperas.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
 * either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

`define NUM_REGS 32
`define NUM_CSRS 4096

`define RVVI_TRACE_VERSION_MAJOR 1
`define RVVI_TRACE_VERSION_MINOR 5

/*
 * A single DTM (Debug Transport Module), connects
 * via the DMI (Debug Module Interface) to
 * a DM (Debug Module), which can control N harts
 *
 */
interface dm
#(
    parameter int ILEN   = 32,  // Instruction length in bits
    parameter int XLEN   = 32,  // GPR length in bits
    parameter int FLEN   = 32,  // FPR length in bits
    parameter int VLEN   = 256, // Vector register size in bits
    parameter int NHART  = 1,   // Number of harts reported
    parameter int RETIRE = 1    // Number of instructions that can retire during valid event
);
    //
    // RISCV DM signals
    //
    wire                      clk;                                      // Interface clock
    wire                      rd;                                       // read
    wire                      wr;                                       // write
    wire [31:0]               address;
    wire [31:0]               data;

    bit  [(XLEN-1):0]         store      [127:0];                       // Storage for DM registers

endinterface

interface rvviTrace
#(
    parameter int ILEN   = 32,  // Instruction length in bits
    parameter int XLEN   = 32,  // GPR length in bits
    parameter int FLEN   = 32,  // FPR length in bits
    parameter int VLEN   = 256, // Vector register size in bits
    parameter int NHART  = 1,   // Number of harts reported
    parameter int RETIRE = 1    // Number of instructions that can retire during valid event
);
    //
    // RISCV output signals
    //
    wire                      clk;                                      // Interface clock
    wire                      valid      [(NHART-1):0][(RETIRE-1):0];   // Valid event
    wire [63:0]               order      [(NHART-1):0][(RETIRE-1):0];   // Unique event order count (no gaps or reuse)

    wire [(ILEN-1):0]         insn       [(NHART-1):0][(RETIRE-1):0];   // Instruction bit pattern
    wire                      trap       [(NHART-1):0][(RETIRE-1):0];   // State update without instruction retirement
    wire                      debug_mode [(NHART-1):0][(RETIRE-1):0];   // Retired instruction executed in debug mode

    // Program counter
    wire [(XLEN-1):0]         pc_rdata   [(NHART-1):0][(RETIRE-1):0];   // PC of instruction

    // X Registers
    wire [31:0][(XLEN-1):0]   x_wdata    [(NHART-1):0][(RETIRE-1):0];   // X data value
    wire [31:0]               x_wb       [(NHART-1):0][(RETIRE-1):0];   // X data writeback (change) flag

    // F Registers
    wire [31:0][(FLEN-1):0]   f_wdata    [(NHART-1):0][(RETIRE-1):0];   // F data value
    wire [31:0]               f_wb       [(NHART-1):0][(RETIRE-1):0];   // F data writeback (change) flag

    // V Registers
    wire [31:0][(VLEN-1):0]   v_wdata    [(NHART-1):0][(RETIRE-1):0];   // V data value
    wire [31:0]               v_wb       [(NHART-1):0][(RETIRE-1):0];   // V data writeback (change) flag

    // Control and Status Registers
    wire [4095:0][(XLEN-1):0] csr        [(NHART-1):0][(RETIRE-1):0];   // Full CSR Address range
    wire [4095:0]             csr_wb     [(NHART-1):0][(RETIRE-1):0];   // CSR writeback (change) flag

    // Atomic Memory Control
    wire                      lrsc_cancel[(NHART-1):0][(RETIRE-1):0];   // Implementation defined cancel

    //
    // Optional
    //
    wire [(XLEN-1):0]         pc_wdata   [(NHART-1):0][(RETIRE-1):0];   // PC of next instruction
    wire                      intr       [(NHART-1):0][(RETIRE-1):0];   // (RVFI Legacy) Flag first instruction of trap handler
    wire                      halt       [(NHART-1):0][(RETIRE-1):0];   // Halted  instruction
    wire [1:0]                ixl        [(NHART-1):0][(RETIRE-1):0];   // XLEN mode 32/64 bit
    wire [1:0]                mode       [(NHART-1):0][(RETIRE-1):0];   // Privilege mode of operation

    //
    // Optional DMI Interface
    //
    dm dm();

    //
    // Synchronization of NETs
    //
    longint vslot;
    always @(posedge clk) begin
        vslot <= vslot + 1;
    end

    string           name[$];
    longint unsigned value[$];
    longint unsigned tslot[$];
    longint unsigned nets[string];

    function automatic void net_push(input string pname, input longint unsigned pvalue);
        name.push_front(pname);
        value.push_front(pvalue);
        tslot.push_front(vslot);
    endfunction

    function automatic int net_pop(output string pname, output longint unsigned pvalue, output longint unsigned pslot);
        int  ok;
        string msg;
        if (name.size() > 0) begin
            pname       = name.pop_back();
            pvalue      = value.pop_back();
            pslot       = tslot.pop_back();
            nets[pname] = pvalue;
            ok = 1;
        end else begin
            ok = 0;
        end
        return ok;
    endfunction

endinterface
