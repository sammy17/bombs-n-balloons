`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2022 05:43:27 PM
// Design Name: 
// Module Name: t_lfsr
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


module LFSR_TB ();
 
  parameter c_NUM_BITS = 10;
   
  reg r_Clk = 1'b0;
   
  wire [c_NUM_BITS-1:0] w_LFSR_Data;
  wire w_LFSR_Done;
   
  LFSR #(.NUM_BITS(c_NUM_BITS)) LFSR_inst
         (.i_Clk(r_Clk),
          .i_Enable(1'b1),
          .i_Seed_DV(1'b0),
          .i_Seed_Data({c_NUM_BITS{1'b0}}), // Replication
          .o_LFSR_Data(w_LFSR_Data),
          .o_LFSR_Done(w_LFSR_Done)
          );
  
  always @(*)
    #10 r_Clk <= ~r_Clk; 
   
endmodule // LFSR_TB