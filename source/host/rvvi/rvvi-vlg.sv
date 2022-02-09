/*
 * Copyright (c) 2005-2022 Imperas Software Ltd., www.imperas.com
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

import rvvi_pkg::*;

`define NUM_REGS 32
`define NUM_CSRS 4096

interface RVVI_VLG #(
    parameter int ILEN  = 32,
    parameter int XLEN  = 32,
    parameter int FLEN  = 32,
    parameter int VLEN  = 256,
    parameter int NHART = 1,
    parameter int ISSUE = 1
);
    //
    // RISCV output signals
    //
    wire                       clk;                                   // interface clock
                               
    wire                       valid    [(NHART-1):0][(ISSUE-1):0];   // Retired instruction
    wire [63:0]                order    [(NHART-1):0][(ISSUE-1):0];   // Unique instruction order count (no gaps or reuse)
    wire [(ILEN-1):0]          insn     [(NHART-1):0][(ISSUE-1):0];   // Instruction bit pattern
    wire                       trap     [(NHART-1):0][(ISSUE-1):0];   // Trapped instruction
    wire                       halt     [(NHART-1):0][(ISSUE-1):0];   // Halted  instruction
    wire                       intr     [(NHART-1):0][(ISSUE-1):0];   // (RVFI Legacy) Flag first instruction of trap handler
    wire [1:0]                 mode     [(NHART-1):0][(ISSUE-1):0];   // Privilege mode of operation
    wire [1:0]                 ixl      [(NHART-1):0][(ISSUE-1):0];   // XLEN mode 32/64 bit
                               
    wire [(XLEN-1):0]          pc_rdata [(NHART-1):0][(ISSUE-1):0];   // PC of insn
    wire [(XLEN-1):0]          pc_wdata [(NHART-1):0][(ISSUE-1):0];   // PC of next instruction
                               
    // X Registers             
    wire [31:0][(XLEN-1):0]    x_wdata  [(NHART-1):0][(ISSUE-1):0];   // X data value
    wire [31:0]                x_wb     [(NHART-1):0][(ISSUE-1):0];   // X data writeback (change) flag
                               
    // F Registers                     
    wire [31:0][(FLEN-1):0]    f_wdata  [(NHART-1):0][(ISSUE-1):0];   // F data value
    wire [31:0]                f_wb     [(NHART-1):0][(ISSUE-1):0];   // F data writeback (change) flag
                               
    // V Registers                     
    wire [31:0][(VLEN-1):0]    v_wdata  [(NHART-1):0][(ISSUE-1):0];   // V data value
    wire [31:0]                v_wb     [(NHART-1):0][(ISSUE-1):0];   // V data writeback (change) flag

    // Control & State Registers
    wire [4095:0][(XLEN-1):0]  csr      [(NHART-1):0][(ISSUE-1):0];   // Full CSR Address range
    wire [4095:0]              csr_wb   [(NHART-1):0][(ISSUE-1):0];   // CSR writeback (change) flag
    
    //
    // Synchronization of NETs and REGs
    //
    wire                       clk1;                                  // SIG clock
    wire                       clkSIGData;                            // SIG clock
    wire                       clkREGData;                            // REG clock
    assign #1 clk1       = clk;
    assign #2 clkSIGData = clk;
    assign #3 clkREGData = clk;
    
    
    // NET functions
    string name[$];
    int    value[$];
    
    function automatic void net_push(input string vname, input int vvalue);
        //$display("%m net_push %0s %0d", vname, vvalue);
        name.push_front(vname);
        value.push_front(vvalue);
    endfunction
    
    function automatic int net_pop(output string vname, output int vvalue);
        int  ok;
        string msg;
        if (name.size() > 0) begin
            vname  = name.pop_back();
            vvalue = value.pop_back();
            //$display("%m net_pop 1 %0s %0d", vname, vvalue);
            //msg = $sformatf("%m %0s %0d", vname, vvalue);
            //rvvi_pkg::info(msg);
            ok = 1;
        end else begin
            ok = 0;
        end
        return ok;
    endfunction
    
endinterface

