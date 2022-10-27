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

//`define RE640

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
`ifdef RE640
reg pixel_clk;
`else
wire pixel_clk;
`endif
wire [10:0] vga_hcnt, vga_vcnt;
wire vga_blank;
wire [11:0] b1_color, b2_color;
wire b1_en, b2_en;
reg [9:0] pos0, pos1;
reg reset = 0;
wire [10:0] x_loc;
reg  [10:0] x_loc_reg;

`ifdef RE640
// Clock divider. Generate 25MHz pixel_clk from 100MHz clock.
always @(posedge CLK100MHZ) begin
 pclk_div_cnt <= !pclk_div_cnt;
 if (pclk_div_cnt == 1'b1) pixel_clk <= !pixel_clk;
end
`else
// Clock for 1080p
  clk_wiz_1 clk_div_74
   (
    .clk_out1(pixel_clk),     // output clk_out1
    .clk_in1(CLK100MHZ)
    ); 
`endif


LFSR lfsr(.clock(pixel_clk), .reset(reset), .rnd(x_loc));


`ifdef RE640
// Instantiate VGA controller
vga_controller_640_60 vga_controller(
 .pixel_clk(pixel_clk),
 .HS(VGA_HS),
 .VS(VGA_VS),
 .hcounter(vga_hcnt),
 .vcounter(vga_vcnt),
 .blank(vga_blank)
);

`else

vga_controller_720_60 vga_controller(
 .pixel_clk(pixel_clk),
 .HS(VGA_HS),
 .VS(VGA_VS),
 .hcounter(vga_hcnt),
 .vcounter(vga_vcnt),
 .blank(vga_blank)
);

`endif

balloon b1(
    .x(vga_hcnt),
    .y(vga_vcnt),
    .cx(x_loc_reg),
    .cy(pos0),
    .en(b1_en),
    .color(b1_color)
);

// Cannot add balloons like this, needs to have a seperate control flow to decide which balloon each pixel belongs to
balloon b2(
    .x(vga_hcnt),
    .y(vga_vcnt),
    .cx(460),
    .cy(pos1),
    .en(b2_en),
    .color(b2_color)
);

always@(posedge pixel_clk) begin
    if (vga_hcnt == 0 && vga_vcnt==0) begin
        pos0 <= pos0 + 1;
        pos1 <= pos1 + 1;
    end
    if (pos0==0)
        x_loc_reg <= x_loc;
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
  else if (b1_en) begin
    VGA_R = b1_color[11:8]; 
    VGA_G = b1_color[7:4];
    VGA_B = b1_color[3:0];
  end
  else if (b2_en) begin
    VGA_R = b2_color[11:8]; 
    VGA_G = b2_color[7:4];
    VGA_B = b2_color[3:0];
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
    VGA_R = 4'hf; 
    VGA_G = 4'hf; 
    VGA_B = 4'hf; 
  end
end
endmodule
