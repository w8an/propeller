{{ adc0831_fast.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ adc0831_fast              v1.0      │  BR            │ (C)2011             │  31May2011    │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│ Bare-bones ADC0831 8-bit ADC driver, written in pasm. Uses a cog to get 8-bit adc samples  │
│ at a max rate of 30,000 samples/sec.                                                       │
│                                                                                            │
│ •Max theoretical sample rate is ~45,000 samples/sec (400KHz clk @ 8 bits/sample, w/ ovrhd) │
│ •The highest sample rate relably demonstrated (using the part I have @3.3v attached to a   │
│  breadboard) is 30K samples/sec @ 80MHz                                                    │
│ •Using Vcc of +5V (as spec'd) enables slightly higher sample rates,                        │
│  but is generally less convenient...if using +5V, adcClock can be 500K                     │
│ •Vin is spec'd as +5v, but 3.3v seems to work OK for the part I have                       │
│ •If using +5v, be sure to put a 2.2K resistor on the d0 pin. In practice, it doesn't hurt  │
│  to use a 2.2K resistor on all pins connected to the propeller, just to be safe.           │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘

Reference circuit w/ potentiometer
============================================
Typical connections for a simple adc test circuit with 0 at ground and max scale at Vdd.
Example curcuit shown uses a potentiometer to make a variable voltage divider which
can be used to see how adc output changes w/ voltage.  See data sheet for further example
reference configurations (upper/lower bound scaling, differential voltage sampling, etc.).

              
                   ADC0831         Vcc(+5V spec'd, but +3.3V 
              ┌─────────────┐   │      seems to work OK)
   cs pin ────┤1 -CS   VCC  8 ├───┘                
         ┌────┤2 VIN+  CLK  7 ├─────────  clk pin 
         │  ┌─┤3 VIN-  DO   6 ├───────  d0 pin (2.2K resistor)
 sampled │  ╋─┤4 GND   Vref 5 ├───────┐  
 voltage │   └───────────────┘       │                                    
                                     │
      ┌───────────────────────────┻─ +3.3V (or 5V)    
      │  pot                              
 100Ω 
      

TIMING LIMITS per data sheet (Aug1999)
======================================
fCLK, Clock Frequency Min = 10 khz
                      Max = 400 khz (100 ticks on 80MHz clock)
tSET-UP, CS Falling Edge or Data Input Valid to CLK Rising Edge = 250 ns
   (20 ticks @ 80MHz)
}}

con
adcClock = 350_000                      'clk rate applied to adc clk pin (400Khz max)


VAR
byte cog


pub start(cs,clk,d0,sampRate,outPtr) 
''initilaizes asm driver, sets cs pin high (idle state)
''cs       = adc0831 chip select pin
''clk      = adc0831 clock pin
''d0       = adc0831 serial data pin
''sampRate = rate at which adc samples are taken and placed into inPtr memory location
''outptr   = pointer to memory location where current adc output value to placed
''           (value is refreshed at user-specified update rate)

  clk_mask := |< clk                    'embed initialized values into asm code before launching...
  cs_mask  := |< cs
  do_mask  := |< d0
  t1 := clk_mask + cs_mask
  sampRate <#= 30000                    'limit sample rate
  sampCnt := clkfreq / sampRate         'wait period between samples (ticks)
  clkCnt := clkfreq / adcClock / 2      'wait period between clk transitions (400 KHz max)
  stop
  cog := cognew(@entry,outPtr) + 1
  return cog


PUB stop
  if cog
    cogstop( cog~ - 1 )  

  
dat
' ASM driver entry
              org
entry         or      dira,t1             'make clk and cs pins outputs
              or      outa,cs_mask        'set cs pin high (deselect chip)
              mov     cnt1,cnt            'initialize sample rate waitperiod
              add     cnt1,sampCnt
              
:loop         waitcnt cnt1,sampCnt        'wait for next sampling period
              andn    outa,cs_mask        'set cs pin low (activate chip)            
              mov     t1,#0               'zero t1                           ' 
              mov     t2,#8               'read in 8 bits (loop 8 times)     '250ns min from
              mov     cnt2,cnt                                               'cs-low to 1st clk edge
              add     cnt2,clkCnt                                            ' 
              or      outa,clk_mask       'pulse clk to bring d0 out of tri-state mode
              waitcnt cnt2,clkCnt         'wait (max freq on clk pin is 400khz)
              andn    outa,clk_mask       'clk lo
              waitcnt cnt2,clkCnt         
                                                                               
:serin        or      outa,clk_mask       'shift in data: clk pin hi
              waitcnt cnt2,clkCnt         'wait (max freq on clk pin is 400khz)
              andn    outa,clk_mask       'clk lo
              waitcnt cnt2,clkCnt         'wait for data valid

              test    do_mask,ina    wc
              rcl     t1,#1
              djnz    t2,#:serin

              or      outa,cs_mask        'set cs pin high (deselect chip)
              wrlong  t1,par
              jmp     #:loop              'play it again, Sam              '4
'
' Initialized data
'
clk_mask      long    0
cs_mask       long    0                   'cs is an active low pin (idle state is high)
do_mask       long    0
sampCnt       long    0
clkCnt        long    0
t1            long    0
'
' Uninitialized data
'
t2            res     1
cnt1          res     1
cnt2          res     1


dat
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
             