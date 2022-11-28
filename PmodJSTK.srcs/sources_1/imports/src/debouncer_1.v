`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/21/2022 12:33:52 PM
// Design Name: 
// Module Name: debouncer
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


module debouncer( clk, in, out);

input       clk     ;
input       in  ;
output reg  out  ;

reg tmp0, tmp1;

always@(posedge clk) begin
    tmp0 <= in;
    tmp1 <= ~tmp0;
    out <= tmp0 & tmp1;
end

endmodule
