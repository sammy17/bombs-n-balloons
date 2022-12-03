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
    parameter NUM_BULLETS = 10;
    parameter NUM_BALLOONS = 5;
    parameter NUM_BOMBS = 4;
    
    reg pclk_div_cnt;
    reg pixel_clk_reg;
    wire [VGA_VAL_SIZE-1:0] vga_hcnt, vga_vcnt;
    wire vga_blank;
    wire pixel_clk;
    
    // top bar
    reg[VGA_VAL_SIZE-1:0] top_bar_w = 640;
    reg[VGA_VAL_SIZE-1:0] top_bar_h = 40;
    reg[11:0] top_color = 12'h000;
    
    // timer 
    parameter dig_W = 8;
    parameter dig_H = 16;
    
    reg[5:0] display_time_val = 6'd59;
    reg[3:0] dec_digit;
    
    reg[10:0] d0_pos_x = 40;
    reg[10:0] d0_pos_y = 15;
    reg[10:0] d1_pos_x = 30;
    reg[10:0] d1_pos_y = 15;
    
    wire [6:0] ascii_val;
    reg [3:0] row_id;
    reg [3:0] col_id;
    wire [7:0] digit_pixel_data;
    
    wire timer_clk;
    reg [5:0] timer_counter;
    wire [NUM_BOMBS-1:0] game_over_r;
    timer_clk_generator tcg (.CLK100MHZ (CLK100MHZ), .out_clk(timer_clk));
    
    always@(posedge timer_clk) begin
        if (rst) 
            timer_counter <= 0;
        else 
            timer_counter <= timer_counter + 6'd1;
    end
   
    always@(posedge timer_clk, posedge rst) begin
        if (rst) begin
            display_time_val <= 60;
            scene <= GAME_SCENE;
        end
        else if (|game_over_r) begin
            scene <= GAME_OVER_SCENE;
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
    
    // score digits
//    reg[5:0] score = 6'd36;
    
    wire[10:0] sc_d0_pos_x[1:0];
    wire[10:0] sc_d0_pos_y[1:0];
    wire[10:0] sc_d1_pos_x[1:0];
    wire[10:0] sc_d1_pos_y[1:0];
    
    assign sc_d0_pos_x[GAME_SCENE] = 610; assign sc_d0_pos_x[GAME_OVER_SCENE] = 330;
    assign sc_d1_pos_x[GAME_SCENE] = 600; assign sc_d1_pos_x[GAME_OVER_SCENE] = 320;    
    assign sc_d0_pos_y[GAME_SCENE] = 15; assign sc_d0_pos_y[GAME_OVER_SCENE] = 135;
    assign sc_d1_pos_y[GAME_SCENE] = 15; assign sc_d1_pos_y[GAME_OVER_SCENE] = 135;
    
    // SCORE
    wire[6:0] score_ascii_vals [5:0];
    assign score_ascii_vals[0] = 83;
    assign score_ascii_vals[1] = 67;
    assign score_ascii_vals[2] = 79;
    assign score_ascii_vals[3] = 82;
    assign score_ascii_vals[4] = 69;
    assign score_ascii_vals[5] = 58;
    
    wire[10:0] score_pos_x_start[1:0];
    wire[10:0] score_pos_y[1:0];
    
    assign score_pos_x_start[GAME_SCENE] = 540; assign score_pos_x_start[GAME_OVER_SCENE] = 260;
    assign score_pos_y[GAME_SCENE] = 15; assign score_pos_y[GAME_OVER_SCENE] = 135;    
    
    reg [6:0] ascii_val_txt_reg;
    wire [6:0] ascii_val_txt;
    assign ascii_val_txt = ascii_val_txt_reg;
    wire [7:0] txt_pixel_data;
    font_rom fr_txt (pixel_clk, {ascii_val_txt, row_id}, txt_pixel_data);
    
    // character
    reg[VGA_VAL_SIZE-1:0] char_pos_x = 550;
    
    parameter char_w = 40;
    parameter char_h = 44;
    
    parameter char_1_addr = 0;
    parameter char_2_addr = char_w * char_h;
    
    reg[15:0] char_start_addr;
    
    
    // balloons    
    parameter balloon_w = 18;
    parameter balloon_h = 24;
    parameter balloon_start_addr = char_2_addr + char_w*char_h ;
    parameter balloon2_start_addr = balloon_start_addr + balloon_w*balloon_h ;
    reg [15:0] balloon_addr_reg;
    

    
    wire [VGA_VAL_SIZE-1:0] balloon_x [NUM_BALLOONS-1:0];
    wire [VGA_VAL_SIZE-1:0] balloon_y [NUM_BALLOONS-1:0]; 
    wire [VGA_VAL_SIZE-1:0] bomb_x [NUM_BOMBS-1:0];
    wire [VGA_VAL_SIZE-1:0] bomb_y [NUM_BOMBS-1:0]; 
    reg  [VGA_VAL_SIZE-1:0] min [NUM_BALLOONS-1:0]; 
    wire [NUM_BALLOONS-1:0] b_en;
    wire [NUM_BOMBS-1:0] bo_en;
    wire [VGA_VAL_SIZE*NUM_BOMBS-1:0] bomb_x_all;
    wire [VGA_VAL_SIZE*NUM_BOMBS-1:0] bomb_y_all;
    reg  [9:0] score;
    wire score_detect;
    wire [NUM_BALLOONS:0] score_detect_temp;
//    wire [NUM_BOMBS:0] blast_detect_temp;
    
    assign score_detect_temp[0] = 0;
//    assign blast_detect_temp[0] = 0;
    
    wire frame_end;
    assign frame_end = (vga_hcnt == 0 && vga_vcnt == 0) ;
    
    genvar m ;
    generate
//    always@(*) begin
        for (m=0; m<NUM_BOMBS; m=m+1) begin
            assign bomb_x_all[VGA_VAL_SIZE*(m+1)-1:VGA_VAL_SIZE*m] = bomb_x[m];
            assign bomb_y_all[VGA_VAL_SIZE*(m+1)-1:VGA_VAL_SIZE*m] = bomb_y[m];
        end
//    end
    endgenerate
//    assign bomb_x_all = {{bomb_x}};

    localparam TADJUST = 1_000_000/(40*480);
    
    genvar k;
    generate
        for (k=0; k<NUM_BALLOONS; k=k+1) begin : balloon
            balloon #(.START(50*k+k*k+5),.NUM_BULLETS(NUM_BULLETS), .NUM_BOMBS(NUM_BOMBS)) b1 (.rst(rst), .clk(pixel_clk), .frame_end(frame_end), .x(balloon_x[k]), .y(balloon_y[k]), .bullet_x(bullet_pos_x), .bullet_y(bullet_pos_y), .bomb_x(bomb_x_all), .bomb_y(bomb_y_all), .en(b_en[k]));
//            balloon #(.START(150),.NUM_BULLETS(NUM_BULLETS)) b2 (.rst(rst), .clk(pixel_clk), .frame_end(frame_end), .x(balloon_x[1]), .y(balloon_y[1]), .bullet_x(bullet_pos_x), .bullet_y(bullet_pos_y), .en(b_en[1]));
//            balloon #(.START(400),.NUM_BULLETS(NUM_BULLETS)) b3 (.rst(rst), .clk(pixel_clk), .frame_end(frame_end), .x(balloon_x[2]), .y(balloon_y[2]), .bullet_x(bullet_pos_x), .bullet_y(bullet_pos_y), .en(b_en[2]));
//            balloon #(.START(500),.NUM_BULLETS(NUM_BULLETS)) b4 (.rst(rst), .clk(pixel_clk), .frame_end(frame_end), .x(balloon_x[3]), .y(balloon_y[3]), .bullet_x(bullet_pos_x), .bullet_y(bullet_pos_y), .en(b_en[3]));
              assign score_detect_temp[k+1] = score_detect_temp[k] | balloon[k].b1.score_detected;
        end
    endgenerate
    
    genvar l;
    generate
        for (l=0; l<NUM_BOMBS; l=l+1) begin //50*l+l*l+5
            bomb #(.START(TADJUST*(60/NUM_BOMBS)*(l+1)-10),.NUM_BULLETS(NUM_BULLETS)) bomb1 (.rst(rst), .clk(pixel_clk), .frame_end(frame_end), .x(bomb_x[l]), .y(bomb_y[l]), .bullet_x(bullet_pos_x), .bullet_y(bullet_pos_y), .char_y(char_pos_y), .en(bo_en[l]), .game_over(game_over_r[l]));
//            balloon #(.START(150),.NUM_BULLETS(NUM_BULLETS)) b2 (.rst(rst), .clk(pixel_clk), .frame_end(frame_end), .x(balloon_x[1]), .y(balloon_y[1]), .bullet_x(bullet_pos_x), .bullet_y(bullet_pos_y), .en(b_en[1]));
//            balloon #(.START(400),.NUM_BULLETS(NUM_BULLETS)) b3 (.rst(rst), .clk(pixel_clk), .frame_end(frame_end), .x(balloon_x[2]), .y(balloon_y[2]), .bullet_x(bullet_pos_x), .bullet_y(bullet_pos_y), .en(b_en[2]));
//            balloon #(.START(500),.NUM_BULLETS(NUM_BULLETS)) b4 (.rst(rst), .clk(pixel_clk), .frame_end(frame_end), .x(balloon_x[3]), .y(balloon_y[3]), .bullet_x(bullet_pos_x), .bullet_y(bullet_pos_y), .en(b_en[3]));
//            assign blast_detect_temp[l+1] = blast_detect_temp[l] | balloon[k].b1.score_detected;
        end
    endgenerate
    
    assign score_detect = score_detect_temp[NUM_BALLOONS];
    
    parameter SCORE_REDUCTION = 5;
    reg score_reduced;
    
    always@(posedge pixel_clk )begin
        if(rst) begin
            score <= 0;
            score_reduced <= 0;
        end else if(scene == GAME_OVER_SCENE)
            score <= score;
//        else if (~(&bo_en) & ~score_reduced) begin 
//            score_reduced <= 1;
//            if (score>SCORE_REDUCTION)
//                score <= score - SCORE_REDUCTION;
//            else
//                score <= 0;//score - SCORE_REDUCTION;
        else if(score_detect)
            score <= score + 1;
    end
    
//    always@(*) begin
//        min[0] <= 40;
//        min[1] <= 200;
//        min[2] <= 400;
//    end
    
//    reg [15:0] balloon_clk;
//    reg balloon_anim;
//    always @(posedge CLK100MHZ) begin
//         balloon_clk <= balloon_clk + 1;
//         if (balloon_clk == 16'd60000) begin
//            balloon_clk <= 0;
//            balloon_anim <= !balloon_anim;
//         end
//    end
    
//    always @* begin
//        case (balloon_anim)
//            1: balloon_addr_reg = balloon_start_addr;
//            0: balloon_addr_reg = balloon2_start_addr;
//        endcase
//    end
    
    
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

    // bomb
    parameter bomb_w = 16;
    parameter bomb_h = 24;
    parameter bomb_start_addr = gameover_start_addr + gameover_w*gameover_h ;
    parameter bomb2_start_addr = bomb_start_addr + bomb_w*bomb_h ;
    reg [15:0] bomb_addr_reg;
    
//    wire [VGA_VAL_SIZE-1:0] bomb_x = 20; // remove these numbers and wire to a bomb generator 
//    wire [VGA_VAL_SIZE-1:0] bomb_y = 100;

    // brick
    parameter brick_w = 55;
    parameter brick_h = 22;
    parameter brick_start_addr = bomb2_start_addr + bomb_w*bomb_h;
    
    wire [9:0] brick_x[11:0]; 
    wire [VGA_VAL_SIZE-1:0] brick_y;    

    assign brick_x[0] = 0;
    assign brick_x[1] = 55;
    assign brick_x[2] = 110;
    assign brick_x[3] = 165;
    assign brick_x[4] = 220;
    assign brick_x[5] = 275;
    assign brick_x[6] = 330;
    assign brick_x[7] = 385;
    assign brick_x[8] = 440;
    assign brick_x[9] = 495;
    assign brick_x[10] = 550;
    assign brick_x[11] = 605;
    assign brick_y = 458;

    // blast animations
    parameter balloon_pop_1_addr = brick_start_addr + brick_w*brick_h;
    parameter balloon_pop_2_addr = balloon_pop_1_addr + balloon_w*balloon_h;
    wire [15:0] balloon_pop_anim_reg [1:0];
    assign balloon_pop_anim_reg[0] = balloon_pop_1_addr;
    assign balloon_pop_anim_reg[1] = balloon_pop_2_addr;
    reg [31:0] balloon_pop_counter [NUM_BALLOONS-1:0];
  
    parameter IDLE = 0;
    parameter BLAST_1 = 1;
    parameter BLAST_2 = 2;
    reg [1:0] pop_state [NUM_BALLOONS-1:0];    
    genvar b;
    generate
    for (b=0; b<NUM_BALLOONS; b=b+1) begin
        always @(posedge pixel_clk) begin // change this clock
            if (rst) begin
                pop_state[b] = 0;
                balloon_pop_counter[b] = 0;
            end else begin
                case (pop_state[b])
                     IDLE:begin
                           balloon_pop_counter[b] = 0;
                          if (balloon[b].b1.score_detected) begin
                            pop_state[b] = BLAST_1;
                          end else begin
                            pop_state[b] = IDLE;
                          end
                     end
                     
                     BLAST_1: begin
                         balloon_pop_counter[b] = balloon_pop_counter[b] + 1;
                         if (balloon_pop_counter[b] == 1_000_000) begin
                            pop_state[b] = BLAST_2;
                            balloon_pop_counter[b] = 0;
                         end
                     end
                     BLAST_2: begin
                         balloon_pop_counter[b] = balloon_pop_counter[b] + 1;
                         if (balloon_pop_counter[b] == 1_000_000) begin
                            pop_state[b] = IDLE;
                            balloon_pop_counter[b] = 0;
                         end
                     end
                endcase
            end
        end
    end
    endgenerate

   

    // boom
    parameter boom_start_addr =  balloon_pop_2_addr + balloon_w*balloon_h;
    parameter boom_h = 50;
    parameter boom_w = 50;
    
    wire [VGA_VAL_SIZE-1:0] boom_x; assign boom_x = char_pos_x;
    wire [VGA_VAL_SIZE-1:0] boom_y; assign boom_y = char_pos_y; // change here
 // title
    parameter title_start_addr =  boom_start_addr + boom_w*boom_h;
    parameter title_w = 146;
    parameter title_h = 20;
    
    wire [VGA_VAL_SIZE-1:0] title_x; assign title_x = 220;//585;
    wire [VGA_VAL_SIZE-1:0] title_y; assign title_y = 15;//435;
    // bram
    reg[15:0] bram_addr;
    wire[11:0] pixel_data;
    block_ram bram (.clk (pixel_clk), .addr (bram_addr), .dout (pixel_data));
    
    // balloon and bomb animation
    reg [15:0] anim_clk;
    reg do_anim;
    always @(posedge CLK100MHZ) begin
         anim_clk <= anim_clk + 1;
         if (anim_clk == 16'd40000) begin
            anim_clk <= 0;
            do_anim <= !do_anim;
         end
    end
    
    // balloon and bomb animation 
    always @* begin
        case (do_anim)
            1: begin
            balloon_addr_reg <= balloon_start_addr;
            bomb_addr_reg <= bomb_start_addr;
            char_start_addr <= char_1_addr;
            end
            0: begin
            balloon_addr_reg <= balloon2_start_addr;
            bomb_addr_reg <= bomb2_start_addr;
            char_start_addr <= char_2_addr;
            end
        endcase
    end
    
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
//         else if (scene == GAME_SCENE) begin
        else

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
                 
            // balloons
            for (i=0; i<NUM_BALLOONS; i=i+1) begin
                if (((vga_hcnt >= balloon_x[i] && vga_hcnt < (balloon_x[i] + balloon_w)) &&
                    (vga_vcnt >= balloon_y[i] && vga_vcnt < (balloon_y[i] + balloon_h)))) begin   
                        if ( b_en[i]) begin            
                              bram_addr <= balloon_addr_reg + (((vga_vcnt - balloon_y[i])*balloon_w) + (vga_hcnt - balloon_x[i])); 
                              VGA_R <= pixel_data[11:8];
                              VGA_G <= pixel_data[7:4];
                              VGA_B <= pixel_data[3:0];
                        end
                        else if (!b_en[i] && (pop_state[i]==1 || pop_state[i]==2)) begin
                              bram_addr <= balloon_pop_anim_reg[pop_state[i]-1] + (((vga_vcnt - balloon_y[i])*balloon_w) + (vga_hcnt - balloon_x[i])); 
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
            //bomb
            for (i=0; i<NUM_BOMBS; i=i+1) begin
                if ( (scene==GAME_SCENE) && (vga_hcnt >= bomb_x[i] && vga_hcnt < (bomb_x[i] + bomb_w)) &&
                    (vga_vcnt >= bomb_y[i] && vga_vcnt < (bomb_y[i] + bomb_h))) begin                
                      bram_addr <= bomb_addr_reg + (((vga_vcnt - bomb_y[i])*bomb_w) + (vga_hcnt - bomb_x[i])); 
                      VGA_R <= pixel_data[11:8];
                      VGA_G <= pixel_data[7:4];
                      VGA_B <= pixel_data[3:0];
                end
            end
            // top bar
            if ((vga_hcnt >= 0 && vga_hcnt < (0 + top_bar_w)) &&
                (vga_vcnt >= 0 && vga_vcnt < (0 + top_bar_h))) begin                 
                  VGA_R <= top_color[11:8];
                  VGA_G <= top_color[7:4];
                  VGA_B <= top_color[3:0];
            end
            
            
//            generate
            for (i=0; i<NUM_BULLETS; i=i+1) begin  // 3 bullets for now
                if ( scene==GAME_SCENE & bullet_en[i] && vga_hcnt >= ((bullet_pos_x>>(11*i))& 11'h7ff) && vga_hcnt < (((bullet_pos_x>>(11*i)) & 11'h7ff) + bullet_w) &&
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
                        VGA_R <= top_color[11:8];
                        VGA_G <= top_color[7:4];
                        VGA_B <= top_color[3:0];
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
                        VGA_R <= top_color[11:8];
                        VGA_G <= top_color[7:4];
                        VGA_B <= top_color[3:0];
                        end
                    1: begin           
                        VGA_R <= 4'hf;
                        VGA_G <= 4'hf;
                        VGA_B <= 4'hf;
                        end
                 endcase             
            end
            
            //score digits
            // score digit 0
           if ((vga_hcnt >= sc_d0_pos_x[GAME_SCENE] && vga_hcnt < (sc_d0_pos_x[GAME_SCENE] + dig_W) ) &&
             (vga_vcnt >= sc_d0_pos_y[GAME_SCENE] && vga_vcnt < sc_d0_pos_y[GAME_SCENE] + dig_H)) begin
                 dec_digit <= score % 10;
                 row_id <= (vga_vcnt - sc_d0_pos_y[GAME_SCENE]);
                 col_id <= dig_W - (vga_hcnt - sc_d0_pos_x[GAME_SCENE]); 
                 
                 case (digit_pixel_data[col_id])       
                    0: begin           
                        VGA_R <= top_color[11:8];
                        VGA_G <= top_color[7:4];
                        VGA_B <= top_color[3:0];
                        end
                    1: begin           
                        VGA_R <= 4'hf;
                        VGA_G <= 4'hf;
                        VGA_B <= 4'hf;
                        end
                 endcase             
            end
            // score digit 1
            else if ((vga_hcnt >= sc_d1_pos_x[GAME_SCENE] && vga_hcnt < (sc_d1_pos_x[GAME_SCENE] + dig_W) ) &&
             (vga_vcnt >= sc_d1_pos_y[GAME_SCENE] && vga_vcnt < sc_d1_pos_y[GAME_SCENE] + dig_H)) begin

                 dec_digit <= (score/10) % 10;
                 row_id <= (vga_vcnt - sc_d1_pos_y[GAME_SCENE]);
                 col_id <= dig_W - (vga_hcnt - sc_d1_pos_x[GAME_SCENE]); 
                 
                 case (digit_pixel_data[col_id])       
                    0: begin           
                        VGA_R <= top_color[11:8];
                        VGA_G <= top_color[7:4];
                        VGA_B <= top_color[3:0];
                        end
                    1: begin           
                        VGA_R <= 4'hf;
                        VGA_G <= 4'hf;
                        VGA_B <= 4'hf;
                        end
                 endcase             
            end
            
            //score
            for (i=0; i<6; i=i+1) begin
                if ((vga_hcnt >= score_pos_x_start[GAME_SCENE] + i*10 && vga_hcnt < (score_pos_x_start[GAME_SCENE] + i*10 + dig_W) ) &&
                 (vga_vcnt >= score_pos_y[GAME_SCENE] && vga_vcnt < score_pos_y[GAME_SCENE] + dig_H)) begin
                     ascii_val_txt_reg <= score_ascii_vals[i];
                     row_id <= (vga_vcnt - score_pos_y[GAME_SCENE]);
                     col_id <= dig_W - (vga_hcnt - (score_pos_x_start[GAME_SCENE] + i*10));                     
                     case (txt_pixel_data[col_id])       
                        0: begin           
                            VGA_R <= top_color[11:8];
                            VGA_G <= top_color[7:4];
                            VGA_B <= top_color[3:0];
                            end
                        1: begin           
                            VGA_R <= 4'hf;
                            VGA_G <= 4'hf;
                            VGA_B <= 4'hf;
                            end
                     endcase             
                end
            end
            

            
            //bricks
            for (i=0; i<12; i=i+1) begin
                if ((vga_hcnt >= brick_x[i] && vga_hcnt < (brick_x[i] + brick_w) &&
                    (vga_vcnt >= brick_y && vga_vcnt < (brick_y + brick_h)))) begin                
                          bram_addr <= brick_start_addr + (((vga_vcnt - brick_y)*brick_w) + (vga_hcnt - brick_x[i])); 
                          VGA_R <= pixel_data[11:8];
                          VGA_G <= pixel_data[7:4];
                          VGA_B <= pixel_data[3:0];
                end
            end
            
            //title
            if ((vga_hcnt >= title_x && vga_hcnt < (title_x + title_w)) &&
                (vga_vcnt >= title_y && vga_vcnt < (title_y + title_h))) begin                 
                  bram_addr <= title_start_addr + (((vga_vcnt - title_y)*title_w) + (vga_hcnt - title_x)); 
                  VGA_R <= pixel_data[11:8];
                  VGA_G <= pixel_data[7:4];
                  VGA_B <= pixel_data[3:0];
            end


//        end
        ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if (scene == GAME_OVER_SCENE) begin // scene == game over scene
            if ((vga_hcnt >= gameover_x && vga_hcnt < (gameover_x + gameover_w)) &&
                (vga_vcnt >= gameover_y && vga_vcnt < (gameover_y + gameover_h))) begin                
                  bram_addr <= gameover_start_addr + (((vga_vcnt - gameover_y)*gameover_w) + (vga_hcnt - gameover_x)); 
                  VGA_R <= pixel_data[11:8];
                  VGA_G <= pixel_data[7:4];
                  VGA_B <= pixel_data[3:0];
            end
            
            //boom!!
            if ( (|game_over_r) & (vga_hcnt >= boom_x && vga_hcnt < (boom_x + boom_w)) &&
                (vga_vcnt >= boom_y && vga_vcnt < (boom_y + boom_h))) begin                 
                  bram_addr <= boom_start_addr + (((vga_vcnt - boom_y)*boom_w) + (vga_hcnt - boom_x)); 
                  VGA_R <= pixel_data[11:8];
                  VGA_G <= pixel_data[7:4];
                  VGA_B <= pixel_data[3:0];
            end
            

//            else begin
//                VGA_R <= 4'h0;
//                VGA_G <= 4'h0;
//                VGA_B <= 4'h0;
//            end
             //score digits
            // score digit 0
           if ((vga_hcnt >= sc_d0_pos_x[GAME_OVER_SCENE] && vga_hcnt < (sc_d0_pos_x[GAME_OVER_SCENE] + dig_W) ) &&
             (vga_vcnt >= sc_d0_pos_y[GAME_OVER_SCENE] && vga_vcnt < sc_d0_pos_y[GAME_OVER_SCENE] + dig_H)) begin
                 dec_digit <= score % 10;
                 row_id <= (vga_vcnt - sc_d0_pos_y[GAME_OVER_SCENE]);
                 col_id <= dig_W - (vga_hcnt - sc_d0_pos_x[GAME_OVER_SCENE]); 
                 
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
            // score digit 1
            else if ( (vga_hcnt >= sc_d1_pos_x[GAME_OVER_SCENE] && vga_hcnt < (sc_d1_pos_x[GAME_OVER_SCENE] + dig_W) ) &&
             (vga_vcnt >= sc_d1_pos_y[GAME_OVER_SCENE] && vga_vcnt < sc_d1_pos_y[GAME_OVER_SCENE] + dig_H)) begin

                 dec_digit <= (score/10) % 10;
                 row_id <= (vga_vcnt - sc_d1_pos_y[GAME_OVER_SCENE]);
                 col_id <= dig_W - (vga_hcnt - sc_d1_pos_x[GAME_OVER_SCENE]); 
                 
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
            
            //score
            for (i=0; i<6; i=i+1) begin
                if ((vga_hcnt >= score_pos_x_start[GAME_OVER_SCENE] + i*10 && vga_hcnt < (score_pos_x_start[GAME_OVER_SCENE] + i*10 + dig_W) ) &&
                 (vga_vcnt >= score_pos_y[GAME_OVER_SCENE] && vga_vcnt < score_pos_y[GAME_OVER_SCENE] + dig_H)) begin
                     ascii_val_txt_reg <= score_ascii_vals[i];
                     row_id <= (vga_vcnt - score_pos_y[GAME_OVER_SCENE]);
                     col_id <= dig_W - (vga_hcnt - (score_pos_x_start[GAME_OVER_SCENE] + i*10));                     
                     case (txt_pixel_data[col_id])       
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
        end         
        
    end
    
endmodule