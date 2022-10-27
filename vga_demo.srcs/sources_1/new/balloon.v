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


module balloon( x, y, cx, cy, color, en);

input [9:0] x, y;
input [9:0] cx, cy;
output reg [11:0] color;
output en;

`include "bl_colors.vh"

localparam RAD = 50;

reg [2:0] count = 0;
//wire in_balloon;

assign en = (cx-x)*(cx-x) + (cy-y)*(cy-y) < RAD;

always@(cy)
    if (cy==0) begin
        count = count + 1;
        color = colors[count];
    end

//assign r = color[11:8];
//assign g = color[7:4];
//assign b = color[3:0];

endmodule
