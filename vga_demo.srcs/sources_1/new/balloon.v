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


module balloon( rst, clk, frame_end, x, y);
parameter RAD = 50;
parameter START = 4;
parameter MAXV = 720;
parameter MAXH = 1280;
input clk, frame_end, rst;
output reg [10:0] x;
output reg [10:0] y;
//output reg [11:0] color;

//`include "bl_colors.vh"
reg  [31:0] frame_count;
wire [9:0] x_loc;
wire mov_en;

LFSR  lfsr
         (.i_Clk(clk),
          .i_Enable(1'b1),
          .i_Seed_DV(1'b0),
          .i_Seed_Data({10{1'b0}}), // Replication
          .o_LFSR_Data(x_loc),
          .o_LFSR_Done()
          );


//always@(posedge clk) begin
//    if (frame_count >= START) begin 
//        mov_en <= 1;
//    end
//    else begin 
//        mov_en <= 0;
//    end
//end

assign mov_en = (frame_count >= START) ? 1'b1 : 1'b0;

always@(posedge clk) begin
    if (rst) begin
        frame_count <= 0;
        x <= x_loc;
        y <= MAXV;
    end
    else if (frame_end) begin
        frame_count <= frame_count + 1;
        x <= x_loc;
        if (mov_en)
            y <= y - 1;
        else 
            y <= y;
    end
//    else if (mov_en) begin
//        frame_count <= frame_count;
//        x <= x;
//        y <= y - 1;
//    end
    else begin
        frame_count <= frame_count;
        x <= x;
        y <= y;
    end 
end

//reg [2:0] count = 0;
//wire in_balloon;

//assign en = (cx-x)*(cx-x) + (cy-y)*(cy-y) < RAD;

//always@(cy)
//    if (cy==0) begin
//        count = count + 1;
//        color = colors[count];
//    end

//assign r = color[11:8];
//assign g = color[7:4];
//assign b = color[3:0];

endmodule
