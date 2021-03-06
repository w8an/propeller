'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │ ESC Motor Control Demo                                             v1.00 │
'' ├──────────────────────────────────────────────────────────────────────────┤
'' │  Authors:           (c) 2008 Gavin Garner(original Single_Servo_Assembly)│
'' │                     (c) 2010 "Cluso99" (Ray Rodrick)  modifications      │
'' │  Acknowledgements:  see relevant files for authors and acknowledgements  │
'' │  License   MIT License - See end of file for terms of use                │
'' └──────────────────────────────────────────────────────────────────────────┘
'' Modified from original code....
''   Single_Servo_Assembly
''   Author: Gavin Garner
''   November 17, 2008
''   See end of file for original comments
'──────────────────────────────────────────────────────────────────────────────────────────────────
'  Modifications by Cluso99.
'  Modified to drive a Brushless Motor using an ESC/BEC motor controller.
'  Note a BEC type ESC supplies 5V on the center serovo pin (some servos are different). Therefore, only two wires
'    should be connected, being ground and servo pin.
'  I have used the TV output because it has a series resistor for protection and ground outputs. I have connected an
'    RCA plug to a servo type cable & plug from an old PC and a 3pin stake block. You could also put a series resistor
'    in the RCA plug for protection if you wish.

'  Here is the connection diagram...             RCA Plug                  To Servo Plug
'                           270R/560R/1K1                                             
'   Prop Pxx (TV P14) ───────────────────┐     ───────────────────────────────────────
'                     ──┐                ┌• TV ───┐                             nc ───
'                       ┴                ┴          └───────────────────────────────────
'──────────────────────────────────────────────────────────────────────────────────────────────────
'  Uses the PropPlug and PST to set the motor speed from the PC Keyboard
'    0=OFF, 1=12.5%,2=25%, 3=37.5%, 4=50%, 5=62.5%, 6=75%,7=87.5%, 8=ON
'──────────────────────────────────────────────────────────────────────────────────────────────────
'' RR20100426   _rr001  use 20ms and 1ms...2ms (motor 1ms=off, 1.5ms=50%, 2ms=100%)
''                      uses fdx and PST: 0=OFF, 1=12.5%,2=25%, 3=37.5%, 4=50%, 5=62.5%, 6=75%,7=87.5%, 8=ON




 
CON
  _xinfreq  = 5_000_000            
  _clkmode  = xtal1+pll16x                 'The system clock is set at 80MHz (this is recommended for optimal resolution)                                             

  Servo_Pin = 14                           'use the TV pin

  rxPin  = 31                   'serial
  txPin  = 30
  baud   = 115200
  tvPin  = 14                   'TV pin (1-pin version)  (best pin to use if trying on existing circuit)
  kdPin  = 26                   'Kbd pin (1-pin version) (use this pin    if trying on existing circuit)

OBJ
  fdx   :       "FullDuplexSerial"                      'serial driver
                                                                                                                          
VAR                                                                                                                      
  long  position                           'The assembly program will read this variable from the main Hub RAM to determine
                                           ' the servo signal's high pulse duration                                  
                                                                                                                           
PUB Demo  | ch                                                                                                                 

  waitcnt(clkfreq*5 + cnt)                 'delay (5 secs) to get terminal program runnining (if required)
  fdx.start(rxPin,txPin,0,baud)            'start serial driver to PC

  fdx.str(string(13,"Cluso's Motor Control Test v002",13))
  fdx.str(string("Press <space> to start"))
  repeat
    ch := fdx.rx
  until ch := " "
  fdx.tx(13)

  position := 80_000                       '1mS (motor off)
  cognew(@SingleServo,@position)           'Start a new cog and run the assembly code starting at the "SingleServo" cell on         
                                           ' it passing the address of the "position" variable to that cog's "par" register            

  repeat
    ch := fdx.rx
    case ch
      "0" : position := 80_000                          '1mS     OFF
      "1" : position := 90_000                          '1.125ms 12.5%
      "2" : position := 100_000                         '1.250ms 25%
      "3" : position := 110_000                         '1.375ms 37.5%
      "4" : position := 120_000                         '1.5ms   50%
      "5" : position := 130_000                         '1.625ms 62.5%
      "6" : position := 140_000                         '1.75ms  75%
      "7" : position := 150_000                         '1.875ms 87.5%
      "8" : position := 160_000                         '2ms     ON


      
  

                                                   
DAT
'The assembly program below runs on a parallel cog and checks the value of the "position" variable in the main Hub RAM (which 
' other cogs can change at any time). It then outputs a servo high pulse for the "position" number of system clock ticks and 
' sends a 10ms low part of the pulse. It repeats this signal continuously and changes the width of the high pulse as the
' "position" variable is changed by other cogs.

              org                         'Assembles the next command to the first cell (cell 0) in the new cog's RAM
SingleServo   mov       dira,ServoPin     'Set the direction of the "ServoPin" to be an output (and all others to be inputs)                                 
                                                                                                                      
Loop          rdlong    HighTime,par      'Read the "position" variable (at "par") from Main RAM and store it as "HighTime"
              mov       counter,cnt       'Store the current system clock count in the "counter" cell's address   
              mov       outa,AllOn        'Set all pins on this cog high (really only sets ServoPin high b/c rest are inputs)            
              add       counter,HighTime  'Add "HighTime" value to "counter" value
              waitcnt   counter,LowTime   'Wait until "cnt" matches "counter" then add a 10ms delay to "counter" value 
              mov       outa,#0           'Set all pins on this cog low (really only sets ServoPin low b/c rest are inputs)
              waitcnt   counter,0         'Wait until cnt matches counter (adds 0 to "counter" afterwards)
              jmp       #Loop             'Jump back up to the cell labled "Loop"                                      
                                                                                                                    
'Constants and Variables:                                                                                           
ServoPin      long      |< Servo_Pin      '<------- This sets the pin that outputs the servo signal (which is sent to the white wire
                                          ' on most servomotors). Here, this "7" indicates Pin 7. Simply change the "7" 
                                          ' to another number to specify another pin (0-31).
AllOn         long      $FFFFFFFF         'This will be used to set all of the pins high (this number is 32 ones in binary)
LowTime       long      1_600_000         'This works out to be a 20ms pause time with an 80MHz system clock.
'LowTime       long      800_000          'This works out to be a 10ms pause time with an 80MHz system clock.
counter       res                         'Reserve one long of cog RAM for this "counter" variable                     
HighTime      res                         'Reserve one long of cog RAM for this "HighTime" variable                                                                       
              fit                         'Makes sure the preceding code fits within cells 0-495 of the cog's RAM


{Copyright (c) 2008 Gavin Garner, University of Virginia
''   Single_Servo_Assembly
''This program demonstrates how to control a single RC servomotor by dedicating a cog to output signal pulses using a simple
''assembly program. Once the assembly program is loaded into a new cog, it continuously checks the value of the "position"
''variable in the main RAM (the value of which code running on any other cog can change at any time) and creates a steady
''stream of signal pulses with a high part that is equal to the "position" value times the clock period (1/80MHz) in length
''and a low part that is 10ms in length. (This low part may need to be changed to 20ms depending on the brand of motor being
''used, but 10ms seems to work fine for Parallax/Futaba Standard Servos and gives a quicker response time than 20ms.) With an
''80MHz system clock the servo signal's pulse resolution is between 12.5-50ns, however, the control circuitry inside most
''analog servomotors will probably not be able to distinguish between such small changes in the signal.
'Notes:
' -To use this in your own Spin code, simply declare a "position" variable as a long, start the assembly code running in a
'  cog with the "cognew(@SingleServo,@position)" line and copy and paste my DAT section into the DAT section of your own 
'  code. Note that you must change the number "7" in the ServoPin constant declaration in the assembly code to select a pin
'  other than Pin 7 to be the output pin for the servo signal.
' -If you are using a Parallax/Futaba Standard Servo, the range of signal pulse widths is typically between 0.5-2.25ms, which
'  corresponds to "position" values between 40_000 (full clockwise) and 180_000 (full counterclockwise). In theory, this
'  provides you with 140_000 units of position resolution across the full range of motion. You may need to experiment with
'  changing the "position" values a little to take advantage of the full range of motion for the specific RC servo motor that
'  you are using. However, you must be careful not to force the servo to try to move beyond its mechanical stops.
' -If you find that your propeller chip or servomotor stops working for no apparent reason, it could be that the motor is
'  sending inductive spikes back into the power supply or it is simply drawing too much current and resetting the
'  propeller chip. Adding a large capacitor (e.g.,1000uF) across the power leads of the servo motor or using separate power
'  sources for the propeller chip's 3.3V regulator and the servomotor's power supply will help to fix this.

MIT License: Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and
this permission notice shall be included in all copies or substantial portions of the Software. The software is provided
as is, without warranty of any kind, express or implied, including but not limited to the warrenties of noninfringement.
In no event shall the author or copyright holder be liable for any claim, damages or other liablility, out of or in
connection with the software or the use or other dealings in the software.}                 