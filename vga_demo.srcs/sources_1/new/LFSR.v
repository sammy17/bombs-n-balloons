`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2022 06:31:12 PM
// Design Name: 
// Module Name: LFSR
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

module LFSR (
    input clock,
    input reset,
    output [10:0] rnd 
    );

reg [10:0] random, random_next, random_done;
reg [3:0] count, count_next; //to keep track of the shifts

wire feedback = random[10] ^ random[8]; 

always @ (posedge clock or posedge reset)
begin
 if (reset)
 begin
  random <= 11'hF; //An LFSR cannot have an all 0 state, thus reset to FF
  count <= 0;
 end
 
 else
 begin
  random <= random_next;
  count <= count_next;
 end
end

always @ (*)
begin
 random_next = random; //default state stays the same
 count_next = count;
  
  random_next = {random[9:0], feedback}; //shift left the xor'd every posedge clock
  count_next = count + 1;

 if (count == 11)
 begin
  count = 0;
  random_done = random; //assign the random number to output after 13 shifts
 end
 
end


assign rnd = random_done;

endmodule
