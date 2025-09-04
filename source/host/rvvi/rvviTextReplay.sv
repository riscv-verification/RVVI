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

module top();

  string  traceFilePath;
  integer traceFileHandle;
  logic   clk;
  string  line;

  longint pc_rdata;
  longint insn;
  longint order;
  integer hart;
  integer index;
  longint value;
  bit     valid;
  logic   [`VLEN-1:0] valueVr;
  string  vendor;

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
    bit     done;

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
          vendor = tokens.pop_front();
          res = $sscanf(tokens.pop_front(), "%d", value);  // major
          res = $sscanf(tokens.pop_front(), "%d", value);  // minor
        end
        "VERSION": begin
          res = $sscanf(tokens.pop_front(), "%d", value);  // major
          res = $sscanf(tokens.pop_front(), "%d", value);  // minor
        end
        "PARAMS": begin
          res = $sscanf(tokens.pop_front(), "%d", value);  // count
          while (value--) begin
            checkParam(tokens.pop_front(), tokens.pop_front());
          end
        end
        "ORDER": begin
          res = $sscanf(tokens.pop_front(), "%d", order);
          $display("ORDER %1d", order);
        end
        "ISSUE": begin
          res = $sscanf(tokens.pop_front(), "%d", retire);

          // if RETIRE slot is manually specified we inhibit the auto increment
          retireAutoInc = 0;
        end
        "HART": begin
          res = $sscanf(tokens.pop_front(), "%d", hart);
          $display("HART %1d", hart);

          // when changing harts we reset the RETIRE slot
          retire = 0;
          retireAutoInc = 0;
        end
        "RET": begin
          res = $sscanf(tokens.pop_front(), "%h", pc_rdata);
          res = $sscanf(tokens.pop_front(), "%h", insn);

          // pre-increment the retirement slot as needed
          retire += retireAutoInc ? 1 : 0;
          retireAutoInc = 1;
          $display("ISSUE %1d", retire);

          // mark that we now have a valid event
          valid = 1;
          $display("RET %h %h", pc_rdata, insn);

          // post-increment the order field
          $display("ORDER %1d", order);
          order++;
        end
        "TRAP": begin
          res = $sscanf(tokens.pop_front(), "%h", pc_rdata);
          res = $sscanf(tokens.pop_front(), "%h", insn);

          retire += retireAutoInc ? 1 : 0;
          retireAutoInc = 1;
          $display("ISSUE %1d", retire);

          valid = 1;
          $display("TRAP %h %h", pc_rdata, insn);

          $display("ORDER %1d", order);
          order++;
        end
        "X": begin
          res = $sscanf(tokens.pop_front(), "%d", index);
          res = $sscanf(tokens.pop_front(), "%h", value);
          $display("X %d %h", index, value);
        end
        "F": begin
          res = $sscanf(tokens.pop_front(), "%d", index);
          res = $sscanf(tokens.pop_front(), "%h", value);
          $display("F %d %h", index, value);
        end
        "C": begin
          res = $sscanf(tokens.pop_front(), "%h", index);
          res = $sscanf(tokens.pop_front(), "%h", value);
          $display("C %h %h", index, value);
        end
        "V": begin
          res = $sscanf(tokens.pop_front(), "%d", index);
          res = $sscanf(tokens.pop_front(), "%h", valueVr);
          $display("V %d %h", index, valueVr);
        end
        "NET": begin
          net = tokens.pop_front();
          res = $sscanf(tokens.pop_front(), "%h", value);
          $display("NET %s %h", net, value);
        end
        "MODE": begin
          res = $sscanf(tokens.pop_front(), "%h", value);
          $display("MODE %h", value);
        end
        "DM": begin
          res = $sscanf(tokens.pop_front(), "%h", value);
          $display("DM %h", value);
        end
        "META": begin
          res = $sscanf(tokens.pop_front(), "%h", value);
          while (value--) begin
            tokens.pop_front();
          end
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
    bit comment = 0;

    while (i < length) begin

      ch = line[i];
      i++;

      // leaving a comment
      if (ch == "'" && comment) begin
        comment = !comment;
        j = i;
        continue;
      end
      // entering a comment
      if (ch == "'" && !comment) begin
        comment = !comment;
        if ((i-j) > 1) begin
          tokens.push_back(token);
          token = "";
        end
      end
      // inside a comment
      if (comment) begin
        continue;
      end

      if (!isWhitespace(ch)) begin
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
