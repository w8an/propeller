{{
                                         
                                          DIGITAL I/O BOARD DEMO
                                         
   


┌──────────────────────────────────────────────────────┐
│ DIGITAL I/O Board Shift Register Demonstration       │
│ Author: Michael du       m Plessis                           │               
│ Copyright (c) 2011 Optimho                           │               
│ See end of file for terms of use.                    │                
└──────────────────────────────────────────────────────┘ 

This demonstration file is written for Parallax DIGITAL I/O BOARD
The Parallax Digital I/O Board makes use of two shift registers, namely the
74HC595 (Serial to Parallel) and the 74HC165 (Parallel to Serial) Shift registers
This program starts two cogs to handle shifting-out(SHiftOUT) and shifting-in(ShiftIN) data simultaneously 

To demonstrate the functionality simulate an input and the corresponding output relay will operate.
The Digital I/O Board should be supplied from a 9-12v supply for relay power for the demonstration to work.
The inputs also need 9-12V to drive inputs.  
Wiring Connections.
-------------------

 SCLK_RLY -------P12
 LAT_RLY  -------P13
 DATA_RLY -------P11
 SCLK_IN  -------P9
 LOAD_IN  -------P8
 DIN      -------P10
 OE_RLY   -------P14 or GND
 VSS      -- +3.3volts
 VDD      -- GND
 V+       not connected

________________________________
Version 1.0   -  Original file


---------------------------------
Enhancements and things to do:
---------------------------------
1. SHiftIN shifts data out so that data ends up MSB first, Fix this.
                                                        This has been done now
2. Change ShiftOUT and ShiftIN to assembly code implementation.

 
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

 SCLK_RLY=12
 LAT_RLY =13
 DATA_RLY=11
 SCLK_IN=9
 LOAD_IN=8
 DIN =  10
 OE_RLY = 14


  
VAR
byte OUT_REG
byte IN_REG

OBJ    Sout : "ShiftOUT"
       Sin : "ShiftIN"
       trm : "Parallax Serial Terminal"

PUB main
OUT_REG:=0
 Sout.start(SCLK_RLY,LAT_RLY,DATA_RLY,OE_RLY,@OUT_REG)                    ''Start Shiftout 
 Sin.start(SCLK_IN,LOAD_IN,DIN,@IN_REG)                                   ''Start Shift In
 trm.start(115200)                                                        ''Start Terminal 

 repeat
   
   'waitcnt(cnt +clkfreq/100*50)
   trm.position(1,5)                                                       ''Use the delay if you want to slow things down
   trm.Str(String("--   INPUT --- " ))                                    
   trm.bin(IN_REG,8) 'read which input is active                           ''Read Input and display
   
   OUT_REG:=IN_REG  'Make the output register the same as                  ''Send the contents of the IN_REG to the OUT_REG
                                                                           ''This will output the data in the IN_REG to the
                                                                           ''Output Relays 


DAT
     {<end of object code>}
     
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}          