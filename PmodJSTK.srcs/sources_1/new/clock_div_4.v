`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/02/2022 05:40:32 PM
// Design Name: 
// Module Name: clock_div
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


module clock_div_4( clk_in, clk_out); // 100MHz -> 4Hz


input       clk_in  ;

output reg  clk_out ;


reg [25:0] counter = 0;


always@(posedge clk_in) begin

    counter <= counter + 1;

    if (counter == (12_500_000)) begin

        counter <= 0;

        clk_out <= ~clk_out;

    end

end

    

endmodule