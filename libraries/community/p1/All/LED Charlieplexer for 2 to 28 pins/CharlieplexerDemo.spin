{{ Charlieplexer Demo

   Author: Drew Walton
   Version: 1.0 (27 Nov 2010)
   Email: dwalton64@gmail.com
   
   Copyright 2010 Drew Walton
   Send end of file for Open Source License
   
}}

Con
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  
  NUM_PINS = 3    ' Change this to control more or fewer LEDs
                  ' It should be a number between 1 and 27.  
  StartPin = 2

{{

  Here is the schematic for 3 pins. Note the LEDs need current-limiting
  resistors.  I used 180Ω resistors.   



          Pin2     Pin3     Pin4      
          │        │        │        
          │        │ LED0   │ LED1   
          │        ┣──┐ ┣──┐     
    Pin2──╋────────┼──────┻─┼──────┻─ 
          │        │        │        
          │ LED2   │        │ LED3   
          ┣──┐ │        ┣──┐     
    Pin3──┼──────┻─╋────────┼──────┻─ 
          │        │        │        
          │ LED4   │ LED5   │        
          ┣──┐ ┣──┐ │        
    Pin4──┼──────┻─┼──────┻─╋────────
    
}}
    
OBJ
  cp : "charlieplexer"

VAR
  long numLeds
  
pub testHarness | led, slidemask, count1 
  cp.Start(NUM_PINS, StartPin, TRUE)

  numLeds := cp.GetNumLeds
  
  dira[20]~~
  
  repeat 2
    repeat led from 0 to numLeds
      cp.LedOn(led)
      cp.LedOff(led - 1)
      waitcnt(clkfreq/4 + cnt)        
  
  
    
  repeat 1
    repeat led from 0 to numLeds
      cp.LedOn(led)
      !outa[20]
      waitcnt(clkfreq/4 + cnt)

    cp.SetBlinkCycles(clkfreq/4)
    
    cp.BlinkAll
    waitcnt(clkfreq*2 + cnt)
    
    cp.SetBlinkCycles(clkfreq/10)
    waitcnt(clkfreq*2 + cnt)
    
    cp.StopBlinkingAll
    
    waitcnt(clkfreq*2 + cnt)

    cp.Disable
    waitcnt(clkfreq*2 + cnt)
    
    cp.Enable
    waitcnt(clkfreq*2 + cnt)
    
    
    repeat led from 0 to numLeds
      cp.LedOff(led)
      !outa[20]
      waitcnt(clkfreq/4 + cnt)
      
  count1 := 0

  repeat 
    repeat led from 0 to numLeds
      slidemask := |<led
      if (count1 & slidemask) <> 0
        cp.LedOn(led)
      else
        cp.LedOff(led)

    if ina[0] == 0
      repeat
      
    !outa[20]    
    waitcnt(clkfreq/2 + cnt)        

    count1++
    if count1 > 63
      count1 := 0

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