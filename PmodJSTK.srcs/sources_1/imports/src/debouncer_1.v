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

reg [7:0] counter = 0;
reg start_count = 0;

always@(posedge clk) begin
    if (start_count)
        counter = counter + 1;
end

always@(posedge clk) begin
    tmp0 <= in;
    tmp1 <= ~tmp0;
    out <= tmp0 & tmp1;
//    if (in==1 && ~start_count) begin
//        out <= 1;
//        start_count <= 1;
//    end
//    else if (out==1) begin
//        out <= 0;
//        start_count <= start_count;
//    end
//    else if (counter==8'd4) begin
//        out <= 0;
//        start_count <= 0;
//    end
end

endmodule
