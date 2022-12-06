import numpy as np
import cv2


img_dirs = ["char_1.png", "char_2.png", "balloon.png","balloon2.png","bullet.png", "game_over.png",\
            "bomb1.png", "bomb2.png", "brick.png", "balloon_pop_1.png", "balloon_pop_2.png",\
                "boom.png", "title.png"]
im_w = [40, 40, 18, 18, 8, 150, 16, 16, 55, 18, 18, 50, 146]
im_h = [44, 44, 24, 24, 3, 22, 24, 24, 22, 24, 24, 50, 20]
addr = 0


with open('block_ram.v', 'w') as f:
    f.write("`timescale 1ns / 1ps\n\n")
    f.write("module block_ram(clk, addr, dout);\n")
    f.write("\tparameter BLOCK_SIZE = 12; // 4 bit R, 4 bit G, 4 bit B\n")
    f.write("\tparameter ADDR_SIZE = 16;\n")
    f.write("\tinput clk;\n")
    f.write("\tinput [ADDR_SIZE-1:0] addr;\n")
    f.write("\toutput reg [BLOCK_SIZE-1:0] dout;\n\n")
    
    f.write("\talways @* begin\n")
    f.write("\t\tcase(addr)\n")
        
    for k in range (len(img_dirs)): 
        img = cv2.imread(img_dirs[k])
        #print(img.shape)
        img = cv2.resize(img, (im_w[k], im_h[k]), interpolation = cv2.INTER_AREA)
        
        img = np.array(img)
        img = img/16
        img = (img).astype(int)
        
        for i in range (im_h[k]):
            for j in range (im_w[k]):
                f.write("\t\t\t" + str(addr) + ": dout = 12'h" + str(hex(img[i][j][2])[2:]) + str(hex(img[i][j][1])[2:]) + str(hex(img[i][j][0])[2:]) + ";\n")
                addr += 1
            f.write("\n");

    f.write("\t\t\tdefault: dout = 0;\n")
    f.write("\t\tendcase\n")
    f.write("\tend\n")
    f.write("endmodule")