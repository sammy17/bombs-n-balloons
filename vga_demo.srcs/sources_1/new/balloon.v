`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2022 05:18:48 PM
// Design Name: 
// Module Name: balloon
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


module balloon( x, y, cx, cy, r, g, b);
input [9:0] x, y;
input [9:0] cx, cy;
output [3:0] r, g, b;

localparam RAD = 20;

wire in_balloon;

assign in_balloon = (cx-x)*(cx-x) + (cy-y)*(cy-y) < RAD;

assign r = in_balloon ? 4'h0 : 4'hf;
assign g = in_balloon ? 4'h0 : 4'hf;
assign b = in_balloon ? 4'h0 : 4'hf;

endmodule
