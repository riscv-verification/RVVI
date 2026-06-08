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

`ifndef _RVVI_TRACE_TYPES__
`define _RVVI_TRACE_TYPES__

typedef struct packed {
    logic            fetch;           // 1 (fetch access) 0 (data access)
    longint unsigned size;            // access size in bytes
    longint unsigned vaddr;           // virtual address
    longint unsigned paddr;           // physical address
    longint unsigned gaddr;           // guest address
    longint unsigned pte;             // page table entry (VS-stage when Hypervisor is active)
    longint unsigned gpte;            // page table entry (G-stage when Hypervisor is active)
    logic [2:0]      page_type;       // 0b000 (kilo) 0b001 (mega) 0b010 (giga) 0b011 (tera) 0b100 (peta)
    logic [2:0]      guest_page_type; // 0b000 (kilo) 0b001 (mega) 0b010 (giga) 0b011 (tera) 0b100 (peta)
} rvvi_mem_access_t;

`endif  // _RVVI_TRACE_TYPES__
