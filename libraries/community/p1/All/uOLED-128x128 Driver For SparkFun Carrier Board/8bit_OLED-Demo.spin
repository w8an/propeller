''**************************************
''
''  Demo for the 8-bit graphics and 8-bit display driver
''  for the uOLED-128-SPIN
''
''  Mark Swann
''  from code originally authored by
''  Timothy D. Swieter, E.I.
''  www.brilldea.com
''
''Description:
'' This program is a simple demo of the functions in the
'' 8 bit graphics driver.  This demo is intended for use
'' with a uOLED-128x128 carrier board from Sparkfun running
'' an 8 bit per pixel display driver.
''
''    
'**************************************
CON               'Constants to be located here
'***************************************
'  Processor Settings
'***************************************
  _clkmode = xtal1 + pll16x     'Use the PLL to multiple the external clock by 16
  _xinfreq = 5_000_000          'An external clock of 5MHz. is used (80MHz. operation)
' _xinfreq = 8_000_000          'An external clock of 8MHz. is used (64MHz. operation)
' _clkmode = xtal1 + pll8x      'Use the PLL to multiple the external clock by 8
' _xinfreq = 10_000_000         'An external clock of 10MHz. is used (80MHz. operation)

'***************************************
'  GUI Definitions
'***************************************
  'screen sizing constants for 256 color mode of uOLED-128x128
  _xpixels      = 128                                    'Screen width
  _ypixels      = 128                                    'Screen height          
  _pixelperlong = 4
  
  _screensize   = (_xpixels*_ypixels)/_pixelperlong     'Size needed for arrays

'***************************************
'  Color Definitions
'***************************************

  _red          = %11100000
  _green        = %00011100
  _blue         = %00000011
  _yellow       = %11111100
  _magenta      = %11100011
  _cyan         = %00011111
  _white        = %11111111
  _grey         = %01101101
  _black        = %00000000


'**************************************
VAR               'Variables to be located here
'***************************************

  'OLED display driver variables
  long MemDispA[_screensize]
  long  CurrFrameOut        'Address of the frame buffer being written to the display

'***************************************
OBJ               'Object declaration to be located here
'***************************************

  OLED          : "8bit_Display-Driver-v01.spin"
  Graphics      : "8bit_Graphics-Driver-v02.spin"
  Num           : "Numbers.spin"

'***************************************
PUB main 'The first PUB in the file is the first one executed
'***************************************
  dira[18]~~
  outa[18] := 0

  '**************************************
  '   Initialize the variables
  '**************************************
  
  'nada

  '**************************************
  '   Start the processes in their cogs
  '**************************************

  'Start the OLED driver
  OLED.start(@CurrFrameOut)

  'Start the graphics driver and it up for operation
  Graphics.setup(@MemDispA, @MemDispA, _xpixels, _ypixels, @CurrFrameOut)

  \DoDemo

  Graphics.frameWait
  Graphics.clear
  Graphics.endFrame
  Graphics.SetFont(1)
  Graphics.plotText(0,1,0, _white, string("Bye"))
  Graphics.endFrame
  PauseMSec(2000)
  Graphics.clear
  Graphics.endFrame
  Graphics.frameWait

  Graphics.stop
  OLED.stop
  PauseMSec(100)
  outa[18] := 1
  repeat

PRI DoDemo
  '**************************************
  '   Begin the demo
  '**************************************

  repeat                        'forever loop through the demo
    splash
    wipes
    circles
    fillCircles
    lines
    colors
    text
    Graphics.selectFrontSurface
    Graphics.clear
    Graphics.endFrame
    PauseMSec(1000)

PRI CheckPowerDown
   if ina[25] == 0
      abort


'***************************************
PUB splash | x
'***************************************
'' To be used with the 8-bit display driver and 8-bit graphics driver
'' Display an "icon" (or sprite) and text

  Graphics.selectFrontSurface

  repeat x from -96 to 128 step 2
    CheckPowerDown
    Graphics.frameWait
    Graphics.clear
    Graphics.plotText(0,0,2, _green, string("  OLED 128x128  "))
    Graphics.plotText(0,2,2, _yellow, string(" Propeller Demo "))
    Graphics.plotText(0,14,2, _white, string("  8-bit Driver  "))
    Graphics.plotSprite(x,40, @PropLogo)                  'Copy in the "icon"
    Graphics.endFrame
  
  repeat x from -96 to 32 step 2
    CheckPowerDown
    Graphics.frameWait
    Graphics.clear
    Graphics.plotText(0,0,2, _green, string("  OLED 128x128  "))
    Graphics.plotText(0,2,2, _yellow, string(" Propeller Demo "))
    Graphics.plotText(0,14,2, _white, string("  8-bit Driver  "))
    Graphics.plotSprite(x,40, @PropLogo)                  'Copy in the "icon"
    Graphics.endFrame

  repeat x from 31 to 16 step 2
    CheckPowerDown
    Graphics.frameWait
    Graphics.clear
    Graphics.plotText(0,0,2, _green, string("  OLED 128x128  "))
    Graphics.plotText(0,2,2, _yellow, string(" Propeller Demo "))
    Graphics.plotText(0,14,2, _white, string("  8-bit Driver  "))
    Graphics.plotSprite(x,40, @PropLogo)                  'Copy in the "icon"
    Graphics.endFrame

  Graphics.frameWait
  PauseMSec(3000)

'***************************************
PUB wipes | x, y
'***************************************
'' To be used with the 8-bit display driver and 8-bit graphics driver
'' wipe various colors across the screen

  Graphics.selectFrontSurface

  Graphics.SetColor(_white)
  repeat x from 0 to 127                                 'Animated wipe left to right
    CheckPowerDown
    Graphics.frameWait
    Graphics.plotVertLine(x,0,127)
    Graphics.endFrame
    'PauseMSec(10)

  Graphics.SetColor(_green)
  repeat x from 127 to 0                                 'Animated wipe right to left
    CheckPowerDown
    Graphics.frameWait
    Graphics.plotVertLine(x,0,127)
    Graphics.endFrame
    'PauseMSec(10)

  Graphics.SetColor(_red)
  repeat y from 0 to 127                                 'Animated wipe top to bottom
    CheckPowerDown
    Graphics.frameWait
    Graphics.plotHorizLine(0, 127,y)
    Graphics.endFrame
    'PauseMSec(10)

  Graphics.SetColor(_yellow)
  repeat y from 127 to 0                                 'Animated wipe bottom to top
    CheckPowerDown
    Graphics.frameWait
    Graphics.plotHorizLine(0, 127,y)
    Graphics.endFrame
    'PauseMSec(10)

  Graphics.SetColor(_cyan)
  repeat x from 0 to 127                                 'Animated wipe left to right
    CheckPowerDown
    Graphics.frameWait
    Graphics.plotVertLine(x,0,127)
    Graphics.endFrame
    'PauseMSec(5)

  Graphics.SetColor(_black)
  repeat x from 127 to 0                                 'Animated wipe right to left
    CheckPowerDown
    Graphics.frameWait
    Graphics.plotVertLine(x,0,127)
    Graphics.endFrame
    'PauseMSec(5)


'***************************************
PUB circles | i, color
'***************************************
'' To be used with the 8-bit display driver and 8-bit graphics driver
'' draw and animate colored circles

  'Graphics.selectBackSurface
  Graphics.selectFrontSurface

  repeat color from 0 to 255
    repeat i from 1 to 58
      CheckPowerDown
      Graphics.frameWait
      Graphics.clear
      Graphics.plotCircleC(64,64,i+5, color)
      color++
      Graphics.plotCircleC(64,64,i, color)
      color++
      Graphics.plotCircleC(64,64,i-5, color)
      Graphics.plotText(0,1,0, _white, Num.ToStr(OLED.frameStat, Num#DEC))
      Graphics.endFrame
      PauseMSec(10)

    repeat i from 57 to 1
      CheckPowerDown
      Graphics.frameWait
      Graphics.clear
      color++
      Graphics.plotCircleC(64,64,i+5, color)
      color++
      Graphics.plotCircleC(64,64,i, color)
      color++
      Graphics.plotCircleC(64,64,i-5, color)
      Graphics.plotText(0,1,0, _white, Num.ToStr(OLED.frameStat, Num#DEC))
      Graphics.endFrame
      PauseMSec(10)

'***************************************
PUB fillCircles | i, jj
'***************************************
'' To be used with the 8-bit display driver and 8-bit graphics driver
'' draw and animate colored circles

  'Graphics.selectBackSurface
  Graphics.selectFrontSurface

  repeat 2
    repeat i from 1 to 58
      CheckPowerDown
      Graphics.frameWait
      Graphics.clear
      Graphics.setFillColor(_red)
      Graphics.fillCircle(64,64,i+5)
      Graphics.setFillColor(_green)
      Graphics.fillCircle(64,64,i)
      Graphics.setFillColor(_blue)
      Graphics.fillCircle(64,64,i-5)
      Graphics.plotText(0,1,0, _white, Num.ToStr(OLED.frameStat, Num#DEC))
      Graphics.endFrame
      PauseMSec(10)

    repeat i from 57 to 1
      CheckPowerDown
      Graphics.frameWait
      Graphics.clear
      Graphics.setFillColor(_red)
      Graphics.fillCircle(64,64,i+5)
      Graphics.setFillColor(_green)
      Graphics.fillCircle(64,64,i)
      Graphics.setFillColor(_blue)
      Graphics.fillCircle(64,64,i-5)
      Graphics.plotText(0,1,0, _white, Num.ToStr(OLED.frameStat, Num#DEC))
      Graphics.endFrame
      PauseMSec(10)

'***************************************
PUB lines | eraser_count, color, i
'***************************************
'' To be used with the 8-bit display driver and 8-bit graphics driver
'' draw and animate colored lines

  eraser_count := 0
  color := 0

  plines[0] := 10
  plines[1] := 3
  plines[2] := 50
  plines[3] := 60

  plines[4] := 10
  plines[5] := 3
  plines[6] := 50
  plines[7] := 60

  vlines[0] := 1
  vlines[1] := 2
  vlines[2] := -3
  vlines[3] := 5

  vlines[4] := 1
  vlines[5] := 2
  vlines[6] := -3
  vlines[7] := 5


  Graphics.selectFrontSurface

  Graphics.clear    

  repeat 750

    CheckPowerDown

    color++

    if color == 0
      color++

    Graphics.frameWait

    if (++eraser_count > 7)
     
      Graphics.plotLineC(plines[4], plines[5], plines[6], plines[7], _black)
     
      plines[4] += vlines[4]
      plines[5] += vlines[5]
     
      plines[6] += vlines[6]
      plines[7] += vlines[7]
     
      if (plines[4] > 127)
        vlines[4] := -vlines[4]
        plines[4] += vlines[4]
     
      if (plines[6] > 127)
        vlines[6] := -vlines[6]
        plines[6] += vlines[6]
     
      if (plines[5] > 127)
        vlines[5] := -vlines[5]
        plines[5] += vlines[5]
     
      if (plines[7] > 127)
        vlines[7] := -vlines[7]
        plines[7] += vlines[7]
  
    Graphics.plotLineC(plines[0], plines[1], plines[2], plines[3], color>>1)

    plines[0] += vlines[0]
    plines[1] += vlines[1]

    plines[2] += vlines[2]
    plines[3] += vlines[3]

    if (plines[0] > 127)
      vlines[0] := -vlines[0]
      plines[0] += vlines[0]
     
    if (plines[2] > 127)
      vlines[2] := -vlines[2]
      plines[2] += vlines[2]
     
    if (plines[1] > 127)
      vlines[1] := -vlines[1]
      plines[1] += vlines[1]
     
    if (plines[3] > 127)
      vlines[3] := -vlines[3]
      plines[3] += vlines[3]
     
    Graphics.endFrame
    PauseMSec(20)
    'repeat i from 0 to 100 + 3*(eraser_count // 10)

  Graphics.clear
  Graphics.endFrame
  CheckPowerDown

'***************************************
PUB colors | x, y, pix, color
'***************************************
'' To be used with the 8-bit display driver and 8-bit graphics driver
'' draw the 256 color spectrum on the screen

  Graphics.selectFrontSurface

  x := 0
  y := 0
  pix := 0
  color := 0

  Graphics.frameWait
  Graphics.clear       
  repeat x from 0 to 126
    CheckPowerDown
    Graphics.SetColor(%00000000)
    repeat y from 0 to 15
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%00100000)
    repeat y from 15 to 31
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%01000000)
    repeat y from 32 to 47
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%01100000)
    repeat y from 48 to 63
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%10000000)
    repeat y from 64 to 79
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%10100000)
    repeat y from 80 to 96
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%11000000)
    repeat y from 96 to 111
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%11100000)
    repeat y from 112 to 127
      Graphics.plotPixel(x, y)

  CheckPowerDown
  Graphics.endFrame
  PauseMSec(1500)                      
   
  Graphics.clear               
  repeat x from 0 to 126
    CheckPowerDown
    Graphics.SetColor(%00000000)
    repeat y from 0 to 15
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%00000100)
    repeat y from 15 to 31
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%00001000)
    repeat y from 32 to 47
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%00001100)
    repeat y from 48 to 63
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%00010000)
    repeat y from 64 to 79
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%00010100)
    repeat y from 80 to 96
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%00011000)
    repeat y from 96 to 111
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%00011100)
    repeat y from 112 to 127
      Graphics.plotPixel(x, y)
   
  Graphics.endFrame
  PauseMSec(1500)                         
  CheckPowerDown
   
  Graphics.clear               
  repeat x from 0 to 126
    CheckPowerDown
    Graphics.SetColor(%00000000)
    repeat y from 0 to 31
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%00000001)
    repeat y from 32 to 63
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%00000010)
    repeat y from 64 to 95
      Graphics.plotPixel(x, y)
    Graphics.SetColor(%00000011)
    repeat y from 96 to 127
      Graphics.plotPixel(x, y)

    
  Graphics.endFrame
  PauseMSec(1500)
  CheckPowerDown

  Graphics.clear
  repeat x from 0 to 15
    repeat y from 0 to 28
      CheckPowerDown
      Graphics.SetColor(color)
      repeat pix from 0 to 7
        Graphics.plotPixel((x*8)+pix, (y*4)+0)
        Graphics.plotPixel((x*8)+pix, (y*4)+1)
        Graphics.plotPixel((x*8)+pix, (y*4)+2)
        Graphics.plotPixel((x*8)+pix, (y*4)+3)
      color++      

  Graphics.endFrame
  PauseMSec(2000)  

  Graphics.clear
  Graphics.endFrame


'***************************************
PUB text | x, color 
'***************************************
'' To be used with the 8-bit display driver and 8-bit graphics driver
'' draw various text on the screen

  'Graphics.selectBackSurface
  Graphics.selectFrontSurface

  Graphics.setFillColor(_black)

  repeat 3
    color++
       
    repeat x from 0 to 15
      CheckPowerDown

      Graphics.frameWait
      Graphics.clear
    
      Graphics.SetFont(2)

      Graphics.plotCharC("F",  3, x, _blue)
      Graphics.plotCharC("r",  4, x, _yellow)
      Graphics.plotCharC("u",  5, x, _red)
      Graphics.plotCharC("i",  6, x, _green)
      Graphics.plotCharC("t",  7, x, _white)
      Graphics.plotCharC("S",  8, x, _magenta)
      Graphics.plotCharC("a",  9, x, _cyan)
      Graphics.plotCharC("l", 10, x, _yellow)
      Graphics.plotCharC("a", 11, x, _red)
      Graphics.plotCharC("d", 12, x, _magenta)
    
      Graphics.plotText(x,6,0, color, string(" Testing"))
      Graphics.plotText(x,8,0, color, string("1, 2, 3.."))

      Graphics.endFrame
      PauseMSec(70)

    color++

    repeat x from 15 to 0
      CheckPowerDown

      Graphics.frameWait
      Graphics.clear
    
      Graphics.SetFont(2)

      Graphics.plotCharC("F",  3, x, _blue)
      Graphics.plotCharC("r",  4, x, _yellow)
      Graphics.plotCharC("u",  5, x, _red)
      Graphics.plotCharC("i",  6, x, _green)
      Graphics.plotCharC("t",  7, x, _white)
      Graphics.plotCharC("S",  8, x, _magenta)
      Graphics.plotCharC("a",  9, x, _cyan)
      Graphics.plotCharC("l", 10, x, _yellow)
      Graphics.plotCharC("a", 11, x, _red)
      Graphics.plotCharC("d", 12, x, _magenta)

      Graphics.plotText(x,6,0, color, string(" Testing"))
      Graphics.plotText(x,8,0, color, string("1, 2, 3.."))

      Graphics.endFrame
      PauseMSec(70)

  Graphics.frameWait
  Graphics.clear
  Graphics.endFrame
  Graphics.frameWait
  CheckPowerDown


PRI pauseMSec(Duration)
'' Pause execution in milliseconds.
'' Duration = number of milliseconds to delay
  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)


DAT

PropLogo        long
                byte    96, 64, 0, 0
                long    $00 ' transparent color

        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$20,$20,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$40,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$20,$40,$60,$60,$60,$80,$80,$A0,$A4,$A4,$A4,$A4,$A4,$C4,$C4,$C4,$C0,$C4,$C4,$C4,$C4,$A0,$A0,$20,$20,$00,$00
        byte    $00,$00,$00,$00,$00,$20,$20,$20,$20,$20,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$20,$20,$20,$40,$60,$80,$80,$A4,$A4,$A4,$C4,$C4,$A4,$A4,$A4,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$A0,$A0,$40,$00
        byte    $00,$00,$20,$20,$80,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$80,$40,$20,$20,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$20,$20,$20,$40,$80,$A0,$A4,$A4,$A4,$C4,$C4,$C4,$C4,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$A0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$A0,$00
        byte    $00,$40,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C4,$A4,$A0,$A0,$A0,$60,$40,$20,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$40,$80,$80,$60,$00,$00,$40,$40,$40,$80,$A0,$A4,$A4,$C4,$C4,$A4,$A4,$A4,$C0,$A0,$A0,$A0,$A0,$A0,$A0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$40
        byte    $00,$A0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C4,$C0,$C4,$A4,$A4,$A0,$A0,$80,$60,$60,$60,$60,$40,$40,$40,$40,$40,$40,$20,$20,$20,$20,$20,$20,$20,$20,$40,$84,$C4,$C4,$A4,$84,$A0,$A4,$A4,$A4,$A4,$A4,$A4,$A4,$A0,$A0,$A0,$A0,$A0,$C4,$C4,$C4,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$60
        byte    $20,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C4,$C4,$C4,$C4,$C0,$C4,$C4,$C4,$A4,$A4,$A4,$A4,$A4,$A4,$A4,$A4,$A4,$A4,$84,$80,$84,$A0,$A0,$84,$40,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$40,$40,$40,$40,$60,$80,$A0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$20
        byte    $00,$A0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C4,$C4,$A4,$A4,$A0,$80,$60,$40,$40,$00,$00,$40,$A8,$A8,$64,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$20,$20,$40,$60,$80,$A0,$A0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$60,$00
        byte    $00,$60,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C4,$A0,$A0,$80,$60,$40,$20,$20,$00,$00,$00,$00,$00,$00,$00,$20,$EC,$EC,$44,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$40,$60,$80,$80,$80,$A0,$A0,$A0,$A0,$A0,$A0,$80,$40,$40,$00,$00
        byte    $00,$00,$80,$80,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$A0,$A0,$80,$40,$40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$24,$B2,$B2,$49,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$60,$A0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0,$A0,$A0,$A0,$60,$60,$40,$40,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$53,$7B,$7B,$57,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$20,$40,$40,$60,$60,$60,$60,$60,$60,$40,$40,$20,$20,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$32,$57,$57,$53,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$29,$57,$57,$2E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$53,$77,$77,$77,$29,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$2E,$57,$77,$77,$77,$52,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$2E,$57,$57,$57,$57,$33,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$33,$53,$53,$53,$09,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$28,$4C,$4C,$90,$90,$D5,$D4,$D4,$D5,$90,$90,$6C,$6C,$28,$24,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$4E,$4E,$72,$BA,$FC,$FC,$FC,$FC,$F8,$F4,$F4,$F4,$F4,$F4,$FC,$FC,$FC,$FC,$DD,$96,$4E,$4E,$25,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$4E,$72,$97,$DE,$DE,$FD,$FC,$FC,$FC,$FC,$F8,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$FC,$FC,$FC,$FC,$FC,$DD,$DD,$96,$73,$4E,$25,$25,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$24,$4E,$77,$77,$97,$BA,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F8,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$DD,$97,$77,$77,$72,$29,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$29,$77,$97,$97,$97,$BA,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F8,$F8,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$DD,$97,$97,$97,$97,$4E,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$24,$72,$72,$97,$77,$97,$DA,$DA,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$DD,$DD,$97,$77,$97,$77,$77,$29,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$49,$77,$77,$77,$77,$97,$DD,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F8,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FD,$97,$77,$77,$77,$77,$4E,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$52,$77,$77,$77,$77,$97,$DD,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$96,$77,$77,$77,$77,$73,$25,$25,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$52,$52,$77,$77,$77,$77,$77,$BA,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F0,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$DD,$97,$97,$77,$77,$77,$73,$73,$25,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$25,$72,$77,$77,$77,$77,$77,$BA,$BA,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F8,$F0,$F0,$F0,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F4,$F0,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$D9,$D9,$77,$77,$77,$77,$77,$77,$29,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$73,$77,$77,$77,$77,$77,$97,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F8,$F0,$F0,$F0,$F0,$F4,$F4,$F4,$F4,$F4,$F4,$F0,$F0,$F0,$F0,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$BA,$77,$77,$77,$77,$77,$77,$29,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$52,$77,$77,$77,$77,$77,$77,$DD,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F4,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$97,$77,$77,$77,$77,$77,$73,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$52,$52,$77,$77,$77,$77,$77,$77,$BA,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$D9,$77,$77,$77,$77,$77,$77,$73,$73,$25,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$4E,$77,$77,$77,$77,$77,$77,$77,$97,$FD,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F8,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$96,$77,$77,$77,$77,$77,$77,$77,$52,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$25,$77,$77,$77,$77,$77,$77,$77,$77,$BA,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F8,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$DD,$97,$97,$77,$77,$77,$77,$77,$77,$2E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$52,$77,$77,$77,$77,$77,$77,$97,$97,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F8,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$9A,$9A,$77,$77,$77,$77,$77,$77,$57,$29,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$4E,$77,$77,$77,$77,$77,$77,$77,$BA,$BA,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F4,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$DD,$DD,$77,$77,$77,$77,$77,$77,$57,$53,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$05,$53,$57,$77,$77,$77,$77,$77,$77,$DD,$DD,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F8,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$96,$77,$77,$77,$77,$77,$57,$57,$29,$29,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$4E,$4E,$57,$53,$77,$77,$77,$77,$77,$9A,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$D0,$F4,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$BA,$77,$77,$77,$77,$77,$57,$57,$53,$53,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$25,$53,$53,$53,$53,$77,$77,$77,$77,$77,$B9,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F8,$F8,$D0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$D0,$F4,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$77,$77,$77,$77,$77,$77,$53,$57,$57,$2E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$32,$53,$53,$53,$53,$77,$77,$77,$77,$97,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F8,$F8,$D0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$D0,$F4,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$BA,$77,$77,$77,$77,$77,$53,$53,$53,$53,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$53,$53,$53,$53,$57,$77,$77,$77,$77,$BA,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F4,$F4,$D0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$D0,$F4,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$D9,$77,$77,$77,$77,$57,$53,$53,$53,$53,$2E,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$2E,$53,$53,$53,$53,$53,$77,$77,$77,$77,$D9,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F4,$F4,$D0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FD,$77,$77,$77,$77,$53,$53,$53,$53,$53,$32,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$33,$53,$53,$53,$53,$53,$77,$77,$77,$77,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F4,$F4,$D0,$D0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$F0,$D0,$D0,$F0,$F0,$D0,$F0,$F0,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$96,$77,$77,$77,$53,$53,$53,$53,$53,$53,$29,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$29,$33,$53,$53,$53,$53,$53,$77,$77,$77,$96,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F0,$F0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$F0,$F0,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$B9,$77,$77,$77,$53,$53,$53,$53,$53,$53,$2E,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$2E,$33,$53,$53,$53,$53,$53,$77,$53,$53,$B9,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F0,$F0,$CC,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$D9,$77,$77,$77,$53,$53,$53,$53,$53,$33,$33,$05,$05,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$05,$05,$33,$33,$53,$53,$53,$53,$53,$53,$77,$77,$D9,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F0,$F0,$CC,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$EC,$EC,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$DD,$77,$77,$57,$53,$53,$53,$53,$53,$33,$33,$29,$29,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$29,$29,$33,$33,$33,$53,$53,$53,$53,$53,$77,$77,$DD,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$D0,$D0,$CC,$CC,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$D0,$CC,$CC,$CC,$CC,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$77,$77,$53,$53,$53,$53,$53,$53,$33,$33,$2E,$2E,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$2E,$2E,$33,$33,$33,$53,$53,$53,$53,$53,$77,$77,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$D0,$D0,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$9A,$9A,$53,$53,$53,$53,$53,$53,$33,$33,$2E,$2E,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$2E,$2E,$33,$33,$33,$53,$53,$53,$53,$53,$76,$76,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$CC,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$B9,$B9,$53,$53,$53,$53,$53,$33,$33,$33,$33,$33,$05,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$04,$33,$33,$33,$33,$33,$53,$53,$53,$53,$53,$BA,$BA,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F8,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$EC,$F4,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$DD,$DD,$53,$53,$53,$53,$53,$33,$33,$33,$33,$33,$09,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$05,$33,$33,$33,$33,$33,$33,$33,$53,$53,$53,$B9,$B9,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$DC,$D8,$D9,$B9,$B9,$B9,$B9,$95,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$8D,$91,$B9,$B9,$B9,$B9,$D9,$D9,$DC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$77,$53,$53,$53,$53,$33,$33,$33,$33,$33,$29,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$09,$33,$33,$33,$33,$33,$33,$33,$53,$53,$53,$D9,$D9,$FC,$D8,$D9,$B9,$B9,$95,$76,$52,$4E,$4E,$2E,$2E,$2E,$2E,$2E,$2E,$2F,$2F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$0F,$2F,$2F,$2E,$2E,$2E,$2E,$2E,$2E,$2E,$4E,$72,$95,$B5,$B5,$B9,$D9,$FC,$FC,$FC,$76,$53,$53,$33,$33,$33,$33,$33,$33,$33,$2E,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$09,$33,$33,$33,$33,$33,$33,$33,$33,$53,$52,$72,$72,$52,$2E,$2E,$2F,$2F,$0F,$0F,$0F,$2F,$2F,$2F,$2E,$2E,$2E,$2E,$2E,$2E,$2E,$2E,$2E,$4E,$4E,$4E,$4E,$4E,$6D,$6D,$6D,$6D,$6D,$6D,$6D,$6D,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$2E,$2E,$2E,$2E,$2E,$2E,$2E,$2F,$2F,$2F,$0F,$0F,$0F,$2F,$2F,$2E,$2E,$2E,$72,$72,$52,$33,$53,$33,$33,$33,$33,$33,$33,$33,$2E,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$2A,$33,$33,$33,$33,$32,$2E,$2E,$2E,$2E,$2E,$0F,$0F,$2F,$2E,$2E,$2E,$2E,$4E,$72,$95,$95,$95,$95,$B5,$B5,$B5,$B5,$B9,$B9,$D8,$D8,$D8,$D0,$AC,$AC,$AC,$AC,$AC,$CC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$D8,$D8,$D8,$D9,$B9,$B5,$B5,$B5,$B5,$95,$95,$95,$95,$72,$4E,$2E,$2E,$2E,$2E,$2F,$0F,$0F,$2F,$2E,$2E,$2E,$2E,$2E,$33,$33,$33,$33,$2E,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$2E,$33,$33,$2E,$2E,$2E,$2E,$2E,$2F,$2F,$2E,$72,$72,$95,$B5,$B5,$B8,$B8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$B0,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$B5,$B5,$95,$71,$71,$4E,$2E,$2F,$2E,$2E,$2E,$2E,$2E,$2E,$2E,$2E,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$2E,$2E,$2E,$2E,$2E,$2E,$32,$32,$72,$95,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$B0,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$D4,$D4,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$B5,$71,$52,$52,$2E,$2E,$2E,$2E,$2E,$2F,$05,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$2E,$2E,$2E,$2E,$2E,$0E,$95,$95,$F8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$D4,$D4,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$F8,$B5,$B5,$2E,$2E,$2E,$2E,$2E,$2E,$04,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$2E,$2E,$2E,$2E,$2E,$2E,$95,$95,$F8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$D4,$D4,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$B8,$B8,$2E,$2E,$2E,$2E,$2E,$2E,$04,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$2E,$2E,$2E,$2E,$2E,$2E,$B5,$B5,$F8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$D0,$D0,$DC,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$F8,$D8,$D8,$2E,$2E,$2E,$2E,$2E,$2E,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$05,$2E,$2E,$2E,$2E,$2E,$B5,$B5,$FC,$FC,$F8,$F8,$F8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$DC,$D4,$D4,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$D0,$D0,$DC,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$D8,$F8,$FC,$FC,$D8,$D8,$2E,$2E,$2E,$2E,$2E,$2A,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$05,$05,$2E,$2E,$2E,$2E,$2E,$72,$95,$B9,$D8,$D8,$F8,$FC,$FC,$FC,$FC,$FC,$F8,$F8,$D8,$D8,$F8,$F8,$F8,$F8,$F8,$F8,$F8,$FC,$D4,$D4,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$D0,$D0,$FC,$F8,$F8,$D8,$D8,$D8,$D8,$D8,$F8,$F8,$F8,$F8,$FC,$FC,$FC,$FC,$FC,$F8,$D8,$D8,$D8,$B5,$75,$4E,$4E,$2E,$2E,$2E,$29,$29,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$29,$2E,$2F,$2F,$2F,$2F,$2E,$2E,$2E,$52,$95,$B9,$D8,$D8,$F8,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$D4,$D4,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$D0,$D0,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$FC,$F8,$F8,$D9,$95,$72,$2E,$2E,$2E,$2F,$2F,$2F,$2F,$2E,$2E,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$05,$29,$2E,$2E,$2F,$2F,$2F,$2F,$2F,$2E,$2E,$52,$52,$72,$75,$75,$95,$B5,$B5,$D9,$D9,$D8,$FC,$FC,$D4,$D4,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$AC,$D0,$D0,$FC,$FC,$D8,$D9,$D9,$B9,$B5,$95,$95,$95,$72,$72,$52,$4E,$4E,$2E,$2F,$2F,$2F,$2F,$2E,$2E,$2A,$05,$05,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$05,$05,$05,$2A,$2E,$2E,$2E,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2E,$2E,$2E,$2E,$52,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$4E,$52,$2E,$2E,$2E,$2E,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2E,$2A,$29,$05,$05,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$05,$05,$09,$2A,$2A,$2E,$2E,$2E,$2E,$2E,$2E,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2F,$2E,$2E,$2E,$2E,$2E,$2E,$2A,$2A,$09,$09,$05,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
        byte    $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$04,$04,$04,$04,$05,$05,$05,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$29,$05,$05,$05,$05,$05,$04,$04,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

' data structure is array of points, each point is in x,y form, each line needs two points
plines                  word 10,3 ' line 1, endpoint 1
                        word 50,60' line 1, endpoint 2
                        
                        word 10,3 ' line 2, endpoint 1
                        word 50,60' line 2, endpoint 2

'data structure is an array of velocity vectors in vx, vy form, each pair of numbers used to translate a point
vlines                  word    1,2   ' line 1, endpoint 1 velocity
                        word    -3,5  ' line 1, endpoint 2 velocity

                        word    1,2   ' line 2, endpoint 1 velocity
                        word    -3,5  ' line 2, endpoint 2 velocity


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