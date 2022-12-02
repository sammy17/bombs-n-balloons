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


module bomb( rst, clk, frame_end, min, x, y, bullet_x, bullet_y, en);
parameter START = 4;
parameter MAXV = 480;
parameter MAXH = 640;
parameter NUM_BULLETS = 10;
//parameter MINX = 40;
//parameter MAXX = 550;

input clk, frame_end, rst;
input [11*NUM_BULLETS-1:0] min;
input [11*NUM_BULLETS-1:0] bullet_x, bullet_y;
output reg [10:0] x;
output reg [10:0] y;
output en;
//output reg [11:0] color;

localparam BWIDTH = 18;
localparam BHEIGHT = 24;

//`include "bl_colors.vh"
reg  [31:0] frame_count;
wire [10:0] x_loc;
wire mov_en, change_x;
wire [10:0] x_loc_range;
reg [NUM_BULLETS-1:0] en_r;

LFSR  lfsr
         (.i_Clk(clk),
          .i_Enable(1'b1),
          .i_Seed_DV(1'b0),
          .i_Seed_Data(START), // Replication
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
assign change_x = (y==MAXV) ? 1'b1 : 1'b0;

assign x_loc_range = (x_loc < 510) ? x_loc : (x_loc%510);

always@(posedge clk) begin
    if (rst) begin
        frame_count <= 0;
        x <= x_loc_range;
        y <= -11'd20;
    end
    else if (frame_end) begin
        frame_count <= frame_count + 1;
        x <= x;
        if (mov_en)
            y <= y + 1;
        else 
            y <= y;
    end
    else if (change_x) begin
        frame_count <= frame_count;
        x <= x_loc_range;
        y <= y;
    end
    else if (y==MAXV+20) begin
        frame_count <= frame_count;
        x <= x;
        y <= -11'd20;
    end
    else if (~mov_en) begin
        frame_count <= frame_count;
        y <= y;
        x <= x_loc_range;
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

genvar i;
// collision detect
generate
    for (i=0; i<NUM_BULLETS; i=i+1) begin
        always@(posedge clk)  begin
            if (rst) begin
                en_r[i] <= 1;
            end
            else if  ((bullet_x[((i+1)*11)-1:i*11] > x) & (bullet_x[((i+1)*11)-1:i*11] < x+BWIDTH) & (bullet_y[((i+1)*11)-1:i*11] > y-10) & (bullet_y[((i+1)*11)-1:i*11] < y+BHEIGHT) & (en)) begin
                en_r[i] <= 0;
            end
            else if (~en & y==-11'd20) begin
                en_r[i] <= 1;
            end
            else begin
                en_r[i] <= en_r[i];
            end
        end
    end
endgenerate


assign en = &en_r;

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
