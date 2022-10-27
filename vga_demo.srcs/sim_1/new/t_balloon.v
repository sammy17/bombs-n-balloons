`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2022 07:28:16 PM
// Design Name: 
// Module Name: t_balloon
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


module t_balloon();

reg clk, rst;
reg frame_end;

wire [10:0] x, y;

initial clk = 0;

initial frame_end = 0;

always @(*)
  #10 clk <= ~clk; 

//always @(*) begin
//  #180 ; 
//  frame_end = 1; 
//  #20 frame_end = 0;
//end

balloon b1 (.rst(rst), .clk(clk), .frame_end(frame_end), .x(x), .y(y));

initial begin 
    rst = 1; 
    #40 rst = 0;
    #180 frame_end = 1;
    #20  frame_end = 0;
    #500;
    #180 frame_end = 1;
    #20  frame_end = 0;
    #500;
    #180 frame_end = 1;
    #20  frame_end = 0;
    #500;
    #180 frame_end = 1;
    #20  frame_end = 0;
    #500;
    #180 frame_end = 1;
    #20  frame_end = 0;
    #500;
    #180 frame_end = 1;
    #20  frame_end = 0;
    #500;
    #180 frame_end = 1;
    #20  frame_end = 0;
    #500;
    $finish;
end

endmodule
