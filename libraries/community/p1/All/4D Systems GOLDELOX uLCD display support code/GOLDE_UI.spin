{{
┌───────────────────────────────────────────────────┐
│ GOLDEUI.spin version 1.0.0                        │
├───────────────────────────────────────────────────┤
│                                                   │               
│ Author: Mark M. Owen                              │
│                                                   │                 
│ Copyright (C)2015 Mark M. Owen                    │               
│ MIT License - see end of file for terms of use.   │                
└───────────────────────────────────────────────────┘

Description:

  A minimal set of text and graphic operations sent via serial communications to
  a 4D Systems uLCD display with a GOLDELOX processor.

  As implemented, we have:
        pixel level positioning
        pixel coloration
        line drawing
        circle drawing
        rectangle drawing
        zero terminated string rendering (not to exceed 18 characters exclusive of the trailing null),
        character geometry based row/column positioning for text
        a string table (up to 8 entries) which can be preloaded to the display
        rendering of integers and decimals (one or two places)
        2, 4 or 8 character hexadecimal strings (code incorporated from Simple_Numbers object)
        foreground, background, fill and outline colors
        line patterns
        screen geometry control

  Requires:
        a 4D Systems GOLDELOX based display                                     (Parallax and Mouser sell them)
        uLCDserialGOLDE.4dg compiled and loaded to the display                  (source code included in the zip file)
        the uLCDserialIO.spin                                                   (source code included in the zip file)
        the FullDuplexSerial-wCTS.spin                                          (source code included in the zip file)                                                                                            

  
  Portions incorporated from 
''*  Simple_Numbers                      *
''*  Authors: Chip Gracey, Jon Williams  *
''*  Copyright (c) 2006 Parallax, Inc.   *

Revision History:
  Initial release 2015-Feb-10

}}

CON
  #$01
  CMD_MOVETOXY                          
  CMD_CLEAR         
  CMD_LINETO        
  CMD_PIXEL         
  CMD_COLOR       ' foreground
  CMD_FILLMODE    ' 0 solid 1 outline
  CMD_COLORBG     ' background
  CMD_SCREENMODE  ' 1 LANDSCAPE,2 LANDSCAPE_R,3 PORTRAIT,4 PORTRAIT_R
  CMD_COLORBORDER ' for circle, rect
  CMD_LINEPATTERN
  CMD_CLIP        ' 0 ON 1 OFF [wtfo? idiotic enumeration]  NOT CURRENTLY SUPPORTED
  CMD_CLIPWINDOW  ' x0,y0,x1,y1
  CMD_TXTCOLOR
  CMD_TXTCOLORBG
  CMD_TXTATTRIB    ' 16 bold 32 italic 64 reverse 128 underline
  CMD_TXTOPAQUE    ' 0 transparent 1 opaque

  #$20
  CMD_RECT        ' actually boxto
  CMD_CIRCLE      ' actually bullet   

  #$50
  CMD_MOVETOCR      
  CMD_NEWLINE
  CMD_TEXTSIZE
  CMD_SET_STRING_AT_IX       
  CMD_STRING_IX     
  CMD_STRING_IX_AT     
  CMD_STRING
  CMD_STRING_AT
  CMD_PRINT_DEC1
  CMD_PRINT_DEC1_AT
  CMD_PRINT_DEC2
  CMD_PRINT_DEC2_AT
  CMD_PRINT_INT
  CMD_PRINT_INT_AT

  #$80
  CMD_8LEDS
  CMD_1LED        

  #$E0
  CMD_XYMAX
  CMD_CHRWH
  
  #$FF
  CMD_SHUTDOWN

CON

  #0
  SOLIDFILL
  OUTLINE

  #0
  CLIP_ON
  CLIP_OFF

  #0
  TRANSPARENT
  OPAQUE

  NORMAL        = 0
  BOLD          = 16 
  ITALIC        = 32 
  REVERSED      = 64 
  UNDERLINED    = 128  

  #1
  LANDSCAPE
  LANDSCAPE_R
  PORTRAIT
  PORTRAIT_R
  
CON
  BLACK         = $0000
  WHITE         = $FFFF
  RED           = $1F<<11
  GREEN         = $3F<<5
  BLUE          = $1F
  CYAN          = %0000011111111111
  MAGENTA       = %1111100000011111
  YELLOW        = %1111111111100000

  LTGREY        = %0111100111101111
  GREY          = %0011100011100111
  DKGREY        = %0001100001100011
   
VAR
  byte  szYYYYMMDDHHMM[13] 'yyyymmddhhmm0
  byte  scrnXmax,scrnYmax,charW,charH 
   
OBJ
  LCD   : "uLCDSerialIO"

PUB Start(rx,tx,cts,reset) 
{{
    Initializes 4D Systems display communications at 115200 baud.
    Forces a reset of the 4D Systems display.
    Waits for the display to complete its restart.

    Parameters:
      rx    receive data pin
      tx    transmit data pin
      cts   clear to send pin
      reset display's reset pin
    
}}
  dira[cts]~ ' input
  LCD.Start(rx,tx,115_200,cts)
 ' force a reset of the display device(s)
  outa[reset]~~ ' high
  dira[reset]~~ ' output
  ' reset time is specified as >= 2µS active low
  waitcnt(clkfreq/100_000+cnt) ' 10µS
  outa[reset]~
  ' reboot time is specified as 1000mS
  repeat                                                                  
    waitcnt(clkfreq/10+cnt) ' 100mS nap pending reset completion indicated by CTS high
  until ina[cts]
  scrnXmax := 127
  scrnYmax := 127
  charW    := 7
  charH    := 8

PUB Stop
{{
    Terminates communications with the 4D Systems display by sending it a shutdown command. 

}}
  LCD.bSend(CMD_SHUTDOWN)
  LCD.GetAck
  ' will quit too quickly for the last transmission to be processed if we dont wait
  waitcnt(clkfreq/20+cnt)
  LCD.Stop

PUB ShowVersion(y,md,hm,c,r) ' general purpose version display
{{
    Renders year month day hour and minute at a specified character position.

    Parameters:
      y       year
      md      month and day
      hm      hour and minute
      c       horizonal character position
      r       vertical character position

}}
  bytemove(@szYYYYMMDDHHMM,Dec(y),4)
  bytemove(@szYYYYMMDDHHMM+4,Dec(10000+md),4)
  bytemove(@szYYYYMMDDHHMM+8,Dec(10000+hm),4)
  szYYYYMMDDHHMM[12] := 0 ' trailing null
  StrAt(@szYYYYMMDDHHMM,c,r)

PUB GetGeometry | w
{{
    Caches the maximum horizontal and vertical pixel coordinates for displays with other than
    128x128 pixels.

    The maximum X and Y values can then be obtained by calling the Xmax and Y max methods when
    needed.

}}
  LCD.bSend(CMD_XYMAX)
  w := LCD.GetWord
  LCD.GetAck
  scrnXmax := (w&$FF00)>>8
  scrnYmax := w&$00FF

PUB Xmax
{{
  returns the displays maximum horizontal pixel coordinate
  
}}
  return scrnXmax
  
PUB Ymax
{{
  returns the displays maximum vertical pixel coordinate

}}
  return scrnYmax

PUB GetCharGeometry | w          
{{
    Caches the maximum horizontal and vertical pixel coordinates for characters other than the
    default text size 1.

    The size values can then be obtained by calling the Wchar and Hchar methods when needed.

}}
  LCD.bSend(CMD_CHRWH)
  w := LCD.GetWord
  LCD.GetAck
  charW := (w&$FF00)>>8
  charH := w&$00FF

PUB Wchar
{{
  returns the current text width in pixels
  
}}
  return charW
  
PUB Hchar
{{
  returns the current text height in pixels

}}
  return charH
  
PUB ScreenMode(m)
{{
    Sets the current screen orientation mode.

    Parameters:
      m     1 LANDSCAPE, 2 LANDSCAPE_R, 3 PORTRAIT, 4 PORTRAIT_R       

}}
  LCD.bSend(CMD_SCREENMODE)
  LCD.bSend(m#>1<#4)
  LCD.GetAck

PUB Clip(b)
{{
    Sets the clipping state.

    Parameters:
      b       idiotic 4D Systems enumeration of on as 0 and off as one for this item

}}
  LCD.bSend(CMD_CLIP)
  LCD.bSend(b#>CLIP_ON<#CLIP_OFF) 
  LCD.GetAck

PUB ClipWindow(a,b,c,d)
{{
    Sets the clipping rectangle.
    After calling this method, call Clip(CLIP_ON) to activate or Clip(CLIP_OFF) to deactivate.

    Parameters:
      a       left    pixel coordinate
      b       top     pixel coordinate
      c       right   pixel coordinate
      d       bottom  pixel coordinate

}}
  LCD.bSend(CMD_CLIPWINDOW)
  LCD.bSend(a:=(a#>0<#(scrnXmax-1))) 
  LCD.bSend(b:=(b#>0<#(scrnYmax-1))) 
  LCD.bSend(c#>a<#scrnXmax) 
  LCD.bSend(d#>b<#scrnYmax) 
  LCD.GetAck

  
PUB Home
{{                                          
    Resets the current pixel coordiates and character position to 0,0.
}}
  MoveTo(0,0)
  MoveToCR(0,0)

PUB Clear
{{
   Fills the screen with black.  Horribly slow however so use seldom.
}}
  LCD.bSend(CMD_CLEAR)
  LCD.GetAck

PUB ClearHome
{{
    Combines Home and Clear functions.
}}
  Home
  Clear

PUB FillMode(m)
{{
    Sets the current rendering mode to solid or outline.

    Parameters:
      m       0 solid, 1 outline

}}
  LCD.bSend(CMD_FILLMODE)
  LCD.bSend(m#>0<#1)
  LCD.GetAck

PUB Color(c)
{{
    Sets the current rendering colour.

    Parameters:
      c       16bit RGB color (565 format see constants)

}}
  LCD.bSend(CMD_COLOR)
  LCD.wSend(c)
  LCD.GetAck

PUB ColorBG(c)
{{
    Sets the current background colour.

    Parameters:
      c       16bit RGB color (565 format see constants)

}}
  LCD.bSend(CMD_COLORBG)
  LCD.wSend(c)
  LCD.GetAck
  
PUB BorderColor(c)
{{
    Sets the current border/outline colour.

    Parameters:
      c       16bit RGB color (565 format see constants)

}}
  LCD.bSend(CMD_COLORBORDER)
  LCD.wSend(c)
  LCD.GetAck

PUB TextColor(c)
{{
    Sets the current text foreground rendering colour.

    Parameters:
      c       16bit RGB color (565 format see constants)

}}
  LCD.bSend(CMD_TXTCOLOR)
  LCD.wSend(c)
  LCD.GetAck

PUB TextColorBG(c)
{{
    Sets the current text background rendering colour.

    Parameters:
      c       16bit RGB color (565 format see constants)

}}
  LCD.bSend(CMD_TXTCOLORBG)
  LCD.wSend(c)
  LCD.GetAck

PUB TextAttributes(flags)
{{
    Sets the current text rendering styles. These settings are transient and apply only to
    the next string rendered. 

    Parameters:
      flags   bits 4 through 7 represent bold, italic, reversed and underlined respectively

}}
  LCD.bSend(CMD_TXTATTRIB)
  LCD.bSend(flags&$F0)
  LCD.GetAck
  
PUB TextOpacity(b)
{{
    Sets the current text background rendering method.

    Parameters:
      b       0 - transparent background, 1 opaque background (TextColorBG)

}}
  LCD.bSend(CMD_TXTOPAQUE)
  LCD.bSend(b#>TRANSPARENT<#OPAQUE)
  LCD.GetAck
  
PUB LinePattern(p)
{{
    Sets the current line pattern bits (example: %1111000011110000).
    Idiotically %0000_0000_0000_0000 produces a solid line hence
    zeros are bits which are on and ones are off. 4DGL was developed by
    nutcases?

    Parameters:
      p       16bit RGB color (565 format see constants)

}}
  LCD.bSend(CMD_LINEPATTERN)
  LCD.wSend(p)
  LCD.GetAck

  
PUB MoveTo(x,y)
{{
    Changes the current pixel coordinates to the specified values (x,y).
  
    Parameters:
      x       pixel horizontal coordinate (0..Xmax)
      y       pixel vertical coordinate (0..Ymax)

}}
  LCD.bSend(CMD_MOVETOXY)
  LCD.bSend(x)
  LCD.bSend(y)
  LCD.GetAck
  
PUB LineTo(x,y)
{{
    Renders a line in the current color from the current pixel coordinates to the specified
    pixel coordinates (x,y).

    Parameters:
      x       pixel horizontal coordinate (0..Xmax)
      y       pixel vertical coordinate (0..Ymax)

}}
  LCD.bSend(CMD_LINETO)
  LCD.bSend(x)
  LCD.bSend(y)
  LCD.GetAck

PUB Pixel(x,y,c)
{{
    Sets a pixel at the specified coordinates(x,y) to a specified colour (c).

    Parameters:
      x       pixel horizontal coordinate (0..Xmax)
      y       pixel vertical coordinate (0..Ymax)
      c       16bit RGB color (565 format see constants)

}}
  LCD.bSend(CMD_PIXEL)
  LCD.bSend(x)
  LCD.bSend(y)
  LCD.GetAck

PUB Rectangle(x,y)
{{
    Draws a rectangle from the current pixel coordinates to x,y using the object colour for fill
    if fill mode is solid and the border/outline color for the border.

    Parameters:
      x       pixel horizontal coordinate (0..Xmax) end
      y       pixel vertical coordinate (0..Ymax)   end

}}
  LCD.bSend(CMD_RECT)
  LCD.bSend(x)
  LCD.bSend(y)
  LCD.GetAck

PUB RectangleAt(x0,y0,x1,y1)
{{
    Draws a rectangle from the current pixel coordinates to x,y using the object colour for fill
    if fill mode is solid and the border/outline color for the border.

    Parameters:
      x0      pixel horizontal coordinate (0..Xmax) start
      y0      pixel vertical coordinate (0..Ymax)   start
      x1      pixel horizontal coordinate (0..Xmax) end
      y1      pixel vertical coordinate (0..Ymax)   end

}}
  LCD.bSend(CMD_MOVETOXY)
  LCD.bSend(x0)
  LCD.bSend(y0)
  LCD.GetAck
  LCD.bSend(CMD_RECT)
  LCD.bSend(x1)
  LCD.bSend(y1)
  LCD.GetAck

PUB Circle(r)
{{
    Draws a circle of radius r centered at the current pixel coordinates using the object colour for fill
    if fill mode is solid and the border/outline color for the border.

    Parameters:
      r       radius

}}
  LCD.bSend(CMD_CIRCLE)
  LCD.bSend(r)
  LCD.GetAck

PUB CircleAt(r,x,y)
{{
    Draws a circle of radius r centered at coordinates x,y using the object colour for fill
    if fill mode is solid and the border/outline color for the border.

    Parameters:
      r       radius
      x       pixel horizontal coordinate (0..Xmax) center
      y       pixel vertical coordinate (0..Ymax)   center

}}
  LCD.bSend(CMD_MOVETOXY)
  LCD.bSend(x)
  LCD.bSend(y)
  LCD.GetAck
  LCD.bSend(CMD_CIRCLE)
  LCD.bSend(r)
  LCD.GetAck

PUB EightLEDS(x,y,bits)
{{
    Renders a set of eight simulated LEDs (red green) arranged horizontally
    at specified pixel coordinates.

    The entire array is 80 pixels wide and 10 high.

    Parameters:
      x       pixel horizontal coordinate (0..Xmax)
      y       pixel vertical coordinate (0..Ymax)
      bits    eight bits corresponding to the eight LEDs
              displays red LED when bit is on
              displays green LED when bit is off

}}
  LCD.bSend(CMD_8LEDS)
  LCD.bSend(x)
  LCD.bSend(y)
  LCD.bSend(bits)
  LCD.GetAck

PUB OneLED(x,y,rgb)
{{
    Renders a similated LED in a specified colour at specified pixel coordinates.

    The simulated LED is 10 pixels wide and high, so to place one at the top left
    of the display and have it entirely visible use OneLed(5,5,<colour>).  Its origin
    is at the center of a circle with radius 5 pixels.

    Parameters:
      x       pixel horizontal coordinate (0..Xmax)
      y       pixel vertical coordinate (0..Ymax)
      rgb     16bit RGB color (565 format see constants)

}}
  LCD.bSend(CMD_1LED)
  LCD.bSend(x)
  LCD.bSend(y)
  LCD.wSend(rgb)
  LCD.GetAck

PUB MoveToCR(x,y)
{{
    Changes the current character position to the specified values (x,y).

    Parameters:
      x       character column position (0..17)
      y       character row position (0..16)

}}
  LCD.bSend(CMD_MOVETOCR)
  LCD.bSend(x)
  LCD.bSend(y)
  LCD.GetAck

PUB Newline
{{
    Advances current character vertical position by one row and resets the
    current character horizontal position to zero.
}}
  LCD.bSend(CMD_NEWLINE)
  LCD.GetAck

PUB Textsize(n)
{{
    Sets the current text scale factors to n.

    Parameters:
      n     text scaling on both x and y axes (1 or greater). 

}}
  LCD.bSend(CMD_TEXTSIZE)
  LCD.bSend(n#>1)
  LCD.GetAck

PUB SetStrAtIx(asz,ix)
{{
    Stores a string in the display's string table.

    Parameters:
      asz     address of zero terminated string (18 characters maximum not including trailing null)
      ix      string table index value (0 to 7)

}}
  LCD.bSend(CMD_SET_STRING_AT_IX)
  LCD.bSend(ix<#7#>0)
  LCD.SendBytes(asz, (strsize(asz)+1)<#19#>1)
  LCD.GetAck

PUB StrIx(ix) 
{{
    Causes a previously stored string to be rendered by the display at the current row and column.
    Use SetStrAtIx to preset the string table contents.

    Parameters:
      ix      string table index value (0 to 7)

}}
  LCD.bSend(CMD_STRING_IX)
  LCD.bSend(ix)
  LCD.GetAck

PUB StrIxAt(ix,x,y) 
{{
    Causes a previously stored string to be rendered by the display at row y and column x.
    Use SetStrAtIx to preset the string table contents.

    Parameters:
      ix      string table index value (0 to 7)
      x       character column position (0..17)
      y       character row position (0..16)

}}
  LCD.bSend(CMD_STRING_IX_AT)
  LCD.bSend(x)
  LCD.bSend(y)                                                  
  LCD.bSend(ix)
  LCD.GetAck

PUB Str(asz)
{{
    Causes a string to be rendered by the display at the current row and column.

    Parameters:
      asz     address of zero terminated string (18 characters maximum not including trailing null)

}}
  LCD.bSend(CMD_STRING)
  LCD.SendBytes(asz, (strsize(asz)+1)<#19#>1)
  LCD.GetAck

PUB StrAt(asz,x,y)
{{
    Causes a string to be rendered by the display at row y and column x.

    Parameters:
      asz     address of zero terminated string (18 characters maximum not including trailing null)
      x       character column position (0..17)
      y       character row position (0..16)

}}
  LCD.bSend(CMD_STRING_AT)
  LCD.bSend(x)
  LCD.bSend(y)
  LCD.SendBytes(asz, (strsize(asz)+1)<#19#>1)
  LCD.GetAck

PUB PrintDec(n,d)
{{
    Renders an decimal number with "d" decimal places at the current character position.

    Be sure to prescale the value n by either 10¹ or 10²corresponding to d before calling
    this function.

    For example:
      n     d     output
      123   1     12.3
            2     1.23

    Parameters:
      n       value to be rendered
      d       number of decimal places

}}
  case d#>1
      1: LCD.bSend(CMD_PRINT_DEC1)
      2: LCD.bSend(CMD_PRINT_DEC2)
  LCD.wSend(n)
  LCD.GetAck

PUB PrintDecAt(n,d,x,y)
{{
    Renders an decimal number with "d" decimal places at a specified current character position.

    Be sure to prescale the value n by either 10¹ or 10²corresponding to d before calling
    this function.

    For example:
      n     d     output
      123   1     12.3
            2     1.23

    Parameters:
      n       value to be rendered
      d       number of decimal places
      x       character column position (0..17)
      y       character row position (0..16)

}}
  case d
      1: LCD.bSend(CMD_PRINT_DEC1_AT)
      2: LCD.bSend(CMD_PRINT_DEC2_AT)
  LCD.bSend(x)
  LCD.bSend(y)
  LCD.wSend(n)
  LCD.GetAck

PUB PrintInt(n)
{{
    Renders an integer at the current character position.

    Parameters:
      n       value to be rendered

}}
  LCD.bSend(CMD_PRINT_INT)
  LCD.wSend(n)
  LCD.GetAck

PUB PrintIntAt(n,x,y)
{{
    Renders an integer at a specified character position.

    Parameters:
      n       value to be rendered
      x       character column position (0..17)
      y       character row position (0..16)

}}
  LCD.bSend(CMD_PRINT_INT_AT)
  LCD.bSend(x)
  LCD.bSend(y)
  LCD.wSend(n)
  LCD.GetAck

PUB Hexadecimal(v)
{{
    Renders an eight character hexadecimal representation of v at the current character position.
    
    Parameters:
      v       value to render as hexadecimal

}}
  Str(hex(v,8))
  
PUB Hex4(v)
{{
    Renders a four character hexadecimal representation of v at the current character position.

    Parameters:
      v       value to render as hexadecimal

}}
  Str(hex(v,4))
  
PUB Hex2(v)
{{
    Renders a two character hexadecimal representation of v at the current character position.

    Parameters:
      v       value to render as hexadecimal

}}
  Str(hex(v,2))

PUB Hex1(v)
{{
    Renders a one character hexadecimal representation of v at the current character position.

    Parameters:
      v       value to render as hexadecimal

}}
  Str(hex(v,1))

PUB HexadecimalAt(v,x,y)
{{
    Renders an eight character hexadecimal representation of v at a specified character position.

    Parameters:
      v       value to render as hexadecimal
      x       character column position (0..17)
      y       character row position (0..16)

}}
  StrAt(hex(v,8),x,y)
  
PUB Hex4At(v,x,y)
{{
    Renders a four character hexadecimal representation of v at a specified character position.

    Parameters:
      v       value to render as hexadecimal
      x       character column position (0..17)
      y       character row position (0..16)

}}
  StrAt(hex(v,4),x,y)
  
PUB Hex2At(v,x,y)
{{
    Renders a two character hexadecimal representation of v at a specified character position.

    Parameters:
      v       value to render as hexadecimal
      x       character column position (0..17)
      y       character row position (0..16)

}}
  StrAt(hex(v,2),x,y)

PUB Hex1At(v,x,y)
{{
    Renders a one character hexadecimal representation of v at a specified character position.

    Parameters:
      v       value to render as hexadecimal
      x       character column position (0..17)
      y       character row position (0..16)

}}
  StrAt(hex(v,1),x,y)

{{
''*  Simple_Numbers                      *
''*  Authors: Chip Gracey, Jon Williams  *
''*  Copyright (c) 2006 Parallax, Inc.   *

}}
CON

  MAX_STR_LEN = 64                                          ' 63 chars + zero terminator
  
VAR

  long  szidx                                             ' pointer into string
  byte  sznstr[MAX_STR_LEN]                                   ' string for numeric data


PRI dec(value)

' Returns pointer to signed-decimal string

  clrstr(@sznstr, MAX_STR_LEN)                                ' clear output string  
  return decstr(value)                                  ' return pointer to numeric string

PRI clrstr(strAddr, size)

' Clears string at strAddr
' -- also resets global character pointer (idx)

  bytefill(strAddr, 0, size)                            ' clear string to zeros
  szidx~                                                  ' reset index

  
PRI decstr(value) | div, z_pad   

' Converts value to signed-decimal string equivalent
' -- characters written to current position of idx
' -- returns pointer to nstr

  if (value < 0)                                        ' negative value? 
    -value                                              '   yes, make positive
    sznstr[szidx++] := "-"                                  '   and print sign indicator

  div := 1_000_000_000                                  ' initialize divisor
  z_pad~                                                ' clear zero-pad flag

  repeat 10
    if (value => div)                                   ' printable character?
      sznstr[szidx++] := (value / div + "0")                '   yes, print ASCII digit
      value //= div                                     '   update value
      z_pad~~                                           '   set zflag
    elseif z_pad or (div == 1)                          ' printing or last column?
      sznstr[szidx++] := "0"
    div /= 10 

  return @sznstr

PRI hex(value, digits)

' Returns pointer to a digits-wide hexadecimal string

  clrstr(@sznstr, MAX_STR_LEN) 
  return hexstr(value, digits)

PRI bin(value, digits)

' Returns pointer to a digits-wide binary string      

  clrstr(@sznstr, MAX_STR_LEN)
  return binstr(value, digits)   

PRI hexstr(value, digits)

' Converts value to digits-wide hexadecimal string equivalent
' -- characters written to current position of idx
' -- returns pointer to nstr

  digits := 1 #> digits <# 8                            ' qualify digits
  value <<= (8 - digits) << 2                           ' prep most significant digit
  repeat digits
    sznstr[szidx++] := lookupz((value <-= 4) & $F : "0".."9", "A".."F")

  return @sznstr
  

PRI binstr(value, digits)

' Converts value to digits-wide binary string equivalent
' -- characters written to current position of idx
' -- returns pointer to nstr

  digits := 1 #> digits <# 32                           ' qualify digits 
  value <<= 32 - digits                                 ' prep MSB
  repeat digits
    sznstr[szidx++] := (value <-= 1) & 1 + "0"              ' move digits (ASCII) to string

  return @sznstr

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