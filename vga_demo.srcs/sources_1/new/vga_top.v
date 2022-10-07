`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/06/2022 03:47:47 PM
// Design Name: 
// Module Name: vga_top
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



// top module that instantiates the VGA controller and generates images
module top(
 input wire CLK100MHZ,
 output reg [3:0] VGA_R,
 output reg [3:0] VGA_G,
 output reg [3:0] VGA_B,
 output wire VGA_HS,
 output wire VGA_VS
 );
reg pclk_div_cnt;
reg pixel_clk;
wire [10:0] vga_hcnt, vga_vcnt;
wire vga_blank;
wire [3:0] r, g, b;
reg [8:0] pos;
// Clock divider. Generate 25MHz pixel_clk from 100MHz clock.
always @(posedge CLK100MHZ) begin
 pclk_div_cnt <= !pclk_div_cnt;
 if (pclk_div_cnt == 1'b1) pixel_clk <= !pixel_clk;
end
// Instantiate VGA controller
vga_controller_640_60 vga_controller(
 .pixel_clk(pixel_clk),
 .HS(VGA_HS),
 .VS(VGA_VS),
 .hcounter(vga_hcnt),
 .vcounter(vga_vcnt),
 .blank(vga_blank)
);

balloon b1(
    .x(vga_hcnt),
    .y(vga_vcnt),
    .cx(320),
    .cy(pos),
    .r(r),
    .g(g),
    .b(b)
);

always@(posedge pixel_clk) begin
    if (vga_hcnt == 0 && vga_vcnt==0) begin
        pos = pos + 1;
    end
end

// Generate figure to be displayed
// Decide the color for the current pixel at index (hcnt, vcnt).
// This example displays an white square at the center of the screen with a colored checkerboard background.
always @(*) begin
 // Set pixels to black during Sync. Failure to do so will result in dimmed colors or black screens.
 if (vga_blank) begin
    VGA_R = 0;
    VGA_G = 0;
    VGA_B = 0;
  end
 // Image to be displayed
 else begin
 // Default values for the checkerboard background
//    VGA_R = vga_vcnt[6:3];
//    VGA_G = vga_hcnt[6:3];
//    VGA_B = vga_vcnt[6:3] + vga_hcnt[6:3];
 
 // White square at the center
//    if ((vga_hcnt >= 300 && vga_hcnt <= 340) && (vga_vcnt >= 220 && vga_vcnt <= 260)) begin
//        VGA_R = 4'hf;
//        VGA_G = 4'hf;
//        VGA_B = 4'hf;
//    end
    VGA_R = r; 
    VGA_G = g;
    VGA_B = b;
  end
end
endmodule
