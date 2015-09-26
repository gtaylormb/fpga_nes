**fpga_nes** is an fpga-targeted Nintento Entertainment System emulator written in Verilog.  It is currently under development, and is most notably missing support for mappers and the DMC sound channel.  At this point, it runs most NROM games capably (e.g., Super Mario Brothers, Excitebike).

In addition, this project includes a C++ Windows application called NesDbg, which communicates with the FPGA over USB UART to load ROMs, run unit tests, readwrite memory, etc.

**Hardware Setup:**

![alt text](http://1.bp.blogspot.com/-BfVh-h9vj14/T-9pofsWmEI/AAAAAAAAAG8/kW62NiNQTsE/s320/setup.jpg "Title")

1. [Nexys 3 Spartan-6 FPGA board](http://www.digilentinc.com/Products/Detail.cfm?NavPath=2,400,897&Prod=NEXYS3). ($119 / $199)
2. Micro-USB connection for FPGA power and programming.
3. VGA display connection for NES video output.
4. Micro-USB connection for communication between NES and NesDbg software.
5. [PmodBB Bread Board](http://www.digilentinc.com/Products/Detail.cfm?NavPath=2,401,471&Prod=PMOD-BB) for a solderless joypad connection.  ($20)
6. [NES Joypad Adapter](http://www.parallax.com/StoreSearchResults/tabid/768/txtSearch/nes/List/0/SortField/4/ProductID/613/Default.aspx) to accept input from joypads.  ($5)
7. 2 [NES Joypads](http://www.parallax.com/Store/Accessories/Hardware/tabid/162/txtSearch/nes/List/0/SortField/4/ProductID/528/Default.aspx) to accept user input.  (2 * $5)
8. [PmodAMP1](http://www.digilentinc.com/Products/Detail.cfm?Prod=PMOD-AMP1) to amplify NES PWM audio output.  ($20)
9. [Speaker](http://www.digilentinc.com/Products/Catalog.cfm?NavPath=2,393&Cat=3) to play the NES sound.  ($6)


**Development Environment:**

1. [ISE 14.1 WebPack](http://www.xilinx.com/support/download/index.htm) (free)
2. [Visual Studio 2010 Express](http://www.microsoft.com/visualstudio/en-us/products/2010-editions/visual-cpp-express) (free)

** ZYBO Board Port:**

This is under development by Greg Taylor. Some changes to the hardware setup:
1. [ZYBO Zynq-7000 FPGA board](https://www.digilentinc.com/Products/Detail.cfm?NavPath=2,400,1198&Prod=ZYBO) instead of Nexys 3. ($125 / $189)
2. [PmodUSBUART](https://digilentinc.com/Products/Detail.cfm?NavPath=2,401,928&Prod=PMOD-USB-UART) for UART connection to ZYBO FPGA.  ($22)
3. You do not need the PmodAMP1 as the ZYBO has a built in DAC.

Changes to development setup:
1. [Vivado 2015.1 WebPack](http://www.xilinx.com/support/download.html) (free) instead of ISE.

