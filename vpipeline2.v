module pipe_MIPS32(clk1,clk2);
    input clk1,clk2; // TWO PHASE CLOCK

    reg [31:0] PC,IF_ID_IR,IF_ID_NPC;
   
    reg [31:0] ID_EX_IR, ID_EX_NPC,ID_EX_A,ID_EX_B,ID_EX_Imm;
   
    reg [2:0] ID_EX_type,EX_MEM_type,MEM_WB_type;

    reg [31:0] EX_MEM_IR, EX_MEM_ALUOut,EX_MEM_B;
    reg EX_MEM_cond;
    reg OVERFLOW;
    reg [31:0] temp_sum;
    reg [31:0] temp_diff;

    reg [31:0] MEM_WB_IR, MEM_WB_ALUOut,MEM_WB_LMD;

    reg [31:0] Reg [0:31]; // REGISTER BANK (32X32)
    reg [31:0] Mem [0:1023]; // 1024 X 32 MEMORY    

    parameter ADD=6'b000000, SUB=6'b000001,AND=6'b000010, OR=6'b000011,
              SLT=6'b000100 ,MUL=6'b000101,HLT=6'b111111, LW=6'b001000,
              SW=6'b001001,ADDI=6'b001010, SUBI=6'b001011,SLTI=6'b001100,
              BNEQZ=6'b001101, BEQZ=6'b001110, XOR=6'b000110, NOR=6'b000111,
              SLL=6'b010000, SRL=6'b010001;

    parameter RR_ALU=3'b000,RM_ALU=3'b001, LOAD=3'b010,STORE=3'b011,
              BRANCH=3'b100, HALT=3'b101;

    reg HALTED;
    reg TAKEN_BRANCH;
    initial begin PC=0; HALTED=0; TAKEN_BRANCH=0; OVERFLOW=0; end

    // =========================================================
    // IF STAGE  (clk1)
    // =========================================================
    always @(posedge clk1)
        if (HALTED == 0)
        begin
            if (((EX_MEM_IR[31:26] == BEQZ)  && (EX_MEM_cond == 1)) ||
                ((EX_MEM_IR[31:26] == BNEQZ) && (EX_MEM_cond == 0)))
                begin
                    IF_ID_IR     <= #2 Mem[EX_MEM_ALUOut]; 
                    TAKEN_BRANCH <= #2 1'b1;               
                    IF_ID_NPC    <= #2 EX_MEM_ALUOut + 1;
                    PC           <= #2 EX_MEM_ALUOut + 1;
                end
            else
                begin
                    IF_ID_IR     <= #2 Mem[PC];
                    IF_ID_NPC    <= #2 PC + 1;
                    PC           <= #2 PC + 1;
                    TAKEN_BRANCH <= #2 1'b0;
                end
        end

    // =========================================================
    // ID STAGE  (clk2)
    // =========================================================
    always @(posedge clk2)
        if (HALTED == 0)
        begin 
            if (IF_ID_IR[25:21] == 5'b00000) ID_EX_A <= 0;
            else ID_EX_A <= #2 Reg[IF_ID_IR[25:21]];  // rs

            if (IF_ID_IR[20:16] == 5'b00000) ID_EX_B <= 0;
            else ID_EX_B <= #2 Reg[IF_ID_IR[20:16]];  // rt

            ID_EX_NPC <= #2 IF_ID_NPC;
            ID_EX_IR  <= #2 IF_ID_IR;
            ID_EX_Imm <= #2 {{16{IF_ID_IR[15]}}, {IF_ID_IR[15:0]}}; // sign-extend

            case (IF_ID_IR[31:26])
                ADD,SUB,AND,OR,SLT,MUL,XOR,NOR,SLL,SRL: ID_EX_type <= #2 RR_ALU;
                ADDI,SUBI,SLTI:                           ID_EX_type <= #2 RM_ALU;
                LW:                                       ID_EX_type <= #2 LOAD;
                SW:                                       ID_EX_type <= #2 STORE;
                BNEQZ,BEQZ:                               ID_EX_type <= #2 BRANCH;
                HLT:                                      ID_EX_type <= #2 HALT;
                default:                                  ID_EX_type <= #2 HALT;
            endcase
        end  

    // =========================================================
    // EX STAGE  (clk1)
    // =========================================================
    always @(posedge clk1)
        if (HALTED == 0)
        begin 
            EX_MEM_type <= #2 ID_EX_type;
            EX_MEM_IR   <= #2 ID_EX_IR;
            OVERFLOW    <= #2 1'b0;

            case (ID_EX_type)
                RR_ALU: begin
                    case (ID_EX_IR[31:26])
                        ADD: begin
                            temp_sum = ID_EX_A + ID_EX_B;
                            EX_MEM_ALUOut <= #2 temp_sum;
                            if ((ID_EX_A[31] == ID_EX_B[31]) && (temp_sum[31] != ID_EX_A[31]))
                                begin
                                    OVERFLOW <= #2 1'b1;
                                    $display("======================================");
                                    $display("ARITHMETIC OVERFLOW DETECTED");
                                    $display("Simulation Time : %0t", $time);
                                    $display("Instruction     : ADD");
                                    $display("Operand A       : %d", $signed(ID_EX_A));
                                    $display("Operand B       : %d", $signed(ID_EX_B));
                                    $display("======================================");
                                end
                            else OVERFLOW <= #2 1'b0;
                        end
                        SUB: begin
                            temp_diff = ID_EX_A - ID_EX_B;
                            EX_MEM_ALUOut <= #2 temp_diff;
                            if ((ID_EX_A[31] != ID_EX_B[31]) && (temp_diff[31] != ID_EX_A[31]))
                                begin
                                    OVERFLOW <= #2 1'b1;
                                    $display("======================================");
                                    $display("ARITHMETIC OVERFLOW DETECTED");
                                    $display("Simulation Time : %0t", $time);
                                    $display("Instruction     : SUB");
                                    $display("Operand A       : %d", $signed(ID_EX_A));
                                    $display("Operand B       : %d", $signed(ID_EX_B));
                                    $display("======================================");
                                end
                            else OVERFLOW <= #2 1'b0;
                        end
                        AND:  EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
                        OR:   EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
                        SLT:  EX_MEM_ALUOut <= #2 ((ID_EX_A < ID_EX_B) ? 32'd1 : 32'd0);
                        MUL:  EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
                        XOR:  EX_MEM_ALUOut <= #2 ID_EX_A ^ ID_EX_B;
                        NOR:  EX_MEM_ALUOut <= #2 ~(ID_EX_A | ID_EX_B);
                        SLL:  EX_MEM_ALUOut <= #2 ID_EX_A << ID_EX_B[4:0];
                        SRL:  EX_MEM_ALUOut <= #2 ID_EX_A >> ID_EX_B[4:0];
                        default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
                    endcase
                end

                RM_ALU: begin
                    case (ID_EX_IR[31:26])
                        ADDI: begin
                            temp_sum = ID_EX_A + ID_EX_Imm;
                            EX_MEM_ALUOut <= #2 temp_sum;
                            if ((ID_EX_A[31] == ID_EX_Imm[31]) && (temp_sum[31] != ID_EX_A[31]))
                                begin
                                    OVERFLOW <= #2 1'b1;
                                    $display("======================================");
                                    $display("ARITHMETIC OVERFLOW DETECTED");
                                    $display("Simulation Time : %0t", $time);
                                    $display("Instruction     : ADDI");
                                    $display("Operand A : %d", $signed(ID_EX_A));
                                    $display("Immediate : %d", $signed(ID_EX_Imm));
                                    $display("======================================");
                                end
                            else OVERFLOW <= #2 1'b0;
                        end
                        SUBI: begin
                            temp_diff = ID_EX_A - ID_EX_Imm;
                            EX_MEM_ALUOut <= #2 temp_diff;
                            if ((ID_EX_A[31] != ID_EX_Imm[31]) && (temp_diff[31] != ID_EX_A[31]))
                                begin
                                    OVERFLOW <= #2 1'b1;
                                    $display("======================================");
                                    $display("ARITHMETIC OVERFLOW DETECTED");
                                    $display("Simulation Time : %0t", $time);
                                    $display("Instruction     : SUBI");
                                    $display("Operand A : %d", $signed(ID_EX_A));
                                    $display("Immediate : %d", $signed(ID_EX_Imm));
                                    $display("======================================");
                                end
                            else OVERFLOW <= #2 1'b0;
                        end
                        SLTI: EX_MEM_ALUOut <= #2 ((ID_EX_A < ID_EX_Imm) ? 32'd1 : 32'd0);
                        default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
                    endcase
                end

                LOAD,STORE: begin
                    EX_MEM_ALUOut <= #2 ID_EX_A + ID_EX_Imm;
                    EX_MEM_B      <= #2 ID_EX_B;
                end

                BRANCH: begin
                    EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm;
                    EX_MEM_cond   <= #2 (ID_EX_A == 0);
                end
            endcase
        end

    // =========================================================
    // MEM STAGE  (clk2)
    // =========================================================
    always @(posedge clk2)
        if (HALTED == 0)
        begin
            MEM_WB_type <= #2 EX_MEM_type;
            MEM_WB_IR   <= #2 EX_MEM_IR;

            case (EX_MEM_type)
                RR_ALU, RM_ALU: MEM_WB_ALUOut <= #2 EX_MEM_ALUOut;
                LOAD:           MEM_WB_LMD    <= #2 Mem[EX_MEM_ALUOut];
                STORE: if (TAKEN_BRANCH == 0)
                           Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B;
            endcase
        end  

    // =========================================================
    // WB STAGE  (clk1)
    // =========================================================
    always @(posedge clk1)
        begin
            if (TAKEN_BRANCH == 0)
                case (MEM_WB_type)
                    RR_ALU: Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut; // rd
                    RM_ALU: Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut; // rt
                    LOAD:   Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;    // rt
                    default: ;
                endcase

            if (MEM_WB_type == HALT)
                HALTED <= #2 1'b1;
        end

endmodule