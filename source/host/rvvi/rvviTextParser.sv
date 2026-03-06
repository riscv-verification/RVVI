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

`default_nettype none

`ifndef VLEN
`define VLEN 512
`endif

`define FMT_DEC "%d"
`define FMT_HEX "0x%h"

module top();

  string  traceFilePath;
  integer traceFileHandle;
  logic   clk;
  string  line;

  longint pc_rdata;
  longint insn;
  longint order;
  integer hart;
  bit     valid;
  string  vendor;
  longint cycle_acc;
  longint time_acc;

  integer retire;
  bit     retireAutoInc;

  //---------------------------------------------------------------------------
  // SETUP LOGIC
  //---------------------------------------------------------------------------

  initial begin

    if (!$value$plusargs("traceFile=%s", traceFilePath)) begin
      $display("Error: +traceFile not specified");
      $fatal;
    end
    traceFileHandle = $fopen(traceFilePath, "r");
    if (traceFileHandle == 0) begin
      $display("Error: unable to open trace file '%s'", traceFilePath);
      $fatal;
    end

    $display("----------------------------------------------------------------");
    $display("START");
    $display("----------------------------------------------------------------");
  end

  //---------------------------------------------------------------------------
  // MAIN TRACE PROCESSING LOOP
  //---------------------------------------------------------------------------

  initial begin
    clk = 0;
    forever #1 clk = !clk;
  end

  always @(posedge clk) begin
    integer res;        // task result
    string  tokens[$];  // token list
    string  key;        // element key
    string  net;        // net name
    longint valueInt;   // parsed integer value
    integer valueIndex; // parsed integer index
    string  valueStr;   // parsed string value
    logic   [`VLEN-1:0] valueVr;
    bit     done;

    int     memBytes;
    longint memPAddr;
    longint memVAddr;

    tokens.delete();
    res = $fgets(line, traceFileHandle);
    tokenize(line, tokens);

    valid = 0;  // deassert valid until we find a RET or TRAP entry

    // reset the initial retirement slot
    retire = 0;
    retireAutoInc = 0;

    done = 0;
    while (!done) begin
      done = 1;  // expect only one line by default

      if ($feof(traceFileHandle)) begin
        $display("----------------------------------------------------------------");
        $display("END");
        $display("----------------------------------------------------------------");
        $fclose(traceFileHandle);
        $finish;
      end

      while (tokens.size()) begin

        key = tokens.pop_front();
        case (key)
        "VENDOR": begin
          valueStr = tokens.pop_front();  // vendor
          $display("VENDOR %s", valueStr);
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueInt);  // major
          $display("MAJOR %1d", valueInt);
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueInt);  // minor
          $display("MINOR %1d", valueInt);
        end
        "VERSION": begin
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueInt);  // major
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueInt);  // minor
        end
        "PARAMS": begin
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueInt);  // count
          while (valueInt--) begin
            checkParam(tokens.pop_front(), tokens.pop_front());
          end
        end
        "ORDER": begin
          res = $sscanf(tokens.pop_front(), `FMT_DEC, order);
          $display("ORDER %1d", order);
        end
        "ISSUE": begin
          res = $sscanf(tokens.pop_front(), `FMT_DEC, retire);

          // if RETIRE slot is manually specified we inhibit the auto increment
          retireAutoInc = 0;
        end
        "HART": begin
          res = $sscanf(tokens.pop_front(), `FMT_DEC, hart);
          $display("HART %1d", hart);

          // when changing harts we reset the RETIRE slot
          retire = 0;
          retireAutoInc = 0;
        end
        "RET": begin
          res = $sscanf(tokens.pop_front(), `FMT_HEX, pc_rdata);
          res = $sscanf(tokens.pop_front(), `FMT_HEX, insn);

          // pre-increment the retirement slot as needed
          retire += retireAutoInc ? 1 : 0;
          retireAutoInc = 1;
          $display("ISSUE %1d", retire);

          // mark that we now have a valid event
          valid = 1;
          $display("RET 0x%1h 0x%1h", pc_rdata, insn);

          // post-increment the order field
          $display("ORDER %1d", order);
          order++;
        end
        "TRAP": begin
          res = $sscanf(tokens.pop_front(), `FMT_HEX, pc_rdata);
          res = $sscanf(tokens.pop_front(), `FMT_HEX, insn);

          retire += retireAutoInc ? 1 : 0;
          retireAutoInc = 1;
          $display("ISSUE %1d", retire);

          valid = 1;
          $display("TRAP 0x%1h 0x%1h", pc_rdata, insn);

          $display("ORDER %1d", order);
          order++;
        end
        "X": begin
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueIndex);
          res = $sscanf(tokens.pop_front(), `FMT_HEX, valueInt);
          $display("X %1d 0x%1h", valueIndex, valueInt);
        end
        "F": begin
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueIndex);
          res = $sscanf(tokens.pop_front(), `FMT_HEX, valueInt);
          $display("F %1d 0x%1h", valueIndex, valueInt);
        end
        "C": begin
          res = $sscanf(tokens.pop_front(), `FMT_HEX, valueIndex);
          res = $sscanf(tokens.pop_front(), `FMT_HEX, valueInt);
          $display("C 0x%1h 0x%1h", valueIndex, valueInt);
        end
        "V": begin
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueIndex);
          res = $sscanf(tokens.pop_front(), `FMT_HEX, valueVr);
          $display("V %1d 0x%1h", valueIndex, valueVr);
        end
        "NET": begin
          net = tokens.pop_front();
          res = $sscanf(tokens.pop_front(), `FMT_HEX, valueInt);
          $display("NET %s 0x%1h", net, valueInt);
        end
        "MODE": begin
          res = $sscanf(tokens.pop_front(), `FMT_HEX, valueInt);
          $display("MODE 0x%1h", valueInt);
        end
        "VIRT": begin
          res = $sscanf(tokens.pop_front(), `FMT_HEX, valueInt);
          $display("VIRT 0x%1h", valueInt);
        end
        "DM": begin
          res = $sscanf(tokens.pop_front(), `FMT_HEX, valueInt);
          $display("DM 0x%1h", valueInt);
        end
        "META": begin
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueInt);
          while (valueInt--) begin
            tokens.pop_front();
          end
        end
        "CYCLE": begin
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueInt);
          cycle_acc += valueInt;
          $display("CYCLE %0d (%0d)", valueInt, cycle_acc);
        end
        "TIME": begin
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueInt);
          time_acc += valueInt;
          $display("TIME %0d (%0d)", valueInt, time_acc);
        end
        "MEM": begin
          valueStr = tokens.pop_front();                          // bus
          res = $sscanf(tokens.pop_front(), `FMT_DEC, memBytes);  // bytes
          res = $sscanf(tokens.pop_front(), `FMT_HEX, memVAddr);  // vaddr
          res = $sscanf(tokens.pop_front(), `FMT_HEX, memPAddr);  // paddr
          res = $sscanf(tokens.pop_front(), `FMT_DEC, valueInt);  // count
          $display("MEM %s %d %0x %0x %d", valueStr, memBytes, memVAddr, memPAddr, valueInt);
          while (valueInt--) begin
            key      = tokens.pop_front();                        // key
            valueStr = tokens.pop_front();                        // value
            $display("%s %s", key, valueStr);
          end
        end
        "STATE": begin
          key = tokens.pop_front();                               // key
          valueStr = tokens.pop_front();                          // value
          $display("STATE %s %s", key, valueStr);
        end
        "\\": begin
          done = 0;
          if (tokens.size() > 0) begin
            $display("Warning: unexpected tokens after '\\' in trace file");
            $fatal;
          end
        end
        default: begin
          $display("Error: Unknown entry '%s' in trace file", key);
          $fatal;
        end
        endcase
      end
    end

    if (valid) begin
      $display(".");
    end
  end

  //---------------------------------------------------------------------------
  // TRACE FILE TOKENIZER
  //---------------------------------------------------------------------------

  function automatic checkParam(string key, string value);
    $display("PARAM %s: %s", key, value);
  endfunction

  function automatic isWhitespace(string ch);
    return ch[0] <= 32;  // space and non-printable characters
  endfunction

  function automatic tokenize(string line, ref string tokens[$]);

    string token;
    int length = line.len();
    int j = 0, i = 0;
    byte ch = 0;
    bit inComment = 0;
    bit inString = 0;

    while (i < length) begin

      ch = line[i];
      i++;

      // leaving a comment
      if (ch == "'" && inComment) begin
        inComment = !inComment;
        j = i;
        continue;
      end
      // entering a comment
      if (ch == "'" && !inComment) begin
        inComment = !inComment;
        if ((i-j) > 1) begin
          tokens.push_back(token);
          token = "";
        end
      end
      // inside a comment
      if (inComment) begin
        continue;
      end

      // leaving a string
      if (ch == "\"" && inString) begin
        inString = !inString;
        j = i;
        tokens.push_back(token);
        token = "";
        continue;
      end
      // entering a string
      if (ch =="\"" && !inString) begin
        inString = !inString;
        if ((i-j) > 1) begin
          tokens.push_back(token);
          token = "";
        end
        continue;
      end

      if (inString || !isWhitespace(ch)) begin
        token = {token, ch};
      end else begin
        if ((i-j) > 1) begin
          tokens.push_back(token);
          token = "";
        end
        j = i;
      end
    end

    // push remaining buffered token
    if ((i-j) > 1) begin
      tokens.push_back(token);
      token = "";
    end

  endfunction

endmodule
