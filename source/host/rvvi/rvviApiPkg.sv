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

`ifndef _RVVI_API_PKG__
`define _RVVI_API_PKG__

package rvviApiPkg;

`ifdef UVM
import uvm_pkg::*;
`endif

parameter RVVI_API_VERSION_MAJOR = 1;
parameter RVVI_API_VERSION_MINOR = 34;
parameter RVVI_TRUE = 1;
parameter RVVI_FALSE = 0;
parameter RVVI_INVALID_INDEX = -1;
parameter RVVI_MEMORY_PRIVILEGE_READ = 1;
parameter RVVI_MEMORY_PRIVILEGE_WRITE = 2;
parameter RVVI_MEMORY_PRIVILEGE_EXEC = 4;
parameter RVVI_API_VERSION = ((RVVI_API_VERSION_MAJOR << 24) | RVVI_API_VERSION_MINOR);

typedef enum {
    RVVI_METRIC_RETIRES = 0,
    RVVI_METRIC_TRAPS = 1,
    RVVI_METRIC_MISMATCHES = 2,
    RVVI_METRIC_COMPARISONS_PC = 3,
    RVVI_METRIC_COMPARISONS_GPR = 4,
    RVVI_METRIC_COMPARISONS_FPR = 5,
    RVVI_METRIC_COMPARISONS_CSR = 6,
    RVVI_METRIC_COMPARISONS_VR = 7,
    RVVI_METRIC_COMPARISONS_INSBIN = 8,
    RVVI_METRIC_CYCLES = 9,
    RVVI_METRIC_ERRORS = 10,
    RVVI_METRIC_WARNINGS = 11,
    RVVI_METRIC_FATALS = 12
} rvviMetricE;

import "DPI-C" context function byte rvviVersionCheck(
    input int version);

import "DPI-C" context function byte rvviRefInit(
    input string programPath);

import "DPI-C" context function byte rvviRefPcSet(
    input int hartId,
    input longint address);

import "DPI-C" context function byte rvviRefShutdown();

import "DPI-C" context function byte rvviRefCsrSetVolatile(
    input int hartId,
    input int csrIndex);

import "DPI-C" context function byte rvviRefMemorySetVolatile(
    input longint addressLow,
    input longint addressHigh);

import "DPI-C" context function longint rvviRefNetIndexGet(
    input string name);

import "DPI-C" context function int rvviRefVrGet(
    input int hartId,
    input int vrIndex,
    input int byteIndex);

import "DPI-C" context function void rvviDutVrSet(
    input int hartId,
    input int vrIndex,
    input int byteIndex,
    input int data);

import "DPI-C" context function void rvviDutFprSet(
    input int hartId,
    input int fprIndex,
    input longint value);

import "DPI-C" context function void rvviDutGprSet(
    input int hartId,
    input int gprIndex,
    input longint value);

import "DPI-C" context function void rvviDutCsrSet(
    input int hartId,
    input int csrIndex,
    input longint value);

import "DPI-C" context function void rvviRefNetGroupSet(
    input longint netIndex,
    input int group);

import "DPI-C" context function void rvviRefNetSet(
    input longint netIndex,
    input longint value,
    input longint when);

import "DPI-C" context function longint rvviRefNetGet(
    input longint netIndex);

import "DPI-C" context function void rvviDutRetire(
    input int hartId,
    input longint dutPc,
    input longint dutInsBin,
    input byte debugMode);

import "DPI-C" context function void rvviDutTrap(
    input int hartId,
    input longint dutPc,
    input longint dutInsBin);

import "DPI-C" context function void rvviRefReservationInvalidate(
    input int hartId);

import "DPI-C" context function byte rvviRefEventStep(
    input int hartId);

import "DPI-C" context function byte rvviRefGprsCompare(
    input int hartId);

import "DPI-C" context function byte rvviRefGprsCompareWritten(
    input int hartId,
    input byte ignoreX0);

import "DPI-C" context function byte rvviRefInsBinCompare(
    input int hartId);

import "DPI-C" context function byte rvviRefPcCompare(
    input int hartId);

import "DPI-C" context function byte rvviRefCsrCompare(
    input int hartId,
    input int csrIndex);

import "DPI-C" context function void rvviRefCsrCompareEnable(
    input int hartId,
    input int csrIndex,
    input byte enableState);

import "DPI-C" context function void rvviRefCsrCompareMask(
    input int hartId,
    input int csrIndex,
    input longint mask);

import "DPI-C" context function byte rvviRefCsrsCompare(
    input int hartId);

import "DPI-C" context function byte rvviRefVrsCompare(
    input int hartId);

import "DPI-C" context function byte rvviRefFprsCompare(
    input int hartId);

import "DPI-C" context function void rvviRefGprSet(
    input int hartId,
    input int gprIndex,
    input longint gprValue);

import "DPI-C" context function longint rvviRefGprGet(
    input int hartId,
    input int gprIndex);

import "DPI-C" context function int rvviRefGprsWrittenGet(
    input int hartId);

import "DPI-C" context function longint rvviRefPcGet(
    input int hartId);

import "DPI-C" context function longint rvviRefCsrGet(
    input int hartId,
    input int csrIndex);

import "DPI-C" context function longint rvviRefInsBinGet(
    input int hartId);

import "DPI-C" context function void rvviRefFprSet(
    input int hartId,
    input int fprIndex,
    input longint fprValue);

import "DPI-C" context function longint rvviRefFprGet(
    input int hartId,
    input int fprIndex);

import "DPI-C" context function void rvviDutBusWrite(
    input int hartId,
    input longint address,
    input longint value,
    input longint byteEnableMask);

import "DPI-C" context function void rvviRefMemoryWrite(
    input int hartId,
    input longint address,
    input longint data,
    input int size);

import "DPI-C" context function longint rvviRefMemoryRead(
    input int hartId,
    input longint address,
    input int size);

import "DPI-C" context function string rvviDasmInsBin(
    input int hartId,
    input longint address,
    input longint insBin);

import "DPI-C" context function string rvviRefCsrName(
    input int hartId,
    input int csrIndex);

import "DPI-C" context function string rvviRefGprName(
    input int hartId,
    input int gprIndex);

import "DPI-C" context function byte rvviRefCsrPresent(
    input int hartId,
    input int csrIndex);

import "DPI-C" context function byte rvviRefFprsPresent(
    input int hartId);

import "DPI-C" context function byte rvviRefVrsPresent(
    input int hartId);

import "DPI-C" context function string rvviRefFprName(
    input int hartId,
    input int fprIndex);

import "DPI-C" context function string rvviRefVrName(
    input int hartId,
    input int vrIndex);

import "DPI-C" context function string rvviErrorGet();

import "DPI-C" context function longint rvviRefMetricGet(
    input rvviMetricE metric);

import "DPI-C" context function void rvviRefCsrSet(
    input int hartId,
    input int csrIndex,
    input longint value);

import "DPI-C" context function void rvviRefStateDump(
    input int hartId);

import "DPI-C" context function byte rvviRefProgramLoad(
    input string programPath);

import "DPI-C" context function byte rvviRefCsrSetVolatileMask(
    input int hartId,
    input int csrIndex,
    input longint csrMask);

import "DPI-C" context function void rvviDutCycleCountSet(
    input longint cycleCount);

import "DPI-C" context function byte rvviRefConfigSetInt(
    input longint configParam,
    input longint value);

import "DPI-C" context function byte rvviRefConfigSetString(
    input longint configParam,
    input string value);

import "DPI-C" context function int rvviRefCsrIndex(
    input int hartId,
    input string csrName);

import "DPI-C" context function byte rvviRefMemorySetPrivilege(
    input longint addrLo,
    input longint addrHi,
    input int access);

import "DPI-C" context function void rvviRefVrSet(
    input int hartId,
    input int vrIndex,
    input int byteIndex,
    input int data);

import "DPI-C" context function void setContextExtMemory(input string func);

endpackage: rvviApiPkg

`endif  // _RVVI_API_PKG__

