/*
 * Copyright (c) 2005-2023 Imperas Software Ltd., www.imperas.com
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

parameter RVVI_API_VERSION = 28;
parameter RVVI_TRUE = 1;
parameter RVVI_FALSE = 0;
parameter RVVI_INVALID_INDEX = -1;
parameter RVVI_MEMORY_PRIVILEGE_READ = 1;
parameter RVVI_MEMORY_PRIVILEGE_WRITE = 2;
parameter RVVI_MEMORY_PRIVILEGE_EXEC = 4;

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
    RVVI_METRIC_CYCLES = 9
} rvviMetricE;

import "DPI-C" context function int rvviVersionCheck(
    input int version);

import "DPI-C" context function int rvviRefInit(
    input string programPath);

import "DPI-C" context function int rvviRefPcSet(
    input int hartId,
    input longint address);

import "DPI-C" context function int rvviRefShutdown();

import "DPI-C" context function int rvviRefCsrSetVolatile(
    input int hartId,
    input int csrIndex);

import "DPI-C" context function int rvviRefMemorySetVolatile(
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
    input longint dutInsBin);

import "DPI-C" context function void rvviDutTrap(
    input int hartId,
    input longint dutPc,
    input longint dutInsBin);

import "DPI-C" context function void rvviRefReservationInvalidate(
    input int hartId);

import "DPI-C" context function int rvviRefEventStep(
    input int hartId);

import "DPI-C" context function int rvviRefGprsCompare(
    input int hartId);

import "DPI-C" context function int rvviRefGprsCompareWritten(
    input int hartId,
    input int ignoreX0);

import "DPI-C" context function int rvviRefInsBinCompare(
    input int hartId);

import "DPI-C" context function int rvviRefPcCompare(
    input int hartId);

import "DPI-C" context function int rvviRefCsrCompare(
    input int hartId,
    input int csrIndex);

import "DPI-C" context function void rvviRefCsrCompareEnable(
    input int hartId,
    input int csrIndex,
    input int enableState);

import "DPI-C" context function void rvviRefCsrCompareMask(
    input int hartId,
    input int csrIndex,
    input longint mask);

import "DPI-C" context function int rvviRefCsrsCompare(
    input int hartId);

import "DPI-C" context function int rvviRefVrsCompare(
    input int hartId);

import "DPI-C" context function int rvviRefFprsCompare(
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

import "DPI-C" context function int rvviRefCsrPresent(
    input int hartId,
    input int csrIndex);

import "DPI-C" context function int rvviRefFprsPresent(
    input int hartId);

import "DPI-C" context function int rvviRefVrsPresent(
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

import "DPI-C" context function int rvviRefProgramLoad(
    input string programPath);

import "DPI-C" context function void rvviRefForceReconverge(
    input int hartId);

import "DPI-C" context function int rvviRefCsrSetVolatileMask(
    input int hartId,
    input int csrIndex,
    input longint csrMask);

import "DPI-C" context function void rvviDutCycleCountSet(
    input longint cycleCount);

import "DPI-C" context function int rvviRefConfigSetInt(
    input longint configParam,
    input longint value);

import "DPI-C" context function int rvviRefConfigSetString(
    input longint configParam,
    input string value);

import "DPI-C" context function int rvviRefCsrIndex(
    input int hartId,
    input string csrName);

import "DPI-C" context function int rvviRefMemorySetPrivilege(
    input longint addrLo,
    input longint addrHi,
    input int access);

import "DPI-C" context function void rvviRefVrSet(
    input int hartId,
    input int vrIndex,
    input int byteIndex,
    input int data);

export "DPI-C" function SVWriteC;
function void SVWriteC(input string text);
    $write(text);
endfunction

endpackage

`endif  // _RVVI_API_PKG__

