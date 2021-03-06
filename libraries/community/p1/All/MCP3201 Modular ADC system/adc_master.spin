{{

┌──────────────────────────────────────────┐
│ Top level module for ADC-DAC  1.0        │
│ Author: Frank  Freedman                  │
│ Copyright (c) 2011 Frank Freedman        │
│ See end of file for terms of use.        │
└──────────────────────────────────────────┘

This device uses an MCP3201 ADC
IKAlogic 8 bit R2R DAC modded to 12 bits

P  ├P0─────────Clk 7┤           ├ HP3312A function generator
r  ├P1─────────Dat 6┤ MCP3201   │
o  ├P2─────────Csel5┤   V=5V    ├ Vref 5V
p
c  ├
h  ~│
i  ~│12 bits (8-19 for code)
p  ├


}}
'
con
    _clkmode = xtal1 + pll16x
    _clkfreq = 80_000_000

'acq. pins
acq_pin   = %00000000_00000000_00000000_00001000      'sample valid pin all modules
smp_pin   = %00000000_00000000_00000000_00000100      'input sample pin module n
mst_csel  = %00000000_00000000_00000000_00000010      'master csel pin for a/d converters
mst_clk   = %00000000_00000000_00000000_00000001      'master clock pin for a/d converters
DAC_Pins  = %00000000_00001111_11111111_00000000      '12 bits for DAC

time_cog = 1                 'set timebase cog to 1
acq_cog1 = 2                 'acq cog to 2

obj
  clk_gen : "clockgen"
  acq_con : "acq_module"        'acquisition module startup

var

pub main

clk_gen.start_clk(time_cog,mst_clk,mst_csel,acq_pin)
acq_con.acq_init(acq_cog1,acq_pin,smp_pin,mst_csel,DAC_Pins)

DAT
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
