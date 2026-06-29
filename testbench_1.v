// Testing Overflow Detection

module test_mips32_overflow;
reg clk1,clk2;
integer k;
pipe_MIPS32 mips(clk1,clk2);
initial
begin
    clk1=0;
    clk2=0;
    repeat(20)
    begin
        #5 clk1=1; #5 clk1=0;
        #5 clk2=1; #5 clk2=0;
    end
end
initial
begin
    for(k=0;k<31;k=k+1)
        mips.Reg[k]=0;
    mips.Reg[1]=32'h7fffffff; //+1
    mips.Reg[2]=1;
    mips.Reg[3]=32'h80000000;

    //-------------------------------------------------
    // Program
    //-------------------------------------------------

    mips.Mem[0]=32'h00222000;      // ADD R4,R1,R2 (Overflow)
    mips.Mem[1]=32'h0ce77800;      // Dummy
    mips.Mem[2]=32'h0ce77800;      // Dummy
    mips.Mem[3]=32'h04622800;      // SUB R5,R3,R2 (Overflow)
    mips.Mem[4]=32'h0ce77800;      // Dummy
    mips.Mem[5]=32'h0ce77800;      // Dummy
    mips.Mem[6]=32'hfc000000;      // HLT
    mips.PC=0;
    mips.HALTED=0;
    mips.TAKEN_BRANCH=0;
    #250
    $display("\n------ OVERFLOW TEST ------");
    $display("R1 = %h",mips.Reg[1]);
    $display("R2 = %h",mips.Reg[2]);
    $display("R3 = %h",mips.Reg[3]);
    $display("R4 = %h",mips.Reg[4]);
    $display("R5 = %h",mips.Reg[5]);
end
initial
begin
    $dumpfile("overflow.vcd");
    $dumpvars(0,test_mips32_overflow);
    #300 $finish;
end
endmodule