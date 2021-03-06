''*********************************************
''*  Demo for Servo_74HC595 Version 2.0       *
''*  Author: Jim Miller                       *
''*  Copyright (c) 2009 Cannibal Robotics     *               
''*  See end of file for terms of use.        *               
''*********************************************

CON

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  '============================== 74HC595 ports ALL will be output
  Sclr_pin      = 19            ' ~ Input register clear - Active low
  CLK_Pin       = 18            ' Input register clock   
  RCK_pin       = 17            ' Storage register clock
  G_Pin         = 16            ' ~ Output enable - Active low
  SER_pin       = 15            ' serial data

var
  byte                SrvCog
  byte                c  
  long                ServoLong[16]
  long                ServoMult
  long                Scan     
       
OBJ 
  Srv   : "Servo_74HC595"  
  num   : "Numbers"  
PUB start | i
  num.init
                                                        'Start PWM cog and set pin values
  SrvCog := Srv.Start(CLK_Pin, SER_pin, Sclr_pin,RCK_pin,G_Pin) 
  ServoMult := clkfreq/1_000_000                        ' Servo timing mSec multiplier  
  Repeat c from 0 to 15                                 '  Pre-Load all servo positions at mid point
     Srv.ServoOut(1450,c,ServoMult)                     '  ServoOut(PulseLength, Channel, Multiplier)
                                                        '  PulseLength units are uSec 900 to about 2200   
                                                        '  Channel 0 to 15
                                                        '  ServoMult = clkfreq/1_000_000 to adjust
                                                        '  PulseLength to uSec in counts
  Scan := 900                                           '  Set Scan varriable to 900 mSec 
  Main

PUB Main

  repeat                                                ' This loop scans all servo channels simultaneously
    SendServo                                           ' Send the outbound servo values to the servos                                           ' 
    Repeat c from 0 to 15                               ' Load pulse value 'scan' into all servo outputs
       ServoLong[c] := Scan
    Scan := Scan + 10                                   ' Increment Scan
    if Scan == 2210                                     ' Reset it to 900 if too big
      Scan := 900
    waitcnt(10_000_000 + cnt)                           '  Wait for Delay     

pub SendServo                                           ' Update all 16 servo channels from ServoLong array
  repeat c from 0 to 15                                 ' Call format: ServoOut(pulse_length,channel,ServoMult)
    Srv.ServoOut(ServoLong[c],c,ServoMult)              ' PulseLength in uSec,Channel Number 0 - 15

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