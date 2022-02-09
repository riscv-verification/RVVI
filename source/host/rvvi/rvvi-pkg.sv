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

package rvvi_pkg;
    int errors     = 0;
    int max_errors = 5;
    
    function automatic void info(input string text);
        $display("RVVI(info) %0s", text);
    endfunction
    
    function automatic void error(input string text);
        errors++;
        $display("RVVI(error) %0s", text);
        if (errors >= max_errors) begin
            $display("error count exceeded");
            $finish;
        end
    endfunction
endpackage