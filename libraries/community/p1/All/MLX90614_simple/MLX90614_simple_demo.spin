{{ MLX90614_simple_demo.spin
┌─────────────────────────────────────┬────────────────┬─────────────────────┬───────────────┐
│ MMLX90614 driver demo v1.0          │ BR             │ (C)2012             │  10Dec2012    │
├─────────────────────────────────────┴────────────────┴─────────────────────┴───────────────┤
│ A simple/lightweight driver object for interfacing with the Melexis MLX90614 non-contact   │
│ temperature sensor via the SMbus (pseudo-I2C) interface.  This object is for interfacing   │
│ with the raw sensor (no breakout board).  See object for reference circuit and notes.      │
│                                                                                            │
│ See end of file for terms of use.                                                          │
└────────────────────────────────────────────────────────────────────────────────────────────┘
}}
con
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  
obj
  pst  : "parallax serial terminal"                            
  mlx  : "mlx90614_simple"

pub go  | tmp

  pst.start(115200)
  mlx.setup

  waitcnt(clkfreq*4+cnt)
  pst.clear
  pst.str(string("MLX90614_simple demo",13))

  mlx.readReg(mlx#ambient) 'FIXME: some sort of init bug...need to chase this down

  'display RAM register contents
  pst.str(string("********************************",13))
  pst.str(string("RAM Register contents",13))
  pst.str(string("********************************",13))
  pst.str(string("Address   Contents",13))
  repeat tmp from 0 to $1F
     pst.char(36)
     pst.hex(tmp,2)
     pst.positionX(10)
     pst.dec(mlx.readReg(tmp))
     pst.positionX(20)
     case tmp
       $04: pst.str(string("Raw data IR ch 1"))
       $05: pst.str(string("Raw data IR ch 2"))
       $06: pst.str(string("Tambient (16bit format, $27AD=10_157=-70C to $7FFF=32_767=382C)"))
       $07: pst.str(string("Tobject1 (16bit format, $27AD=10_157=-70C to $7FFF=32_767=382C)"))
       $08: pst.str(string("Tobject2 (16bit format, $27AD=10_157=-70C to $7FFF=32_767=382C)"))
       $0A: pst.str(string("Melexis reserved, Ta1_PKI"))
       $0B: pst.str(string("Melexis reserved, Ta2_PKI"))
       $13: pst.str(string("Melexis reserved, Scale_Alpha_Ratio"))
       $14: pst.str(string("Melexis reserved, Scale_Alpha_Slope"))
       $15: pst.str(string("Melexis reserved, IIR_Filter"))
       $16: pst.str(string("Melexis reserved, Ta1_PKI_Fraction"))
       $17: pst.str(string("Melexis reserved, Ta2_PKI_Fraction"))
       $1B: pst.str(string("Melexis reserved, FIR_Filter"))
       other: pst.str(string("Melexis reserved"))
     pst.newline
  pst.newline
     
  'display EEPROM register contents
  pst.str(string("********************************",13))
  pst.str(string("EEPROM Register contents",13))
  pst.str(string("********************************",13))
                 '123456789012345678901234567890
  pst.str(string("Address   Contents            writable?",13))
  repeat tmp from $20 to $3F
     pst.char(36)
     pst.hex(tmp,2)
     pst.positionX(10)
     case tmp
       $2e,$3c..$3f: pst.char(36)
                     pst.hex(mlx.readReg(tmp),2)
       $22,$25:      'pst.positionX(5)
                     pst.char(37)
                     pst.bin(mlx.readReg(tmp),16)
       other:        pst.dec(mlx.readReg(tmp))
     pst.positionX(30)
     case tmp
       $20: pst.str(string("yes       To_max"))
       $21: pst.str(string("yes       To_min"))
       $22: pst.str(string("yes       PWMCTRL"))
       $23: pst.str(string("yes       Ta range"))
       $24: pst.str(string("yes       emissivity correction coefficient"))
       $25: pst.str(string("yes       config register1"))
       $2E: pst.str(string("yes       SMbus address (LSB only)"))
       $2f: pst.str(string("yes       Melexis reserved"))
       $39: pst.str(string("yes       Melexis reserved"))
       $3c: pst.str(string("no        ID number"))
       $3d: pst.str(string("no        ID number"))
       $3e: pst.str(string("no        ID number"))
       $3f: pst.str(string("no        ID number"))
       other: pst.str(string("no        Melexis reserved"))
     pst.newline
  pst.newline
     
  'example EEPROM write command - set TOmax
  tmp:=mlx.writeReg(mlx#TOmax,$9984)
  pst.hex(tmp,2)'dec(tmp)
  pst.newline

  'read current temperatures
  pst.newline
  pst.str(string("********************************",13))
  pst.str(string("Current temperature readings",13))
  pst.str(string("********************************",13))
  pst.positionX(10)
  pst.str(string("raw"))
  pst.positionX(20)
  pst.str(string("degC"))
  pst.positionX(30)
  pst.str(string("degF"))
  pst.newline
  emit_temperatures(mlx#Ambient)
  emit_temperatures(mlx#Object1)
  emit_temperatures(mlx#Object2)
  emit_temperatures(mlx#TOmax)
  emit_temperatures(mlx#TOmin)
  pst.newline

  
  pst.str(string("press any key to continue",13))
  pst.CharIn
  repeat
    emit_temperatures(mlx#Object1)
    waitcnt(clkfreq/2+cnt)


pub emit_temperatures(reg)|t1,t2,t3
  t1:=mlx.readReg(reg)                              'raw
  t2:=mlx.getTempC(reg)                             'C
  t3:=mlx.getTempF(reg)                             'F

  case reg
    mlx#ambient: pst.str(string("Tamb  = "))
    mlx#object1: pst.str(string("Tobj1 = "))
    mlx#object2: pst.str(string("Tobj2 = "))
    mlx#TOmax:   pst.str(string("TOmax = "))
    mlx#TOmin:   pst.str(string("TOmin = "))
  pst.positionX(10)
  pst.dec(t1)
  pst.positionX(20)
  pst.dec(t2)
  pst.positionX(30)
  pst.dec(t3)
  pst.newline


DAT
{{
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                     TERMS OF USE: MIT License                                       │                                                            
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and    │
│associated documentation files (the "Software"), to deal in the Software without restriction,        │
│including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,│
│and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,│
│subject to the following conditions:                                                                 │
│                                                                                                     │                        │
│The above copyright notice and this permission notice shall be included in all copies or substantial │
│portions of the Software.                                                                            │
│                                                                                                     │                        │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT│
│LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  │
│IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         │
│LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION│
│WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}   