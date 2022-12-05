# Bombs & Balloons
Bombs & Balloons is a simple balloon-shooter game designed and implemented on FPGA.
We have implemented this game for the project requirement in EC551 at Boston University. 

Full Vivado project is included with this repo which is targetted for Digilent Nexys A7 FPGA development board. 
However, this game can be synthesized and run on any FPGA development board that has a VGA output port and onboard buttons by just changing the constriants file. See the following section for the detailed requirements. 

## Requirements
Following components are needed to run the game as it is in this repo. 
1. Digilent Nexys A7 board (or any FPGA board that has a VGA output and onboard buttons or Pmod interface)
2. Digilent Joystick (https://digilent.com/shop/pmod-jstk2-two-axis-joystick/)
3. VGA cable and a monitor that has a VGA interface

If you want to target a different board you can use the same source files and change the constraints file according to your board. 

### Running the game without the joystick
Bombs & Balloons can be played using the onboard buttons in the FPGA board instead of the joystick. 
Following change is required before bitstream generation if you want to use the onboard buttons. 

Uncomment the `define NOJSTK line at https://github.com/sammy17/bombs-n-balloons/blob/6152e6a6e4e00bf8bc2bac355a25489abe88c7a4/bombs_and_balloons.srcs/sources_1/imports/Desktop/PmodJSTK/PmodJSTK.srcs/PmodJSTK_Demo.v#L47

Change the constraints if required to use the onboard buttons (no change required for the Nexys A7 board).

Now follow the rest of the instructions in Getting started section. 

## Getting started
1. Clone the project and open the project in Vivado. 
```
git clone https://github.com/sammy17/bombs-n-balloons.git
```

2. Open the project in Vivado (tested in Vivado 2019.1) and do the necessary changes if you have a different FPGA board or you don't have the Digilent Pmod Joystick. See Requirements sections for the changes that needs to be done if you don't have the joystick. 
3. Generate the bitstream and program it to the target FPGA board. 
4. Connect the VGA port of the FPGA to a monitor and connect the joystick if available. 
5. Reset the game: reset is connect to the 4th switch (SW[3]) in the Nexys A7 board (feel free to change this before bitstream generation if needed).
6. Play the game! 

 ## Developers:
   Farbin Fayza  
   Farhan Tanvir Khan  
   Chathura Rajapaksha
