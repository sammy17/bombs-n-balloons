`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2022 05:37:09 PM
// Design Name: 
// Module Name: timer
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


module timer_clk_generator(CLK100MHZ, out_clk);
    input CLK100MHZ;
    output reg out_clk;
    reg [31:0] counter;
    
    always@(posedge CLK100MHZ) begin
        counter <= counter + 1;
        if (counter == (12_500_000*4)) begin
            counter <= 0;
   
            out_clk <= ~out_clk;
        end
    end
endmodule
