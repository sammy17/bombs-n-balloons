`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: 
// 
// Create Date:    07/11/2012
// Module Name:    PmodJSTK_Demo 
// Project Name: 	 PmodJSTK_Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.1
// Description: This is a demo for the Digilent PmodJSTK. Data is sent and received
//					 to and from the PmodJSTK at a frequency of 5Hz, and positional 
//					 data is displayed on the seven segment display (SSD). The positional
//					 data of the joystick ranges from 0 to 1023 in both the X and Y
//					 directions. Only one coordinate can be displayed on the SSD at a
//					 time, therefore switch SW0 is used to select which coordinate's data
//	   			 to display. The status of the buttons on the PmodJSTK are
//					 displayed on LD2, LD1, and LD0 on the Nexys3. The LEDs will
//					 illuminate when a button is pressed. Switches SW2 and SW1 on the
//					 Nexys3 will turn on LD1 and LD2 on the PmodJSTK respectively. Button
//					 BTND on the Nexys3 is used for resetting the demo. The PmodJSTK
//					 connects to pins [4:1] on port JA on the Nexys3. SPI mode 0 is used
//					 for communication between the PmodJSTK and the Nexys3.
//
//					 NOTE: The digits on the SSD may at times appear to flicker, this
//						    is due to small pertebations in the positional data being read
//							 by the PmodJSTK's ADC. To reduce the flicker simply reduce
//							 the rate at which the data being displayed is updated.
//
// Revision History: 
// 						Revision 0.01 - File Created (Josh Sackos)
//////////////////////////////////////////////////////////////////////////////////


// ============================================================================== 
// 										  Define Module
// ==============================================================================
module PmodJSTK_Demo(
    CLK,
    RST,
    MISO,
	 SW,
    SS,
    MOSI,
    SCLK,
    LED,
	 AN,
	 SEG,
	 VGA_R,
	 VGA_G,
	 VGA_B,
	 VGA_HS,
	 VGA_VS
    );

	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================
			input CLK;					// 100Mhz onboard clock
			input RST;					// Button D
			input MISO;					// Master In Slave Out, Pin 3, Port JA
			input [2:0] SW;			// Switches 2, 1, and 0
			output SS;					// Slave Select, Pin 1, Port JA
			output MOSI;				// Master Out Slave In, Pin 2, Port JA
			output SCLK;				// Serial Clock, Pin 4, Port JA
			output [2:0] LED;			// LEDs 2, 1, and 0
			//output [3:0] AN;			// Anodes for Seven Segment Display
			output [7:0] AN;
			output [6:0] SEG;			// Cathodes for Seven Segment Display
            output wire [3:0] VGA_R;
            output wire [3:0] VGA_G;
            output wire [3:0] VGA_B;
            output wire VGA_HS;
            output wire VGA_VS;
             
            
             wire slow_clock;
             													
			 clk_wiz_0 instance_name // For slowing down the clock
                            (
            // Clock out ports
            .clk_out1(slow_clock),     // output clk_out1
            // Clock in ports
            .clk_in1(CLK));
	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================
			wire SS;						// Active low
			wire MOSI;					// Data transfer from master to slave
			wire SCLK;					// Serial clock that controls communication
			reg [2:0] LED;				// Status of PmodJSTK buttons displayed on LEDs
			//wire [3:0] AN;				// Anodes for Seven Segment Display
			wire [7:0] AN;
			wire [6:0] SEG;			// Cathodes for Seven Segment Display

			// Holds data to be sent to PmodJSTK
			wire [7:0] sndData;

			// Signal to send/receive data to/from PmodJSTK
			wire sndRec;

			// Data read from PmodJSTK
			wire [39:0] jstkData;

			// Signal carrying output data that user selected
			wire [9:0] posData;

	// ===========================================================================
	// 										Implementation
	// ===========================================================================


			//-----------------------------------------------
			//  	  			PmodJSTK Interface
			//-----------------------------------------------
			PmodJSTK PmodJSTK_Int(
					.CLK(CLK),
					.RST(RST),
					.sndRec(sndRec),
					.DIN(sndData),
					.MISO(MISO),
					.SS(SS),
					.SCLK(SCLK),
					.MOSI(MOSI),
					.DOUT(jstkData)
			);
			


			//-----------------------------------------------
			//  		Seven Segment Display Controller
			//-----------------------------------------------
			ssdCtrl DispCtrl(
					.CLK(CLK),
					.RST(RST),
					.DIN(posData),
					.AN(AN),
					.SEG(SEG)
			);
			
			

			//-----------------------------------------------
			//  			 Send Receive Generator
			//-----------------------------------------------
			ClkDiv_5Hz genSndRec(
					.CLK(CLK),
					.RST(RST),
					.CLKOUT(sndRec)
			);
			
			
			clock_div slowerClock( .clk_in(CLK), .clk_out(clk_out)); // 100MHz -> 4Hz
			

			// Use state of switch 0 to select output of X position or Y position data to SSD
			assign posData = (SW[0] == 1'b1) ? {jstkData[9:8], jstkData[23:16]} : {jstkData[25:24], jstkData[39:32]};

			// Data to be sent to PmodJSTK, lower two bits will turn on leds on PmodJSTK
			assign sndData = {8'b100000, {SW[1], SW[2]}};

			// Assign PmodJSTK button status to LED[2:0] & Making the character
		    parameter upper_limit = 5;
	        parameter lower_limit = 430;
	        parameter button_lower_limit = 153;
	        parameter button_upper_limit = 858;
	        parameter upper_threshold = 700;
	        parameter lower_threshold = 200;
	        
	        
		    reg [10:0] char_y;
	        reg [10:0] y_data;
			//always @(sndRec or RST or jstkData)
			reg [10:0] bullet_pos_x;
			reg [10:0] bullet_pos_y;
			//Bullet modelling
			always@ (posedge clk_out)
			begin
		        if(RST == 1'b1)
		        begin
		              bullet_pos_x <= 550;
				      bullet_pos_y <= char_y - 100;
		        end
		        else
		        begin 
		              if(bullet_pos_x == 0)
		              begin
		                      bullet_pos_x =  550;
		              end
		              else if(LED)
		              begin   
		                      bullet_pos_y = char_y;
		                      bullet_pos_x = bullet_pos_x - 1;
		              end
		        end
			end
			
			//Character Movement 
			always@ (posedge clk_out)
			begin
		        if(RST == 1'b1)
				begin
			        //LED <= 3'b000;
			        LED <= 8'b00000000;
					y_data <= {2'b00,LED};
					char_y <= upper_limit;
					
				end
				else begin
				    LED <= {jstkData[1], {jstkData[2], jstkData[0]}};
				    y_data <= {{1'b0},jstkData[25:24], jstkData[39:32]};
	                if (y_data > upper_threshold)   
	                begin
	                    if(char_y > upper_limit)
	                    begin
	                        char_y <= char_y - 1;
	                    end   
	                end
	                        
	                else if (y_data < lower_threshold)
	                begin
	                    if(char_y < lower_limit)
	                    begin
	                        char_y <= char_y + 1;
	                    end
	                end
			     end
			end
			

			vga_top vga(.CLK100MHZ (CLK),
			            .char_pos_y (char_y),
			            .bullet_pos_y(bullet_pos_y),
			            .bullet_pos_x(bullet_pos_x),
			            //.character_pos_y (y_data),
			            //.character_pos_y ({jstkData[25:24], jstkData[39:32]}),
			            .rst(RST),
			            .VGA_R (VGA_R),
			            .VGA_G (VGA_G),
			            .VGA_B (VGA_B), 
			            .VGA_HS(VGA_HS),
			            .VGA_VS (VGA_VS) 
			);
			
			

endmodule
