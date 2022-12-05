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

`define CLOG2(x) \
   (x <= 2) ? 1 : \
   (x <= 4) ? 2 : \
   (x <= 8) ? 3 : \
   (x <= 16) ? 4 : \
   (x <= 32) ? 5 : \
   (x <= 64) ? 6 

//`define NOJSTK

module bombs_and_balloons(
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
`ifdef NOJSTK
    ,button_up
    ,button_down
    ,shoot
`endif
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
`ifdef NOJSTK
            input button_up, button_down, shoot;
`endif
            parameter NUM_BULLETS = 10;
            
             wire slow_clock;
             wire clk_out, clk_out_4;
             													
//			 clk_wiz_0 instance_name // For slowing down the clock
//                            (
//            // Clock out ports
//            .clk_out1(slow_clock),     // output clk_out1
//            // Clock in ports
//            .clk_in1(CLK));
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
			
			
			clock_div slowerClock( .clk_in(CLK), .clk_out(clk_out)); // 100MHz -> 40*4Hz
			clock_div_4 slowerClock4( .clk_in(CLK), .clk_out(clk_out_4)); // 100MHz -> 4Hz
			


			// Data to be sent to PmodJSTK, lower two bits will turn on leds on PmodJSTK
			assign sndData = {8'b100000, {SW[1], SW[2]}};

			// Assign PmodJSTK button status to LED[2:0] & Making the character
		    parameter upper_limit = 40;
	        parameter lower_limit = 430-44;
	        parameter button_lower_limit = 153;
	        parameter button_upper_limit = 858;
	        parameter upper_threshold = 700;//458-44;//700; 
	        parameter lower_threshold = 200;//40;//200;
	        
	        
		    reg [10:0] char_y;
	        reg [10:0] y_data;
			//always @(sndRec or RST or jstkData)
			reg [11*NUM_BULLETS-1:0] bullet_pos_x;
			reg [11*NUM_BULLETS-1:0] bullet_pos_y;
			reg bullet_done;
			reg [10-1:0] bullet_en;
			reg [4-1:0] b_idx; // ideally this should only be log2(num_bullets) size reg
			wire shoot_r;
			

			// Use state of switch 0 to select output of X position or Y position data to SSD
			assign posData = (SW[1]==1) ? vga.score : (SW[0] == 1'b1) ? {jstkData[9:8], jstkData[23:16]} : {jstkData[25:24], jstkData[39:32]};
			
`ifdef NOJSTK


            debouncer debouncer(.clk(clk_out), .in(shoot), .out(shoot_r));

            always@(posedge clk_out) begin
                if(RST == 1'b1)
                    b_idx <= 0;
                else if (b_idx==NUM_BULLETS)
                    b_idx <= 0;
                else if (shoot_r)
                    b_idx <= b_idx + 1;
            end

            genvar i;
            generate
                for ( i=0; i<NUM_BULLETS; i=i+1 ) begin
                    always@ (posedge clk_out) begin
                        if(RST == 1'b1)
                        begin
                              bullet_pos_x[((i+1)*11)-1:i*11] <= 550;
                              bullet_pos_y[((i+1)*11)-1:i*11] <= char_y + 50 ;//- 100;
        //				      bullet_done <= 0;
                              bullet_en[i] <= 0;
                        end
                        else if (vga.scene==1) begin
                              bullet_en[i] <= 0;
                              bullet_pos_x[((i+1)*11)-1:i*11] <= bullet_pos_x[((i+1)*11)-1:i*11];
                              bullet_pos_y[((i+1)*11)-1:i*11] <= bullet_pos_y[((i+1)*11)-1:i*11];
                        end
                        else if (bullet_pos_x[((i+1)*11)-1:i*11]==0) begin
        //		              bullet_done <= 1;
                              bullet_en[i] <= 0;
                              bullet_pos_x[((i+1)*11)-1:i*11] <= 1;
                              bullet_pos_y[((i+1)*11)-1:i*11] <= bullet_pos_y[((i+1)*11)-1:i*11];
                        end
                        else if (bullet_en[i]) begin
        //		              bullet_done <= 0;
                              bullet_en[i] <= 1;
                              bullet_pos_x[((i+1)*11)-1:i*11] <= bullet_pos_x[((i+1)*11)-1:i*11] - 1;
                              bullet_pos_y[((i+1)*11)-1:i*11] <= bullet_pos_y[((i+1)*11)-1:i*11];
                        end
                        else if (shoot_r) begin
        //		              bullet_done <= 0;
                              if (~bullet_en[i]) begin // Only set the bullet enable if it's not enable
                                bullet_en[i] <= (b_idx==i);
                              end
                              bullet_pos_x[((i+1)*11)-1:i*11] <= 550;
                              bullet_pos_y[((i+1)*11)-1:i*11] <= char_y + 15;
                        end
                        else begin
        //		              bullet_done <= 0;
                              bullet_en[i] <= bullet_en[i];
                              bullet_pos_x[((i+1)*11)-1:i*11] <= bullet_pos_x[((i+1)*11)-1:i*11];
                              bullet_pos_y[((i+1)*11)-1:i*11] <= bullet_pos_y[((i+1)*11)-1:i*11];
                        end
                    end
                end
            endgenerate
            



`else
			//Bullet modelling
//			always@ (posedge clk_out)
//			begin
//		        if(RST == 1'b1)
//		        begin
//		              bullet_pos_x <= 550;
//				      bullet_pos_y <= char_y + 15 ;//- 100;
//		        end
//		        else
//		        begin 
//		              if(bullet_pos_x == 0)
//		              begin
//		                      bullet_pos_x <=  550;
//		              end
//		              else if(LED)
//		              begin   
//		                      bullet_pos_y <= char_y+10;
//		                      bullet_pos_x <= bullet_pos_x - 1;
//		              end
//		        end
//			end

            debouncer debouncer(.clk(clk_out), .in(jstkData[1]), .out(shoot_r));
            
//            assign shoot_r = jstkData[1];

            always@(posedge clk_out) begin
                if(RST == 1'b1)
                    b_idx <= 0;
                else if (b_idx==NUM_BULLETS)
                    b_idx <= 0;
                else if (shoot_r)
                    b_idx <= b_idx + 1;
            end

            genvar i;
            generate
                for ( i=0; i<NUM_BULLETS; i=i+1 ) begin
                    always@ (posedge clk_out) begin
                        if(RST == 1'b1)
                        begin
                              bullet_pos_x[((i+1)*11)-1:i*11] <= 550;
                              bullet_pos_y[((i+1)*11)-1:i*11] <= char_y + 50 ;//- 100;
        //				      bullet_done <= 0;
                              bullet_en[i] <= 0;
                        end
                        else if (vga.scene==1) begin
                              bullet_en[i] <= 0;
                              bullet_pos_x[((i+1)*11)-1:i*11] <= bullet_pos_x[((i+1)*11)-1:i*11];
                              bullet_pos_y[((i+1)*11)-1:i*11] <= bullet_pos_y[((i+1)*11)-1:i*11];
                        end
                        else if (bullet_pos_x[((i+1)*11)-1:i*11]==0) begin
        //		              bullet_done <= 1;
                              bullet_en[i] <= 0;
                              bullet_pos_x[((i+1)*11)-1:i*11] <= 1;
                              bullet_pos_y[((i+1)*11)-1:i*11] <= bullet_pos_y[((i+1)*11)-1:i*11];
                        end
                        else if (bullet_en[i]) begin
        //		              bullet_done <= 0;
                              bullet_en[i] <= 1;
                              bullet_pos_x[((i+1)*11)-1:i*11] <= bullet_pos_x[((i+1)*11)-1:i*11] - 1;
                              bullet_pos_y[((i+1)*11)-1:i*11] <= bullet_pos_y[((i+1)*11)-1:i*11];
                        end
                        else if (shoot_r) begin
        //		              bullet_done <= 0;
                              if (~bullet_en[i]) begin // Only set the bullet enable if it's not enable
                                bullet_en[i] <= (b_idx==i);
                              end
                              bullet_pos_x[((i+1)*11)-1:i*11] <= 550;
                              bullet_pos_y[((i+1)*11)-1:i*11] <= char_y + 15;
                        end
                        else begin
        //		              bullet_done <= 0;
                              bullet_en[i] <= bullet_en[i];
                              bullet_pos_x[((i+1)*11)-1:i*11] <= bullet_pos_x[((i+1)*11)-1:i*11];
                              bullet_pos_y[((i+1)*11)-1:i*11] <= bullet_pos_y[((i+1)*11)-1:i*11];
                        end
                    end
                end
            endgenerate



			
`endif
			
`ifdef NOJSTK

            always@(posedge clk_out) begin
                if (RST)
                    char_y <= upper_limit+200;
                else if (vga.scene==1) // disable moving when Game Over
                    char_y <= char_y;
                else if (button_up && char_y > upper_limit)
                    char_y <= char_y - 1;
                else if (button_down && char_y < lower_limit)
                    char_y <= char_y + 1;
                else 
                    char_y <= char_y;
            end

`else
			//Character Movement 
			always@ (posedge clk_out)
			begin
		        if(RST == 1'b1)
				begin
			        //LED <= 3'b000;
//			        LED <= 8'b00000000;
					y_data <= 10'd0; //{2'b00,LED};
					char_y <= upper_limit+200;
					
				end
				else begin
//				    LED <= {jstkData[1], {jstkData[2], jstkData[0]}};
				    y_data <= {{1'b0},jstkData[25:24], jstkData[39:32]};
				    
				    if (vga.scene==1) // disable moving when Game Over
                        char_y <= char_y;
	                else if (y_data > upper_threshold)   
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
      
`endif

			vga_top #(.NUM_BULLETS(NUM_BULLETS)) vga(.CLK100MHZ (CLK),
			            .char_pos_y (char_y),
			            .bullet_pos_y(bullet_pos_y),
			            .bullet_pos_x(bullet_pos_x),
			            .bullet_en(bullet_en),
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
