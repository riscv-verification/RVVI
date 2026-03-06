/*
 * Copyright (c) 2024-2026 Synopsys, Inc. All rights reserved.
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
`define RVVI_TRACE_VERSION_MINOR 7

`include "rvviTraceTypes.svh"

/*
 * A single DTM (Debug Transport Module), connects
 * via the DMI (Debug Module Interface) to
 * a DM (Debug Module), which can control N harts
 *
 */
interface dm
#(
    parameter int ILEN    = 32,  // Instruction length in bits
    parameter int XLEN    = 32,  // GPR length in bits
    parameter int FLEN    = 32,  // FPR length in bits
    parameter int VLEN    = 256, // Vector register size in bits
    parameter int NHART   = 1,   // Number of harts reported
    parameter int RETIRE  = 1    // Number of instructions that can retire during valid event
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
    parameter int ILEN        = 32,   // Instruction length in bits
    parameter int XLEN        = 32,   // GPR length in bits
    parameter int FLEN        = 32,   // FPR length in bits
    parameter int VLEN        = 256,  // Vector register size in bits
    parameter int NHART       = 1,    // Number of harts reported
    parameter int RETIRE      = 1,    // Number of instructions that can retire during valid event    
    parameter int CLIENTS_MAX = 5     // number of RVVI clients
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
    // Optional sideband state
    //

    string state[(NHART-1):0][string];

    //
    // Optional
    //
    wire [(XLEN-1):0]         pc_wdata   [(NHART-1):0][(RETIRE-1):0];   // PC of next instruction
    wire                      intr       [(NHART-1):0][(RETIRE-1):0];   // (RVFI Legacy) Flag first instruction of trap handler
    wire                      halt       [(NHART-1):0][(RETIRE-1):0];   // Halted  instruction
    wire [1:0]                ixl        [(NHART-1):0][(RETIRE-1):0];   // XLEN mode 32/64 bit
    wire [1:0]                mode       [(NHART-1):0][(RETIRE-1):0];   // Privilege mode of operation
    wire                      mode_virt  [(NHART-1):0][(RETIRE-1):0];   // Virtual mode

    //
    // Optional DMI Interface
    //
    dm dm();

    //
    // Optional memory interface
    //

    rvvi_mem_access_t mem_accesses[CLIENTS_MAX][(NHART-1):0][$];

    //
    // Synchronization of NETs
    //

    longint vslot;
    always @(posedge clk) begin
        vslot <= vslot + 1;
    end

    string           name [CLIENTS_MAX][$];
    longint unsigned value[CLIENTS_MAX][$];
    longint unsigned tslot[CLIENTS_MAX][$];
    longint unsigned nets [CLIENTS_MAX][string];

    //
    // rvvi-trace clients
    //

    int client_id_next = 0;
    logic client_recv_nets  [CLIENTS_MAX];
    logic client_recv_memory[CLIENTS_MAX];

    function automatic int client_register(logic recv_nets, logic recv_memory);

        // reserve new client slot ID
        int out;
        out = client_id_next;
        if (client_id_next >= CLIENTS_MAX) begin
            $fatal(1, "%m: Maximum RVVI-TRACE client count reached");
        end
        ++client_id_next;

        // set observer state
        client_recv_nets  [out] = recv_nets;
        client_recv_memory[out] = recv_memory;

        return out;
    endfunction

    function automatic void net_push(input string pname, input longint unsigned pvalue);
        // push net change to all clients queues
        int i;
        for (i=0; i<client_id_next; ++i) begin
            if (client_recv_nets[i]) begin
                name [i].push_front(pname);
                value[i].push_front(pvalue);
                tslot[i].push_front(vslot);
            end
        end
    endfunction

    function automatic int net_pop(input int client, output string pname, output longint unsigned pvalue, output longint unsigned pslot);
        int    ok;
        string msg;
        if (name[client].size() > 0) begin
            pname       = name [client].pop_back();     // net name
            pvalue      = value[client].pop_back();     // net value
            pslot       = tslot[client].pop_back();     // net slot
            nets[client][pname] = pvalue;               // save current 'popped' net state
            ok = 1;                                     // success
        end else begin
            ok = 0;                                     // empty
        end
        return ok;
    endfunction

    function automatic void mem_access_push(int hart, input rvvi_mem_access_t access);
        int i;
        for (i=0; i<client_id_next; ++i) begin
            if (client_recv_memory[i]) begin
                mem_accesses[i][hart].push_front(access);
            end
        end
    endfunction

    function automatic int mem_access_pop(input int client, int hart, output rvvi_mem_access_t access);
        if (mem_accesses[client][hart].size() == 0) begin
            return 0;  // empty
        end
        access = mem_accesses[client][hart].pop_back();
        return 1;  // ok
    endfunction

endinterface
