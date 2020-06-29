`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.02.2019 16:17:33
// Design Name: 
// Module Name: sum_conv_pipeline
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sum_conv_pipeline #(parameter NBits = 16, entero  = 4, fraccion =12) (
    input clk,
    input rst,
    input [399:0] multiplied,
    input valid_in,
    output reg valid_prop,
    output [NBits-1:0] pixel_result 
    );
    
    wire [15:0] result_0_0, result_0_1, result_0_2, result_0_3, result_0_4, result_0_5, result_0_6, result_0_7,
     result_0_8, result_0_9, result_0_10, result_0_11, result_0_12, result_0_13;
    
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_0 (.Clk(clk),.Reset(rst),.Var0(multiplied[399:384]),.Var1(multiplied[383:368]),.VarOut(result_0_0));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_1 (.Clk(clk),.Reset(rst),.Var0(multiplied[367:352]),.Var1(multiplied[351:336]),.VarOut(result_0_1));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_2 (.Clk(clk),.Reset(rst),.Var0(multiplied[335:320]),.Var1(multiplied[319:304]),.VarOut(result_0_2));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_3 (.Clk(clk),.Reset(rst),.Var0(multiplied[303:288]),.Var1(multiplied[287:272]),.VarOut(result_0_3));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_4 (.Clk(clk),.Reset(rst),.Var0(multiplied[271:256]),.Var1(multiplied[255:240]),.VarOut(result_0_4));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_5 (.Clk(clk),.Reset(rst),.Var0(multiplied[239:224]),.Var1(multiplied[223:208]),.VarOut(result_0_5));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_6 (.Clk(clk),.Reset(rst),.Var0(multiplied[207:192]),.Var1(multiplied[191:176]),.VarOut(result_0_6));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_7 (.Clk(clk),.Reset(rst),.Var0(multiplied[175:160]),.Var1(multiplied[159:144]),.VarOut(result_0_7));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_8 (.Clk(clk),.Reset(rst),.Var0(multiplied[143:128]),.Var1(multiplied[127:112]),.VarOut(result_0_8));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_9 (.Clk(clk),.Reset(rst),.Var0(multiplied[111:96]),.Var1(multiplied[95:80]),.VarOut(result_0_9));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_10 (.Clk(clk),.Reset(rst),.Var0(multiplied[79:64]),.Var1(multiplied[63:48]),.VarOut(result_0_10));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_11 (.Clk(clk),.Reset(rst),.Var0(multiplied[47:32]),.Var1(multiplied[31:16]),.VarOut(result_0_11));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_12 (.Clk(clk),.Reset(rst),.Var0(multiplied[15:0]),.Var1(16'h0000),.VarOut(result_0_12));

    wire [15:0] result_1_0, result_1_1, result_1_2, result_1_3, result_1_4, result_1_5, result_1_6, result_1_7;
    
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_0_0 (.Clk(clk),.Reset(rst),.Var0(result_0_0),.Var1(result_0_1),.VarOut(result_1_0));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_0_1 (.Clk(clk),.Reset(rst),.Var0(result_0_2),.Var1(result_0_3),.VarOut(result_1_1));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_0_2 (.Clk(clk),.Reset(rst),.Var0(result_0_4),.Var1(result_0_5),.VarOut(result_1_2));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_0_3 (.Clk(clk),.Reset(rst),.Var0(result_0_6),.Var1(result_0_7),.VarOut(result_1_3));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_0_4 (.Clk(clk),.Reset(rst),.Var0(result_0_8),.Var1(result_0_9),.VarOut(result_1_4));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_0_5 (.Clk(clk),.Reset(rst),.Var0(result_0_10),.Var1(result_0_11),.VarOut(result_1_5));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_0_6 (.Clk(clk),.Reset(rst),.Var0(result_0_12),.Var1(16'h0000),.VarOut(result_1_6));
    
    wire [15:0] result_2_0, result_2_1, result_2_2, result_2_3;
    
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_1_0 (.Clk(clk),.Reset(rst),.Var0(result_1_0),.Var1(result_1_1),.VarOut(result_2_0));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_1_1 (.Clk(clk),.Reset(rst),.Var0(result_1_2),.Var1(result_1_3),.VarOut(result_2_1));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_1_2 (.Clk(clk),.Reset(rst),.Var0(result_1_4),.Var1(result_1_5),.VarOut(result_2_2));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_1_3 (.Clk(clk),.Reset(rst),.Var0(result_1_6),.Var1(16'h0000),.VarOut(result_2_3));
    
    wire [15:0] result_3_0, result_3_1;
    
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_2_0 (.Clk(clk),.Reset(rst),.Var0(result_2_0),.Var1(result_2_1),.VarOut(result_3_0));
    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_2_1 (.Clk(clk),.Reset(rst),.Var0(result_2_2),.Var1(result_2_3),.VarOut(result_3_1));
    

    Sum #(.NBits(NBits),.entero(entero),.fraccion(fraccion)) sum_3_0 (.Clk(clk),.Reset(rst),.Var0(result_3_0),.Var1(result_3_1),.VarOut(pixel_result));    
    
    
    reg valid_0, valid_1, valid_2, valid_3;
    
    always @(posedge(clk), negedge rst) begin
        if(!rst) begin
            valid_0 <= 1'b0;
            valid_1 <= 1'b0;
            valid_2 <= 1'b0;
            valid_3 <= 1'b0;
            valid_prop <= 1'b0;
        end
        else begin
            valid_0 <= valid_in;
            valid_1 <= valid_0;
            valid_2 <= valid_1;
            valid_3 <= valid_2;
            valid_prop <= valid_3;
        end
     end
endmodule
