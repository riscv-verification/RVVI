#
# Copyright (c) 2005-2024 Imperas Software Ltd., www.imperas.com
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.
#

import argparse
import sys


class CheckState(object):
    ilen            = 0
    xlen            = 0
    flen            = 0
    vlen            = 0
    nharts          = 0
    nretire         = 0
    order           = []
    hart            = 0
    retire_slot     = 0
    retire_auto_inc = False

def _strip_comments(tokens):
    out = []
    in_comment = False
    for t in tokens:
        if t.startswith("'"):
            in_comment = True
        if not in_comment:
            out.append(t)
        if t.endswith("'"):
            in_comment = False
    return out

def check_STRING(token):
    if not token[0].isalpha():
        raise AssertionError(f"Token '{token}' is not a valid string (must start with an alphabetic character).")
    for c in token:
        if c.isalnum() or c == '_':
            continue
        raise AssertionError(f"Token '{token}' is not a valid string (must contain only alphanumeric characters or underscores).")
    return token

def check_INT(token):
    try:
        return int(token)
    except ValueError:
        raise AssertionError(f"Token '{token}' is not a valid integer.")

def check_HEX(token):
    try:
        return int(token, 16)
    except ValueError:
        raise AssertionError(f"Token '{token}' is not a valid hexadecimal number.")

def check_VENDOR(state, tokens):
    check_STRING(tokens[1])    # vendor name
    check_INT   (tokens[2])    # major version
    check_INT   (tokens[3])    # minor version
    return tokens[4:]

def check_VERSION(state, tokens):
    check_INT   (tokens[1])    # major version
    check_INT   (tokens[2])    # minor version
    return tokens[3:]

def check_PARAMS(state, tokens):

    count = check_INT(tokens[1])
    tokens = tokens[2:]

    for i in range(count):

        key = check_STRING(tokens[0])

        try:
            value = tokens[1]
        except IndexError:
            raise AssertionError(f"Not enough tokens for PARAMS key '{key}'.")

        tokens = tokens[2:]

        if key == 'ILEN':
            state.ilen = check_INT(value)
        elif key == 'XLEN':
            state.xlen = check_INT(value)
        elif key == 'FLEN':
            state.flen = check_INT(value)
        elif key == 'VLEN':
            state.vlen = check_INT(value)
        elif key == 'NHART':
            state.nharts = check_INT(value)
        elif key == 'RETIRE':
            state.nretire = check_INT(value)
        else:
            raise AssertionError(f"Unknown PARAMS key '{key}' encountered.")

    if state.ilen not in [ 32 ]:
        raise AssertionError(f"ILEN must be 32, got {state.ilen}.")
    if state.xlen not in [ 32, 64 ]:
        raise AssertionError(f"XLEN must be 32 or 64, got {state.xlen}.")
    if state.flen not in [ 0, 32, 64, 128 ]:
        raise AssertionError(f"FLEN must be 0, 32, 64, or 128 got {state.flen}.")
    if state.nharts <= 0:
        raise AssertionError(f"NHARTS must be a positive integer, got {state.nharts}.")
    if state.nretire <= 0:
        raise AssertionError(f"NRETIRE must be a positive integer, got {state.nretire}.")

    # now we can init the order array
    state.order = [0] * state.nharts

    return tokens[7:]

def check_HART(state, tokens):
    state.hart = check_INT(tokens[1])

    if state.hart >= state.nharts:
        raise AssertionError(f"HART ID {state.hart} exceeds maximum HARTS ({state.nharts}).")

    state.retire_slot = 0;
    state.retire_auto_inc = False;

    return tokens[2:]

def check_ISSUE(state, tokens):
    issue = check_INT(tokens[1])

    state.retire_slot = issue;
    state.retire_auto_inc = False;

    return tokens[2:]

def check_ORDER(state, tokens):
    order = check_INT(tokens[1])

    state.order[ state.hart ] = order;

    # todo: check order is monotonically increasing...

    return tokens[2:]

def retire_slot_auto_increment(state):
    if state.retire_auto_inc:
        state.retire_slot += 1
    state.retire_auto_inc = True

def retire_slot_validate(state):
    if state.retire_slot >= state.nretire:
        raise AssertionError(f"Exceeded maximum retire slots ({state.nretire}).")

def order_auto_increment(state):
    try:
        state.order[state.hart] += 1
    except IndexError:
        raise AssertionError(f"HART ID {state.hart} exceeds maximum HARTS ({state.nharts}).")

def check_RET(state, tokens):

    # apply auto pre-increment rules for retire slot
    retire_slot_auto_increment(state)

    # check if the retire slot exceeds the maximum allowed after increment
    retire_slot_validate(state)

    pc = check_HEX(tokens[1])
    if pc >= (1 << state.xlen):
        raise AssertionError(f"PC value {pc:#x} exceeds XLEN limit ({state.xlen} bits).")

    inst_bin = check_HEX(tokens[2])
    if (inst_bin >= (1 << state.ilen)):
        raise AssertionError(f"Instruction binary value {inst_bin:#x} exceeds ILEN limit ({state.ilen} bits).")

    # apply auto increment rules for order
    order_auto_increment(state)

    return tokens[3:]

def check_TRAP(state, tokens):

    # apply auto pre-increment rules for retire slot
    retire_slot_auto_increment(state)

    # check if the retire slot exceeds the maximum allowed after increment
    retire_slot_validate(state)

    pc = check_HEX(tokens[1])
    if pc >= (1 << state.xlen):
        raise AssertionError(f"PC value {pc:#x} exceeds XLEN limit ({state.xlen} bits).")

    inst_bin = check_HEX(tokens[2])
    if (inst_bin >= (1 << state.ilen)):
        raise AssertionError(f"Instruction binary value {inst_bin:#x} exceeds ILEN limit ({state.ilen} bits).")

    # apply auto increment rules for order
    order_auto_increment(state)

    return tokens[3:]

def check_X(state, tokens):
    index = check_INT(tokens[1])
    if index >= 32:
        raise AssertionError(f"X register index {index} out of range (must be less than 32).")

    value = check_HEX(tokens[2])
    if value >= (1 << state.xlen):
        raise AssertionError(f"X{index} register value {value:#x} exceeds XLEN limit ({state.xlen} bits).")
    return tokens[3:]

def check_F(state, tokens):

    if (state.flen == 0):
        raise AssertionError("FLEN is 0, but F register update encountered.")

    index = check_INT(tokens[1])
    if index >= 32:
        raise AssertionError(f"F register index {index} out of range (must be less than 32).")

    value = check_HEX(tokens[2])
    if value >= (1 << state.flen):
        raise AssertionError(f"F{index} register value {value:#x} exceeds FLEN limit ({state.flen} bits).")
    return tokens[3:]

def check_V(state, tokens):

    if (state.vlen == 0):
        raise AssertionError("VLEN is 0, but V register update encountered.")

    index = check_INT(tokens[1])
    if index >= 32:
        raise AssertionError(f"Vector register index {index} out of range (must be less than 32).")

    value = check_HEX(tokens[2])   
    if value >= (1 << state.vlen):
        raise AssertionError(f"V{index} register value {value:#x} exceeds VLEN limit ({state.vlen} bits).")
    return tokens[3:]

def check_C(state, tokens):
    index = check_HEX(tokens[1])
    if index >= 0x1000:
        raise AssertionError(f"CSR index {index:#x} out of range (must be less than 0x1000).")

    value = check_HEX(tokens[2])
    if value >= (1 << state.xlen):
        raise AssertionError(f"CSR {index:#x} register value {value:#x} exceeds XLEN limit ({state.xlen} bits).")

    return tokens[3:]

def check_META(state, tokens):
    count = check_INT(tokens[1])
    return tokens[2+count:]

def check_NET(state, tokens):
    name  = check_STRING(tokens[1])
    value = check_HEX   (tokens[2])
    return tokens[3:]

def check_MODE(state, tokens):
    mode = check_HEX(tokens[1])
    if mode not in [ 0, 1, 3 ]:
        raise AssertionError(f"MODE value {mode} is invalid (must be 0, 1, or 3).")
    return tokens[2:]

def check_DM(state, tokens):
    enable = check_HEX(tokens[1])
    if enable not in [ 0, 1 ]:
        raise AssertionError(f"DM ENABLE value {enable} is invalid (must be 0 or 1).")
    return tokens[2:]

def check_line(state, tokens):
    info = {
        'VENDOR':   (check_VENDOR,  3),
        'VERSION':  (check_VERSION, 2),
        'PARAMS':   (check_PARAMS,  6),
        'HART':     (check_HART,    1),
        'ISSUE':    (check_ISSUE,   1),
        'ORDER':    (check_ORDER,   1),
        'RET':      (check_RET,     2),
        'TRAP':     (check_TRAP,    2),
        'X':        (check_X,       2),
        'F':        (check_F,       2),
        'V':        (check_V,       2),
        'C':        (check_C,       2),
        'NET':      (check_NET,     2),
        'MODE':     (check_MODE,    1),
        'DM':       (check_DM,      1),
    }

    # valid events always start with retire_slot 0
    state.retire_slot = 0
    state.retire_auto_inc = False;

    while tokens:
        key = tokens[0]
        if key not in info:
            raise AssertionError(f"Unknown token '{key}' encountered.")
        delegate, size = info[key]
        if len(tokens) < size + 1:
            raise AssertionError(f"Not enough tokens for '{key}'. Expected {size + 1}.")
        tokens = delegate(state, tokens)


def check_file(state, file):
    tokens = []
    line_num = 0

    try:
        for line in file:
            line_num  += 1
            tokens += _strip_comments( t.strip() for t in line.split() )
            if tokens:
                if tokens[-1] == '\\':
                    tokens.pop()
                    continue
                check_line(state, tokens)
            tokens = []
        if tokens:
            check_line(state, tokens)
        return True

    except AssertionError as e:
        print(f"Error on line {line_num}: {e}", file=sys.stderr)
        return False

def _parse_arguments():
    parser = argparse.ArgumentParser(description='Validate an RVVI-TEXT trace file.')
    parser.add_argument('input_file', type=str, help='Path to the input trace file')
    args = parser.parse_args()
    return args

def _main():
    args = _parse_arguments()
    try:
        with open(args.input_file, "r") as file:
            return check_file(CheckState(), file)
    except FileNotFoundError:
        print(f"Error: File '{args.input_file}' not found.", file=sys.stderr)
        exit(1)

if __name__ == "__main__":
    if _main():
        print("Trace file is valid.")
        exit(0)
    else:
        print("Trace file is invalid.", file=sys.stderr)
        exit(1)
