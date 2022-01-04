/*
 *
 * Copyright (c) 2005-2022 Imperas Software Ltd., www.imperas.com
 *
 * The contents of this file are provided under the Software License
 * Agreement that you accepted before downloading this file.
 *
 * This source forms part of the Software and can be used for educational,
 * training, and demonstration purposes but cannot be used for derivative
 * works except in cases where the derivative works require OVP technology
 * to run.
 *
 * For open source models released under licenses that you can use for
 * derivative works, please visit www.OVPworld.org or www.imperas.com
 * for the location of the open source models.
 *
 */

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

    // Signals Reset & Interrupts - TBD

endinterface

