`timescale 1ns / 1ps
// Generate HS, VS signals from pixel clock.
// hcounter & vcounter are the index of the current pixel
// origin (0, 0) at top-left corner of the screen
// valid display range for hcounter: [0, 640)
// valid display range for vcounter: [0, 480)

//`define RE720


module vga_controller_640_60 (pixel_clk, HS, VS, hcounter, vcounter, blank);
     input pixel_clk;
     output HS, VS, blank;
     output [10:0] hcounter, vcounter;
     parameter HMAX = 800; // maximum value for the horizontal pixel counter
     parameter VMAX = 525; // maximum value for the vertical pixel counter
     parameter HLINES = 640; // total number of visible columns
     parameter HFP = 648; // value for the horizontal counter where front porch ends
     parameter HSP = 744; // value for the horizontal counter where the synch pulse ends
     parameter VLINES = 480; // total number of visible lines
     parameter VFP = 482; // value for the vertical counter where the front porch ends
     parameter VSP = 484; // value for the vertical counter where the synch pulse ends
     parameter SPP = 0;
     wire video_enable;
     reg HS,VS,blank;
     reg [10:0] hcounter,vcounter;
 
     always@(posedge pixel_clk) begin
        blank <= ~video_enable;
     end
     
     always@(posedge pixel_clk)begin
         if (hcounter == HMAX) hcounter <= 0;
         else hcounter <= hcounter + 1;
     end
     always@(posedge pixel_clk)begin
         if(hcounter == HMAX) begin
             if(vcounter == VMAX) vcounter <= 0;
             else vcounter <= vcounter + 1;
         end
     end
     always@(posedge pixel_clk)begin
         if(hcounter >= HFP && hcounter < HSP) HS <= SPP;
         else HS <= ~SPP;
     end    
     always@(posedge pixel_clk)begin
         if(vcounter >= VFP && vcounter < VSP) VS <= SPP;
         else VS <= ~SPP;
     end
     
     assign video_enable = (hcounter < HLINES && vcounter < VLINES) ? 1'b1 : 1'b0;
endmodule

module ascii_converter (input [3:0] inp, output reg [6:0] asc_val);
    always @(*) begin
        case (inp)
            4'b0000: asc_val = 7'd48;
            4'b0001: asc_val = 7'd49;
            4'b0010: asc_val = 7'd50;
            4'b0011: asc_val = 7'd51;
            4'b0100: asc_val = 7'd52;
            4'b0101: asc_val = 7'd53;
            4'b0110: asc_val = 7'd54;
            4'b0111: asc_val = 7'd55;
            4'b1000: asc_val = 7'd56;
            4'b1001: asc_val = 7'd57;
            4'b1010: asc_val = 7'd65;
            4'b1011: asc_val = 7'd66;
            4'b1100: asc_val = 7'd67;
            4'b1101: asc_val = 7'd68;
            4'b1110: asc_val = 7'd69;
            4'b1111: asc_val = 7'd70;
        endcase
    end
endmodule


// top module that instantiates the VGA controller and generates images
module vga_top(
     input [VGA_VAL_SIZE-1:0] char_pos_y,
     input [NUM_BULLETS*VGA_VAL_SIZE-1:0] bullet_pos_x,
     input [NUM_BULLETS*VGA_VAL_SIZE-1:0] bullet_pos_y,
     input [10-1:0] bullet_en,
     input wire CLK100MHZ,
     input rst,
     output reg [3:0] VGA_R,
     output reg [3:0] VGA_G,
     output reg [3:0] VGA_B,
     output wire VGA_HS,
     output wire VGA_VS
 );
    parameter GAME_SCENE = 0;
    parameter GAME_OVER_SCENE = 1;
    reg scene;
    
    parameter VGA_VAL_SIZE = 11;
    
    reg pclk_div_cnt;
    reg pixel_clk_reg;
    wire [VGA_VAL_SIZE-1:0] vga_hcnt, vga_vcnt;
    wire vga_blank;
    wire pixel_clk;
    
    // timer 
    parameter dig_W = 8;
    parameter dig_H = 16;
    
    reg[5:0] display_time_val = 6'd59;
    reg[3:0] dec_digit;
    
    reg[10:0] d0_pos_x = 40;
    reg[10:0] d0_pos_y = 20;
    reg[10:0] d1_pos_x = 30;
    reg[10:0] d1_pos_y = 20;
    
    wire [6:0] ascii_val;
    reg [3:0] row_id;
    reg [3:0] col_id;
    wire [7:0] digit_pixel_data;
    
    wire timer_clk;
    timer_clk_generator tcg (.CLK100MHZ (CLK100MHZ), .out_clk(timer_clk));
   
    always@(posedge timer_clk, posedge rst) begin
        if (rst) begin
            display_time_val <= 60;
            scene <= GAME_SCENE;
        end
        else begin
            scene <= GAME_SCENE;
            case (display_time_val)
                0: scene <= GAME_OVER_SCENE;
                default: display_time_val <= display_time_val-1;
            endcase
        end
    end
    
    font_rom fr (pixel_clk, {ascii_val, row_id}, digit_pixel_data);
    ascii_converter (dec_digit, ascii_val);
    
    
    // character
    reg[VGA_VAL_SIZE-1:0] char_pos_x = 550;
    
    parameter char_w = 40;
    parameter char_h = 44;
    parameter char_start_addr = 0;
    
    
    // balloons    
    parameter balloon_w = 18;
    parameter balloon_h = 24;
    parameter balloon_start_addr = char_start_addr + char_w*char_h ;
    parameter balloon2_start_addr = balloon_start_addr + balloon_w*balloon_h ;
    reg [11:0] balloon_addr_reg;
    
    parameter NUM_BULLETS = 10;
    
    wire [VGA_VAL_SIZE-1:0] balloon_x [2:0];
    wire [VGA_VAL_SIZE-1:0] balloon_y [2:0]; 
    reg  [VGA_VAL_SIZE-1:0] min [2:0]; 
    wire [2:0] b_en;
    
    wire frame_end;
    assign frame_end = (vga_hcnt == 0 && vga_vcnt == 0) ;
    
    balloon #(.START(4),.NUM_BULLETS(NUM_BULLETS)) b1 (.rst(rst), .clk(pixel_clk), .frame_end(frame_end), .min(min[0]), .x(balloon_x[0]), .y(balloon_y[0]), .bullet_x(bullet_pos_x), .bullet_y(bullet_pos_y), .en(b_en[0]));
    balloon #(.START(150),.NUM_BULLETS(NUM_BULLETS)) b2 (.rst(rst), .clk(pixel_clk), .frame_end(frame_end), .min(min[1]), .x(balloon_x[1]), .y(balloon_y[1]), .bullet_x(bullet_pos_x), .bullet_y(bullet_pos_y), .en(b_en[1]));
    balloon #(.START(400),.NUM_BULLETS(NUM_BULLETS)) b3 (.rst(rst), .clk(pixel_clk), .frame_end(frame_end), .min(min[2]), .x(balloon_x[2]), .y(balloon_y[2]), .bullet_x(bullet_pos_x), .bullet_y(bullet_pos_y), .en(b_en[2]));
    
    always@(*) begin
        min[0] <= 40;
        min[1] <= 200;
        min[2] <= 400;
    end
    
    reg [15:0] balloon_clk;
    reg balloon_anim;
    always @(posedge CLK100MHZ) begin
         balloon_clk <= balloon_clk + 1;
         if (balloon_clk == 16'd60000) begin
            balloon_clk <= 0;
            balloon_anim <= !balloon_anim;
         end
    end
    
    always @* begin
        case (balloon_anim)
            1: balloon_addr_reg = balloon_start_addr;
            0: balloon_addr_reg = balloon2_start_addr;
        endcase
    end
    
    
    // bullet
//    reg [VGA_VAL_SIZE-1:0] bullet_x [2:0];
//    reg [VGA_VAL_SIZE-1:0] bullet_y [2:0];
//    reg bullet_en_r [NUM_BULLETS-1:0];
//    always@(*) begin
//        bullet_x[0] <= bullet_pos_x;
//        bullet_x[1] <= 10;
//        bullet_x[2] <= 10;
//        bullet_y[0] <= bullet_pos_y;
//        bullet_y[1] <= 400;
//        bullet_y[2] <= 410;
//        bullet_en_r[0] <= bullet_en;
//    end
    parameter bullet_w = 8;
    parameter bullet_h = 3;
    parameter bullet_start_addr = balloon2_start_addr +  balloon_w*balloon_h ;

    // game over image
    parameter gameover_w = 150;
    parameter gameover_h = 22;
    parameter gameover_x = 220;
    parameter gameover_y = 100;
    parameter gameover_start_addr = bullet_start_addr +  bullet_w*bullet_h;

    // bram
    reg[15:0] bram_addr;
    wire[11:0] pixel_data;
    block_ram bram (.clk (pixel_clk), .addr (bram_addr), .dout (pixel_data));
    
    integer i;

   `ifdef RE720 
   clk_wiz_0 clk_div_74
   (
        .clk_out1(pixel_clk), 
        .clk_in1(CLK100MHZ)
    );
    `else
    // Clock divider. Generate 25MHz pixel_clk from 100MHz clock.
    always @(posedge CLK100MHZ) begin
         pclk_div_cnt <= !pclk_div_cnt;
         if (pclk_div_cnt == 1'b1) pixel_clk_reg <= !pixel_clk_reg;
    end
    
    assign pixel_clk = pixel_clk_reg;
    
    `endif
    

    
`ifdef RE720    
    // Instantiate VGA controller
    vga_controller_720_60 vga_controller(
     .pixel_clk(pixel_clk),
     .HS(VGA_HS),
     .VS(VGA_VS),
     .hcounter(vga_hcnt),
     .vcounter(vga_vcnt),
     .blank(vga_blank)
    );
`else
    // Instantiate VGA controller
    vga_controller_640_60 vga_controller(
     .pixel_clk(pixel_clk),
     .HS(VGA_HS),
     .VS(VGA_VS),
     .hcounter(vga_hcnt),
     .vcounter(vga_vcnt),
     .blank(vga_blank)
    );
`endif
    integer j;
    // Generate figure to be displayed
    // Decide the color for the current pixel at index (hcnt, vcnt).
    // This example displays an white square at the center of the screen with a colored checkerboard background.
    always @(*) begin
         // Set pixels to black during Sync. Failure to do so will result in dimmed colors or black screens.
         if (vga_blank) begin
             VGA_R <= 4'h0;
             VGA_G <= 4'h0;
             VGA_B <= 4'h0;
         end
        // Image to be displayed
         else if (scene == GAME_SCENE) begin
//         else begin
            if ((vga_hcnt >= char_pos_x && vga_hcnt < (char_pos_x + char_w)) &&
                (vga_vcnt >= char_pos_y && vga_vcnt < (char_pos_y + char_h))) begin                
                bram_addr <= char_start_addr + (((vga_vcnt - char_pos_y )*char_w) + (vga_hcnt - char_pos_x)); 
                VGA_R <= pixel_data[11:8];
                VGA_G <= pixel_data[7:4];
                VGA_B <= pixel_data[3:0];
            end
            else begin
                VGA_R <= 4'h0;
                VGA_G <= 4'h0;
                VGA_B <= 4'h0;
            end
                 

            for (i=0; i<3; i=i+1) begin
                if ( b_en[i] && ((vga_hcnt >= balloon_x[i] && vga_hcnt < (balloon_x[i] + balloon_w)) &&
                    (vga_vcnt >= balloon_y[i] && vga_vcnt < (balloon_y[i] + balloon_h)))) begin                
                          bram_addr <= balloon_addr_reg + (((vga_vcnt - balloon_y[i])*balloon_w) + (vga_hcnt - balloon_x[i])); 
                          VGA_R <= pixel_data[11:8];
                          VGA_G <= pixel_data[7:4];
                          VGA_B <= pixel_data[3:0];
                end
            end
            
            
//            generate
            for (i=0; i<NUM_BULLETS; i=i+1) begin  // 3 bullets for now
                if ( bullet_en[i] && vga_hcnt >= ((bullet_pos_x>>(11*i))& 11'h7ff) && vga_hcnt < (((bullet_pos_x>>(11*i)) & 11'h7ff) + bullet_w) &&
                    vga_vcnt >= ((bullet_pos_y>>(11*i)) & 11'h7ff) && vga_vcnt < ((bullet_pos_y>>(11*i)) & 11'h7ff) + bullet_h ) begin                
                          bram_addr <= bullet_start_addr + (((vga_vcnt - ((bullet_pos_y>>(11*i)) & 11'h7ff) - 1)*bullet_w) + (vga_hcnt - ((bullet_pos_x>>(11*i)) & 11'h7ff))); 
                          VGA_R <= pixel_data[11:8];
                          VGA_G <= pixel_data[7:4];
                          VGA_B <= pixel_data[3:0];
                end
            end
//            endgenerate
//        end

            // timer digit 0
           if ((vga_hcnt >= d0_pos_x && vga_hcnt <= (d0_pos_x + dig_W) ) &&
             (vga_vcnt >= d0_pos_y && vga_vcnt <= d0_pos_y + dig_H)) begin
                 dec_digit <= display_time_val % 10;
                 row_id <= (vga_vcnt - d0_pos_y);
                 col_id <= dig_W - (vga_hcnt - d0_pos_x); 
                 
                 case (digit_pixel_data[col_id])       
                    0: begin           
                        VGA_R <= 4'h0;
                        VGA_G <= 4'h0;
                        VGA_B <= 4'h0;
                        end
                    1: begin           
                        VGA_R <= 4'hf;
                        VGA_G <= 4'hf;
                        VGA_B <= 4'hf;
                        end
                 endcase             
            end
            // timer digit 1
            else if ((vga_hcnt >= d1_pos_x && vga_hcnt <= (d1_pos_x + dig_W) ) &&
             (vga_vcnt >= d1_pos_y && vga_vcnt <= d1_pos_y + dig_H)) begin

                 dec_digit <= (display_time_val/10) % 10;
                 row_id <= (vga_vcnt - d1_pos_y);
                 col_id <= dig_W - (vga_hcnt - d1_pos_x); 
                 
                 case (digit_pixel_data[col_id])       
                    0: begin           
                        VGA_R <= 4'h0;
                        VGA_G <= 4'h0;
                        VGA_B <= 4'h0;
                        end
                    1: begin           
                        VGA_R <= 4'hf;
                        VGA_G <= 4'hf;
                        VGA_B <= 4'hf;
                        end
                 endcase             
            end
        end
        else begin // scene == game over scene
            if ((vga_hcnt >= gameover_x && vga_hcnt < (gameover_x + gameover_w)) &&
                (vga_vcnt >= gameover_y && vga_vcnt < (gameover_y + gameover_h))) begin                
                  bram_addr <= gameover_start_addr + (((vga_vcnt - gameover_y)*gameover_w) + (vga_hcnt - gameover_x)); 
                  VGA_R <= pixel_data[11:8];
                  VGA_G <= pixel_data[7:4];
                  VGA_B <= pixel_data[3:0];
            end
            else begin
                VGA_R <= 4'h0;
                VGA_G <= 4'h0;
                VGA_B <= 4'h0;
            end
        end         
        
    end
    
endmodule