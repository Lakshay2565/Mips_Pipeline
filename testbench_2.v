// ============================================================
// Testbench 2 : Logical & Subtraction Operations
// Loads R1=15, R2=9, then tests AND / XOR / OR / SUB.
//
// Instruction encodings (hand-verified):
//   ADDI  rt, rs, imm  → opcode=001010  stored to rt  (RM_ALU)
//   AND   rd, rs, rt   → opcode=000010  stored to rd  (RR_ALU)
//   XOR   rd, rs, rt   → opcode=000110  stored to rd  (RR_ALU)
//   OR    rd, rs, rt   → opcode=000011  stored to rd  (RR_ALU)
//   SUB   rd, rs, rt   → opcode=000001  stored to rd  (RR_ALU)
//   NOP = OR R7, R7, R7 (writes back to R7, safe dummy)
//
// Expected results
//   R1 = 15
//   R2 =  9
//   R3 = 15 & 9  = 9   (AND)
//   R4 = 15 ^ 9  = 6   (XOR)
//   R5 = 15 | 9  = 15  (OR)
//   R6 = 15 - 9  = 6   (SUB)
// ============================================================
module test_mips32_tb2;

    reg     clk1, clk2;
    integer k;

    pipe_MIPS32 mips (clk1, clk2);

    // ---- two-phase clock generator ----
    initial
        begin
            clk1 = 0; clk2 = 0;
            repeat (20)
                begin
                    #5 clk1 = 1; #5 clk1 = 0;
                    #5 clk2 = 1; #5 clk2 = 0;
                end
        end

    // ---- load program and display results ----
    initial
        begin
            // initialise register file
            for (k = 0; k < 31; k++)
                mips.Reg[k] = k;

            // ---------- program ----------
            mips.Mem[0]  = 32'h2801000F; // ADDI R1, R0, 15   → R1 = 15
            mips.Mem[1]  = 32'h28020009; // ADDI R2, R0,  9   → R2 =  9
            mips.Mem[2]  = 32'h0CE73800; // NOP  (OR  R7, R7, R7)
            mips.Mem[3]  = 32'h0CE73800; // NOP  (OR  R7, R7, R7)
            mips.Mem[4]  = 32'h08221800; // AND  R3, R1, R2   → R3 =  9
            mips.Mem[5]  = 32'h0CE73800; // NOP  (OR  R7, R7, R7)
            mips.Mem[6]  = 32'h18222000; // XOR  R4, R1, R2   → R4 =  6
            mips.Mem[7]  = 32'h0CE73800; // NOP  (OR  R7, R7, R7)
            mips.Mem[8]  = 32'h0C222800; // OR   R5, R1, R2   → R5 = 15
            mips.Mem[9]  = 32'h0CE73800; // NOP  (OR  R7, R7, R7)
            mips.Mem[10] = 32'h04223000; // SUB  R6, R1, R2   → R6 =  6
            mips.Mem[11] = 32'hFC000000; // HLT
            // -----------------------------

            mips.HALTED       = 0;
            mips.PC           = 0;
            mips.TAKEN_BRANCH = 0;

            #280
            $display("============================================");
            $display(" TB2 : Logical & Subtraction Results");
            $display("============================================");
            for (k = 0; k < 7; k++)
                $display("  R%0d = %0d", k, mips.Reg[k]);
            $display("--------------------------------------------");
            $display("  Expected : R1=15  R2=9");
            $display("             R3=9  (AND)");
            $display("             R4=6  (XOR)");
            $display("             R5=15 (OR)");
            $display("             R6=6  (SUB)");
            $display("============================================");
        end

    // ---- waveform dump ----
    initial
        begin
            $dumpfile("mips_tb2.vcd");
            $dumpvars(0, test_mips32_tb2);
            #300 $finish;
        end

endmodule