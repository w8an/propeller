{{┌──────────────────────────────────────────┐
  │ IL3820 ePaper display Spin text driver   │
  │ Author: Chris Gadd                       │
  │ Copyright (c) 2020 Chris Gadd            │
  │ See end of file for terms of use.        │
  └──────────────────────────────────────────┘
  Written for the Parallax 28024 ePaper display

  The display is designed as 128 horizontal pixels x 296 vertical, x coordinate ranges from byte[0] to byte[15] and y coordinate ranges from byte[0] to byte[4720]
    [0:0] is the top left, with x incrementing left-to-right and y incrementing top-to-bottom.  Each byte is written across eight columns, lsb first

  ┌──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬   ┬──────┬──────┬──────┬──────┬──────┬──────┬──────┬──────┐ 
  │  0:0 │  0:1 │  0:2 │  0:3 │  0:4 │  0:5 │  0:6 │  0:7 │   │ 15:0 │ 15:1 │ 15:2 │ 15:3 │ 15:4 │ 15:5 │ 15:6 │ 15:7 │ 
  ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼   ┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤ 
  │ 16:0 │ 16:1 │ 16:2 │ 16:3 │ 16:4 │ 16:5 │ 16:6 │ 16:7 │   │ 31:0 │ 31:1 │ 31:2 │ 31:3 │ 31:4 │ 31:5 │ 31:6 │ 31:7 │ 
  ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼   ┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤ 
                                                                                                                        
  ├──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼   ┼──────┼──────┼──────┼──────┼──────┼──────┼──────┼──────┤ 
  │4720:0│4720:1│4720:2│4720:3│4720:4│4720:5│4720:6│4720:7│   │4735:0│4735:1│4735:2│4735:3│4735:4│4735:5│4735:6│4735:7│ 
  └──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴   ┴──────┴──────┴──────┴──────┴──────┴──────┴──────┴──────┘ 

  This driver treats the display as 296 horizontal x 128 vertical pixels, coordinate 0,0 is in the bottom-left of the display
  Uses the built-in ROM fonts, creating a 4 line x 18 character display

   4-wire interface
  CS   
  BUSY 
  D/C  
  CLK  
  DIN  ──
          D7  D6  D5  D4  D3  D2  D1  D0       BUSY high for ~418ms                 
}}
CON
'Definitions
  WIDTH   = 128 
  HEIGHT  = 296 
  BLACK   = 0
  WHITE   = 1
        
VAR
  long  cs,mosi,sck,dc,busy,rst
  long  charmap[16]
  byte  bitmap[WIDTH * HEIGHT / 8]
  byte  row_pos,col_pos,color

PUB null                                                '' Not a top-level object

PUB init(_cs,_mosi,_sck,_dc,_busy,_reset)
  longmove(@cs,@_cs,6)
  dira[cs] := dira[mosi] := dira[sck] := dira[dc] := dira[rst] := 1
  outa[cs] := 1
  resetDisplay
  waitcnt(clkfreq + cnt)

PUB clearBitmap                                         
  bytefill(@bitmap,$FF,WIDTH * HEIGHT / 8)

PUB Move(row,col)                                       '' Row 0(bottom) - 3(top) / Col 0(left) - 17(right)
  row_pos := row <# 3
  col_pos := col <# 18

PUB setColor(_color)                                    '' color 0 - black on white / color 1 - white on black
  color := _color ^ 1  
  
PUB Dec(value) | i, x                                   '' Write a decimal value into bitmap

  x := value == NEGX                                    ' Check for max negative
  if value < 0
    value := ||(value+x)                                ' If negative, make positive; adjust for max negative
    Tx("-")                                             '  and output sign

  i := 1_000_000_000                                    ' Initialize divisor

  repeat 10                                             ' Loop for 10 digits
    if value => i                                                               
      Tx(value / i + "0" + x*(i == 1))                  ' If non-zero digit, output digit; adjust for max negative
      value //= i                                       '  and digit from value
      result~~                                          '  flag non-zero found
    elseif result or i == 1
      Tx("0")                                           ' If zero digit (or only digit) output it
    i /= 10                                             ' Update divisor

PUB Str(strPtr)                                         '' Writes a string of characters into bitmap
  repeat strsize(strPtr)
    tx(byte[strPtr++])

PUB Tx(char) | address, temp, i, j                      '' Retrieves character from ROM, rotates, and writes into bitmap

  if row_pos > 3 or col_pos > 17
    return false
  longfill(@charmap,0,16)                                                                               
  address := (char & !1) << 6 + $8000                   
  repeat j from 0 to 31
    temp := long[address] >> (char & 1)
    address += 4     
    repeat i from 0 to 30 step 2
      charmap[i / 2] ->= 1
      charmap[i / 2] |= ((temp >> i) & 1) ^ (color & 1)
  repeat i from 0 to 15
    bitmap[row_pos * 4 + col_pos * 256 + i * 16 + 0] := charmap[i] >> 24
    bitmap[row_pos * 4 + col_pos * 256 + i * 16 + 1] := charmap[i] >> 16
    bitmap[row_pos * 4 + col_pos * 256 + i * 16 + 2] := charmap[i] >> 8
    bitmap[row_pos * 4 + col_pos * 256 + i * 16 + 3] := charmap[i] >> 0
  col_pos += 1

PUB updateDisplay | i                                  

  writeCommand(@c_set_x_position)
  writeCommand(@c_set_y_position)
  writeCommand(@c_set_x_counter)
  writeCommand(@c_set_y_counter)
  repeat while ina[busy] 
  outa[cs] := 0
  outa[dc] := 0
  writeByte(WRITE_RAM)
  outa[dc] := 1
  repeat i from 0 to 4735                               ' WIDTH * HEIGHT / 8 - 1
    writeByte(bitmap[i])
  outa[cs] := 1
  writeCommand(@c_display_update_2)
  writeCommand(@c_master_activation)
  repeat while ina[busy]
  
PUB resetDisplay
  outa[rst] := 0
  waitcnt(clkfreq / 1000 * 200 + cnt)
  outa[rst] := 1
  waitcnt(clkfreq / 1000 * 200 + cnt)

  writeCommand(@c_sw_reset)
  repeat while ina[busy]
  writeCommand(@c_driver_output)
  writeCommand(@c_booster_start)
  writeCommand(@c_write_vcom)
  writeCommand(@c_set_dummy_period)
  writeCommand(@c_set_gate_time)
  writeCommand(@c_data_entry_mode)
  writeCommand(@c_write_lut_full)
  repeat while ina[busy]
  clearBitmap
  updateDisplay
  writeCommand(@c_write_lut_part)
  repeat while ina[busy]

PUB sleep
  writeCommand(@c_deep_sleep_mode)

PRI writeCommand(strPtr)
  outa[cs] := 0
  outa[dc] := 0                                         ' set dc low for command
  repeat byte[strPtr++]                                 ' 1st byte contains message length
    writeByte(byte[strPtr++])                           ' 1st byte of message contains command - send with dc clear
    outa[dc] := 1                                       ' set dc high for remainder of message
  outa[cs] := 1
  
PRI writeByte(spi_byte) | i
  repeat i from 7 to 0
    outa[mosi] := spi_byte >> i & 1
    outa[sck] := 1
    outa[sck] := 0

CON
'Commands
  DRIVER_OUTPUT           = $01  
  BOOSTER_SOFT_START      = $0C  
' GATE_SCAN_START         = $0F  
  DEEP_SLEEP_MODE         = $10  
  DATA_ENTRY_MODE         = $11  
  SW_RESET                = $12  
' TEMPERATURE_SENSOR      = $1A  
  MASTER_ACTIVATION       = $20  
  DISPLAY_UPDATE_1        = $21  
  DISPLAY_UPDATE_2        = $22  
  WRITE_RAM               = $24  
  WRITE_VCOM_REGISTER     = $2C  
  WRITE_LUT_REGISTER      = $32  
  SET_DUMMY_LINE_PERIOD   = $3A
  SET_GATE_TIME           = $3B
  BORDER_WAVEFORM_CONTROL = $3C
  SET_RAM_X_POSITION      = $44
  SET_RAM_Y_POSITION      = $45
  SET_RAM_X_COUNTER       = $4E
  SET_RAM_Y_COUNTER       = $4F
  TERMINATE_READ_WRITE    = $FF
  
DAT                               ' command strings

c_sw_reset              byte      1,SW_RESET
c_deep_sleep_mode       byte      1,DEEP_SLEEP_MODE,1
c_driver_output         byte      4,DRIVER_OUTPUT, (height -1 & $FF), ((height - 1) >> 8 & $FF),0
c_booster_start         byte      4,BOOSTER_SOFT_START,$D7,$D6,$9D
c_write_vcom            byte      2,WRITE_VCOM_REGISTER,$A8
c_set_dummy_period      byte      2,SET_DUMMY_LINE_PERIOD,$1A
c_set_gate_time         byte      2,SET_GATE_TIME,$08
c_data_entry_mode       byte      2,DATA_ENTRY_MODE,%00000_0_11                                                 
c_write_lut_full        byte      31,WRITE_LUT_REGISTER,$02,$02,$01,$11,$12,$12,$22,$22,$66,$69,{
                                                       }$69,$59,$58,$99,$99,$88,$00,$00,$00,$00,{
                                                       }$F8,$B4,$13,$51,$35,$51,$51,$19,$01,$00
c_write_lut_part        byte      31,WRITE_LUT_REGISTER,$10,$18,$18,$08,$18,$18,$08,$00,$00,$00,{ 
                                                       }$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,{
                                                       }$13,$14,$44,$12,$00,$00,$00,$00,$00,$00  
c_set_x_position        byte      3,SET_RAM_X_POSITION,0,15
c_set_y_position        byte      5,SET_RAM_Y_POSITION,0,0,((height - 1) & $FF),(((height - 1) >> 8) & $FF)
c_set_x_counter         byte      2,SET_RAM_X_COUNTER,0
c_set_y_counter         byte      3,SET_RAM_Y_COUNTER,0,0
c_write_ram             byte      1,WRITE_RAM
c_display_update_2      byte      2,DISPLAY_UPDATE_2,$C4
c_master_activation     byte      1,MASTER_ACTIVATION
c_terminate             byte      1,TERMINATE_READ_WRITE

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