'' ┌──────────────────────────────────────────────────────────────────────────┐
'' │ One Pin TV Text Driver used as Debug screen                        v1.04 │
'' ├──────────────────────────────────────────────────────────────────────────┤
'' │  Authors:  (c) 2009 Eric Ball                        (original 1-pinTV)  │
'' │            (c) 2010 "Cluso99" (Ray Rodrick)          (modificatons)      │
'' │            AiChip_SmallFont_Atari_lsb_001.spin       (font)              │
'' │  License   MIT License - See end of file for terms of use                │
'' └──────────────────────────────────────────────────────────────────────────┘
'' One Pin TV Text Driver demo (C) 2009-07-09 Eric Ball
'' Font included is from "AiChip_SmallFont_Atari_lsb_001.spin"  (by hippy???)
'' Modified by Cluso99:
'' RR20100214   _rr015  working for 64x28 NTSC & 64x32 PAL @5MHz
''                        added debug to show calculated values
'' RR20100215   _rr016  remove msb font mode (if reqd, reverse the font in hub)
''              _rr017  remove standby check & function (i.e. do setup once only)
''              _rr018
''              _rr019  use cog screen buffer 1024 bytes (64x16)
''              _rr020  cog screen buffer (40x16)
'' RR20100219   _rr022  cog font (only lsb font supported)
''                       (works but short of font space)
''              _rr023  add inverse bit8
''              _rr025  remove calcs, fix for 5MHz 40x25 chars, ok
''                      test release
''              _rr026  remove all parameter calcs (use "1pinTV_calcs.spin" to calculate parameters)
''              _rr027  add ASCII subset to cog (not VT100) 
''              _rr033  cls, bs, cr, lf working except does not scroll
'' RR20100220   _rr035  add flashing cursor, can, home, right, left, up, down (left/right bug)
''              _rr037  scroll, left, right working :-)
''              _rr038  test with 1-pin Keyboard
''              _rr040  automatically set for 5MHz,6.25, 6.5, 13.5MHz xtal values for ifrqa in xfrqa
'' RR20100226   _rr041  tested ok.
'' RR20100228   Debug version: Rename "Debug_1pinTV.spin" and modify.
''              Output methods: chr/out/tx, str, dec, hex
'' RR20100302   v1.01   add PAL parameters
'' RR20100304   v1.02   modify font to speed up pix generation (each long is stored in a seperate half font)
''                       saved 2 instrctions in :active loop
''              v1.03   add constants for 64x25 & 80x25 NTSC and test various clock frequencies
'' RR20100306   v1.04   remove double height option
'' RR20100315   v1.05   change call doblank2 -> doblank (saves space) at lines 1797
''                      movs vscl,xsync & movs vscl,xbackp s/be mov
'' RR20100318   v1.06   use hub TV cog code for screen buffer
''                        (note that for 80*25 DAT will need extending to prevent overwrite)
'' RR20100318   v1.07   DAT extended to take care in case screen is 80*25
'' RR20100318   v1.08   add methods clear, home, gotoxy, cr (in spin)


'' NTSC 40x25:   80MHz works
'' NTSC 64x25:   80MHz works   with inverse removed
''               96MHz works   
'' NTSC 80x25:   96MHz flicker with inverse removed
''              104MHz works   with inverse removed
''              108MHz works   with inverse removed
'' To remove inverse, comment these two lines in :active
''              '           test    char, #$80      wc      ' inverse?
''              '   if_c    xor     char, #$FF              ' inverse
 

'' 1 pin works with any TV resistor (100R - 1K1) without the RC network although 270R is preferred

' ─────────────────────────────────────────────────────────────────────────────
' 1-pin composite video (TV) circuit...
' You will not get colors, just white on black.
' Acknowledgement: Phil Pilgrim for the circuit and Eric Ball for the driver
'
'                                 270R(*124R)                    
'            ┌───────────────┳──┳─────────────── P22 = SO
'       TV  •┐   (*191R)nc    nc(*470pF)                 
'              ┴             ┴  ┴                   
'                  *see http://forums.parallax.com/forums/default.aspx?f=25&m=340731&g=342216
'
' Note: The existing resistors seem fine. Anything from 270R to 1K1 has been tried (270R is better)
'       If you want to try this out, you can just use your existing video circuit without change.
' ─────────────────────────────────────────────────────────────────────────────
'
'
' The following parameters are passed to this routine (shown here as an example only)
'       tvPina = 12             'not used 
'       tvPinb = 13             'not used
'       tvPinc = 14             'TV pin (1-pin version)  (best pin to use if trying on existing circuit)
'       tvPind = 15             'not used
' ─────────────────────────────────────────────────────────────────────────────


CON
' fixed parameters (use "1pinTV_calcs.spin" to calculate the following parameters) 
'--------------------------------------------------------------------------------------------------
'Maximum screen size is 80*25 since it uses the hub space occupied by the cog code.


'' NTSC 40x25
omode                   =       $801                    ' NTSC, single line res
                                                        ' [1..0]    01 = NTSC(262@60),       10 = PAL (312@50)
                                                        ' [2]        0 = single line res,     1 = double line res
                                                        ' [3]        0 = lsb first font
                                                        ' [4..5]    00 = undefined                                             
                                                        ' [6]        0 = default pixel clock, 1 = use op_pixelclk
                                                        ' [7]        0 = default blank duty,  1 = use op_blankfrq
                                                        ' [11..8] 1000 = 8 pixels per character
ocols                   =       40                      ' number of columns
orows                   =       25                      ' number of rows
'ocolsfrq                =       22_478                  ' Hz per active pixel
oequal1                 =       6                       ' number of equalization pulses
oserr                   =       6                       ' number of serration pulses
oequal2                 =       6                       ' number of equalization pulses
oblank1                 =       32                      ' number of blank lines
oactive                 =       200                     ' number of active lines
oblank2                 =       21                      ' number of blank lines
'otsync                  =       39                      ' temp sync pulse 
ohalf                   =       4324                    ' VSCL half line
obackp                  =       4158                    ' VSCL back porch (sync to active)
ofrontp                 =       4137                    ' VSCL front porch (active to sync)
oequal                  =       4112                    ' VSCL equalization pulse (sync/2)
osync                   =       4129                    ' VSCL sync pulse
osynch                  =       4291                    ' VSCL half-sync
oequalh                 =       4308                    ' VSCL half-equal
ovsclch                 =       4104                    ' VSCL character
ictra                   =       11                      ' CTRA with PLLdiv
ifrqa                   =       386169088               ' required FRQA value (5MHz*16) (xfrqa replaced by start routine)
ifrqb                   =       $4924_0000              ' 40/140 << 32 = 1,227,096,064

ifrqa_80MHz             =       386169088               ' required FRQA value (5MHz*16)
ifrqa_96MHz             =       321807584               ' required FRQA value (6MHz*16)
ifrqa_100MHz            =       308935280               ' required FRQA value (6.25MHz*16)
ifrqa_104MHz            =       297053152               ' required FRQA value (6.5MHz*16)
ifrqa_108MHz            =       286051184               ' required FRQA value (13.5MHz*8)

'--------------------------------------------------------------------------------------------------
{
'' NTSC 64x25
omode                   =       $801                    ' NTSC, single line res
                                                        ' [1..0]    01 = NTSC(262@60),       10 = PAL (312@50)
                                                        ' [2]        0 = single line res,     1 = double line res
                                                        ' [3]        0 = lsb first font
                                                        ' [4..5]    00 = undefined                                             
                                                        ' [6]        0 = default pixel clock, 1 = use op_pixelclk
                                                        ' [7]        0 = default blank duty,  1 = use op_blankfrq
                                                        ' [11..8] 1000 = 8 pixels per character
ocols                   =       64                      ' number of columns
orows                   =       25                      ' number of rows
ocolsfrq                =       22_478                  ' Hz per active pixel
oequal1                 =       6                       ' number of equalization pulses
oserr                   =       6                       ' number of serration pulses
oequal2                 =       6                       ' number of equalization pulses
oblank1                 =       32                      ' number of blank lines
oactive                 =       200                     ' number of active lines
oblank2                 =       21                      ' number of blank lines
otsync                  =       39                      ' temp sync pulse 
ohalf                   =       4462                    ' VSCL half line
obackp                  =       4196                    ' VSCL back porch (sync to active)
ofrontp                 =       4163                    ' VSCL front porch (active to sync)
oequal                  =       4122                    ' VSCL equalization pulse (sync/2)
osync                   =       4149                    ' VSCL sync pulse
osynch                  =       4409                    ' VSCL half-sync
oequalh                 =       4436                    ' VSCL half-equal
ovsclch                 =       4104                    ' VSCL character
ictra                   =       12                      ' CTRA with PLLdiv
ifrqa                   =       308935280               ' required FRQA value (5MHz*16) (xfrqa replaced by start routine)
ifrqb                   =       $4924_0000              ' 40/140 << 32 = 1,227,096,064

ifrqa_80MHz             =       308935280               ' required FRQA value (5MHz*16)
ifrqa_96MHz             =       257446064               ' required FRQA value (6MHz*16)
ifrqa_100MHz            =       247148224               ' required FRQA value (6.25MHz*16)
ifrqa_104MHz            =       237642512               ' required FRQA value (6.5MHz*16)
ifrqa_108MHz            =       228840944               ' required FRQA value (13.5MHz*8)
}
'--------------------------------------------------------------------------------------------------
{
'' NTSC 80x25
omode                   =       $801                    ' NTSC, single line res
                                                        ' [1..0]    01 = NTSC(262@60),       10 = PAL (312@50)
                                                        ' [2]        0 = single line res,     1 = double line res
                                                        ' [3]        0 = lsb first font
                                                        ' [4..5]    00 = undefined                                             
                                                        ' [6]        0 = default pixel clock, 1 = use op_pixelclk
                                                        ' [7]        0 = default blank duty,  1 = use op_blankfrq
                                                        ' [11..8] 1000 = 8 pixels per character
ocols                   =       80                      ' number of columns
orows                   =       25                      ' number of rows
ocolsfrq                =       22_478                  ' Hz per active pixel
oequal1                 =       6                       ' number of equalization pulses
oserr                   =       6                       ' number of serration pulses
oequal2                 =       6                       ' number of equalization pulses
oblank1                 =       32                      ' number of blank lines
oactive                 =       200                     ' number of active lines
oblank2                 =       21                      ' number of blank lines
otsync                  =       39                      ' temp sync pulse 
ohalf                   =       4553                    ' VSCL half line
obackp                  =       4221                    ' VSCL back porch (sync to active)
ofrontp                 =       4179                    ' VSCL front porch (active to sync)
oequal                  =       4129                    ' VSCL equalization pulse (sync/2)
osync                   =       4162                    ' VSCL sync pulse
osynch                  =       4487                    ' VSCL half-sync
oequalh                 =       4520                    ' VSCL half-equal
ovsclch                 =       4104                    ' VSCL character
ictra                   =       12                      ' CTRA with PLLdiv
ifrqa                   =       386169088               ' required FRQA value (5MHz*16) (xfrqa replaced by start routine)
ifrqb                   =       $4924_0000              ' 40/140 << 32 = 1,227,096,064

ifrqa_80MHz             =       386169088               ' required FRQA value (5MHz*16)
ifrqa_96MHz             =       321807584               ' required FRQA value (6MHz*16)
ifrqa_100MHz            =       308935280               ' required FRQA value (6.25MHz*16)
ifrqa_104MHz            =       297053152               ' required FRQA value (6.5MHz*16)
ifrqa_108MHz            =       286051184               ' required FRQA value (13.5MHz*8)
}
'--------------------------------------------------------------------------------------------------
{
'' PAL  40x25
omode                   =       $802                    ' NTSC, single line res
                                                        ' [1..0]    01 = NTSC(262@60),       10 = PAL (312@50)
                                                        ' [2]        0 = single line res,     1 = double line res
                                                        ' [3]        0 = lsb first font
                                                        ' [4..5]    00 = undefined                                             
                                                        ' [6]        0 = default pixel clock, 1 = use op_pixelclk
                                                        ' [7]        0 = default blank duty,  1 = use op_blankfrq
                                                        ' [11..8] 1000 = 8 pixels per character
ocols                   =       40                      ' number of columns
orows                   =       25                      ' number of rows
ocolsfrq                =       22_321                  ' Hz per active pixel
oequal1                 =       4                       ' number of equalization pulses
oserr                   =       5                       ' number of serration pulses
oequal2                 =       5                       ' number of equalization pulses
oblank1                 =       59                      ' number of blank lines
oactive                 =       200                     ' number of active lines
oblank2                 =       45                      ' number of blank lines
otsync                  =       39                      ' temp sync pulse 
ohalf                   =       4324                    ' VSCL half line
obackp                  =       4163                    ' VSCL back porch (sync to active)
ofrontp                 =       4132                    ' VSCL front porch (active to sync)
oequal                  =       4112                    ' VSCL equalization pulse (sync/2)
osync                   =       4129                    ' VSCL sync pulse
osynch                  =       4291                    ' VSCL half-sync
oequalh                 =       4308                    ' VSCL half-equal
ovsclch                 =       4104                    ' VSCL character
ictra                   =       11                      ' CTRA with PLLdiv
ifrqa                   =       383471856               ' required FRQA value (5MHz*16) (xfrqa replaced by start routine)
ifrqb                   =       $4924_0000              ' 40/140 << 32 = 1,227,096,064

ifrqa_80MHz             =       383471856               ' required FRQA value (5MHz*16)
ifrqa_96MHz             =       319559872               ' required FRQA value (6MHz*16)
ifrqa_100MHz            =       306777488               ' required FRQA value (6.25MHz*16)
ifrqa_104MHz            =       294978352               ' required FRQA value (6.5MHz*16)
ifrqa_108MHz            =       284053232               ' required FRQA value (13.5MHz*8)
}
'--------------------------------------------------------------------------------------------------

'ASCII screen codes
_cls    =       0               'clear screen
_bel    =       7               'bell                   (not implemented)
_bs     =       8               'backspace
_ht     =       9               'horiz tab              (not implemented)
_lf     =       10              'line feed
_vt     =       11              'vert tab = home
_ff     =       12              'formfeed               (not implemented)
_cr     =       13              'carriage return
_can    =       24              'cancel = clear screen
_esc    =       27              'escape                 (not implemented)
_fs     =       28              'right                  
_gs     =       29              'left                   
_rs     =       30              'up                     
_us     =       31              'down                   
_spc    =       32              'space

flash   =       1<<2            'cursor flash rate  (change to 1<<4 etc to slow down)

  TEXTCOLS = ocols  '40 
  TEXTROWS = orows  '25                      


VAR
  long  cog
  long  pRENDEZVOUS                                     'buffer to pass characters to 1pinTV driver
'  byte  screen[TEXTROWS*TEXTCOLS]                       'Ensure this matches the OnePinTVText fixed parameters
' the screen is now located in hub over the cog code once it is loaded !!!


PUB start(tvPin)                                        'pass tv pin#

  stop
  Setforxtalfreq                                        'set ifrqa in hub for the current clkfreq before cognew 
  pRENDEZVOUS := @screen << 8 | tvPin
  result := cog := COGNEW( @entry,@pRendezvous) + 1
  repeat until pRENDEZVOUS == 0                         'wait until cleared


PUB stop
   COGSTOP( cog~ - 1 )

PRI Setforxtalfreq
'' These values are set for the default 40x25 NTSC/PAL 8x8 font, single line res
  Case clkfreq
    80_000_000 : xfrqa := ifrqa_80MHz                   ' 5.00 MHz
    96_000_000 : xfrqa := ifrqa_96MHz                   ' 6.00 MHz
    100_000_000: xfrqa := ifrqa_100MHz                  ' 6.25 MHz
    104_000_000: xfrqa := ifrqa_104MHz                  ' 6.50 MHz
    108_000_000: xfrqa := ifrqa_108MHz                  '13.50 MHz

PUB out(c)                                              'compatability
    chr(c)

PUB tx(c)                                               'compatability
    chr(c)
    
PUB chr(c)                                              'can be changed to OUT or TX
'' Print a character

  c |= $100   '0.FF -> 100..1FF                         'add bit9=1 (allows $00 to be passed)
  repeat while pRENDEZVOUS                              'wait for mailbox to be empty (=$0)
  pRENDEZVOUS := c                                      'place in mailbox for driver to act on

PUB str(stringptr)
'' Print a zero-terminated string

  repeat strsize(stringptr)
    chr(byte[stringptr++])

PUB dec(value) | _i
'' Print a decimal number

  if value < 0
    -value
    chr("-")

  _i := 1_000_000_000

  repeat 10
    if value => _i
      chr(value / _i + "0")
      value //= _i
      result~~
    elseif result or _i == 1
      chr("0")
    _i /= 10

PUB hex(value, digits)
'' Print a hexadecimal number

  value <<= (8 - digits) << 2
  repeat digits
    chr(lookupz((value <-= 4) & $F : "0".."9", "A".."F"))

PUB bin(value, digits)
'' Print a binary number

  value <<= 32 - digits
  repeat digits
    chr((value <-= 1) & 1 + "0")

PUB clear
'' Clear screen
  chr(_cls)

PUB home
'' Cursor home
  chr(_vt)

PUB gotoxy(x, y)
'' Position cursor x=col, y=row  (0,0 =home)
'  Currently a slow way until I get space/time to add to cog
  chr(_vt)                      'home
  repeat x
    chr(_fs)                    'cursor right x times
  repeat y
    chr(_us)                    'cursor down x times

PUB cr
'' Carriage return
  chr(_cr)
  
DAT
{{
This driver was inspired by the Parallax Forum topic "Minimal TV or VGA pins"
http://forums.parallax.com/forums/default.aspx?f=25&m=340731&g=342216
Where Phil Pilgrim provided the following circuit and description of use:
─┳┳
    
    
"White is logic high; sync, logic low; blank level, CTRB programmed for DUTY
 mode with FRQB set to $4924_0000. The advantage of this over tri-stating for
 the blanking level is that the Propeller's video generator can be used to
 generate the visible stuff while CTRB is active. When the video output is high,
 it's ORed with the DUTY output to yield a high; when low, the DUTY-mode value
 takes over. CTRB is simply turned off during the syncs, which has to be handled
 in software.

 The resistor values (124Ω series, 191Ω to ground) have an output impedance of
 75 ohms and will drive a 75-ohm load at 1V P-P. The cap is there to filter the
 DUTY doody."

However, in my experience, the RC network is not required. I have tested
successfully using any of the Demoboard TV DAC resistors (although the higher
resistance yields darker text) and with no resistors at all (although this
is not recommended).

Driver limitation details:
CLKFREQ => 12MHz
op_cols =< CLKFRQ / 1.2MHz (LSB) | CLKFREQ / 1.3MHz (MSB)
op_cols * pixels/char => 45
op_pixelclk => 1MHz

Q: Why specify op_pixelclk?
A1: To reduce shimmer caused by the number of significant bits in FRQA.
A2: To allow for WAITVID timing experimentation.
A3: To reduce horizontal overscan & display more characters per line.

Q: Why specify op_blankfrq?
A1: To tune the brightness of the text for a particular display.
A2: To allow for light/dark pulsing text. (Red Alert!!)

Q: Why specify pixels/char <> 8?
A1: To allow for fonts thinner than 8 pixels to be displayed.
A2: To allow for blank pixels between characters (i.e. hexfont.spin)

Q: Why not fonts with vertical sizes <> 8?
A: It probably can be done, but would require a chunk of time-sensitive
   code to be re-written.

Q: Why fewer characters per line for MSB first fonts?  (no longer supported)
A: MSB first fonts require one more instruction in a timing sensitive loop.    

Q: Why is pixels/char embedded in op_mode rather than a separate long?
A1: It's an optional parameter.  op_mode := 1 | 2 will be the norm.
A2: It started as a 1 bit parameter for 9 pixel wide characters, but then
    grew into a nibble.

Technote on video drivers...
Video drivers are constrained by WAITVID to WAITVID timing.  In the inner
active display loop (e.g. :active / :evitca), this determines the maximum
resolution at a given clock frequency.  Other WAITVID to WAITVID intervals
(e.g. front porch) determine the minimum clock frequency.

    
}}

                        ORG     0
'The font is located at the beginning of the cog ram to speed up the code
' *******************************************************************************************************
' *     AiChip_SmallFont_Atari_lsb_001.spin                                                             *
' *     LSB first version of Font_ATARI from AiGeneric Text Driver                                      *
' *******************************************************************************************************
' 128 chars 8x8 font
' RR20100304  v1.02 font now stored as two seperate blocks of 128 longs of 4x8 (4 rows of 8 pixels)
entry                                                   '\
screen                                                  '|  screen will use this hub space once cog is loaded
fonttab                                                 '|  font starts here also...
                        JMP     #init                   '/  go & replace this instr with the first font long

'fonttab       byte      %00000000               ' ........    $00              \ replaces the above jmp
'              byte      %00000000               ' ........                     |
'              byte      %00000000               ' ........                     |
'              byte      %00011000               ' ...##...                     /
                                                 
              byte      %00001111               ' ####....    $01
              byte      %00001111               ' ####....
              byte      %00001111               ' ####....
              byte      %00001111               ' ####....
                                                 
              byte      %00000000               ' ........    $02  USED FOR CURSOR
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %11111111               ' ########    $03
              byte      %11111111               ' ########
              byte      %11111111               ' ########
              byte      %11111111               ' ########
                                                 
              byte      %00000000               ' ........    $04
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %00001111               ' ####....    $05
              byte      %00001111               ' ####....
              byte      %00001111               ' ####....
              byte      %00001111               ' ####....
                                                 
              byte      %11110000               ' ....####    $06
              byte      %11110000               ' ....####
              byte      %11110000               ' ....####
              byte      %11110000               ' ....####
                                                 
              byte      %11111111               ' ########    $07
              byte      %11111111               ' ########
              byte      %11111111               ' ########
              byte      %11111111               ' ########
                                                 
              byte      %00000000               ' ........    $08
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %00001111               ' ####....    $09
              byte      %00001111               ' ####....
              byte      %00001111               ' ####....
              byte      %00001111               ' ####....
                                                 
              byte      %11110000               ' ....####    $0A
              byte      %11110000               ' ....####
              byte      %11110000               ' ....####
              byte      %11110000               ' ....####
                                                 
              byte      %11111111               ' ########    $0B
              byte      %11111111               ' ########
              byte      %11111111               ' ########
              byte      %11111111               ' ########
                                                 
              byte      %00000000               ' ........    $0C
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %00001111               ' ####....    $0D
              byte      %00001111               ' ####....
              byte      %00001111               ' ####....
              byte      %00001111               ' ####....
                                                 
              byte      %11110000               ' ....####    $0E
              byte      %11110000               ' ....####
              byte      %11110000               ' ....####
              byte      %11110000               ' ....####
                                                 
              byte      %11111111               ' ########    $0F
              byte      %11111111               ' ########
              byte      %11111111               ' ########
              byte      %11111111               ' ########
                                                 
              byte      %00000000               ' ........    $10
              byte      %10000000               ' .......#
              byte      %10000000               ' .......#
              byte      %10000000               ' .......#
                                                 
              byte      %00000000               ' ........    $11
              byte      %11111111               ' ########
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %00000000               ' ........    $12
              byte      %11111111               ' ########
              byte      %10000000               ' .......#
              byte      %10000000               ' .......#
                                                 
              byte      %00000000               ' ........    $13
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %00000000               ' ........    $14
              byte      %11111111               ' ########
              byte      %11111111               ' ########
              byte      %11111111               ' ########
                                                 
              byte      %00000000               ' ........    $15
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %11111000               ' ...#####
                                                 
              byte      %00000000               ' ........    $16
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %11111111               ' ########
                                                 
              byte      %00000000               ' ........    $17
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00011111               ' #####...
                                                 
              byte      %00011000               ' ...##...    $18
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
              byte      %11111000               ' ...#####
                                                 
              byte      %00110000               ' ....##..    $19
              byte      %00110000               ' ....##..
              byte      %00110000               ' ....##..
              byte      %00111111               ' ######..
                                                 
              byte      %00100000               ' .....#..    $1A
              byte      %00110000               ' ....##..
              byte      %00111000               ' ...###..
              byte      %00111100               ' ..####..
                                                 
              byte      %00000100               ' ..#.....    $1B
              byte      %00001100               ' ..##....
              byte      %00011100               ' ..###...
              byte      %00111100               ' ..####..
                                                 
              byte      %00000000               ' ........    $1C
              byte      %00011000               ' ...##...
              byte      %00111100               ' ..####..
              byte      %01111110               ' .######.
                                                 
              byte      %00000000               ' ........    $1D
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $1E
              byte      %00001000               ' ...#....
              byte      %00001100               ' ..##....
              byte      %01111110               ' .######.
                                                 
              byte      %00000000               ' ........    $1F
              byte      %00010000               ' ....#...
              byte      %00110000               ' ....##..
              byte      %01111110               ' .######.
                                                 
              byte      %00000000               ' ........    $20  Space
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %00000000               ' ........    $21  !
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $22  "
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $23  #
              byte      %01100110               ' .##..##.
              byte      %11111111               ' ########
              byte      %01100110               ' .##..##.
                                                 
              byte      %00011000               ' ...##...    $24  $
              byte      %01111100               ' ..#####.
              byte      %00000110               ' .##.....
              byte      %00111100               ' ..####..
                                                 
              byte      %00000000               ' ........    $25  %
              byte      %01100110               ' .##..##.
              byte      %00110110               ' .##.##..
              byte      %00011000               ' ...##...
                                                 
              byte      %00111000               ' ...###..    $26  &
              byte      %01101100               ' ..##.##.
              byte      %00111000               ' ...###..
              byte      %00011100               ' ..###...
                                                 
              byte      %00000000               ' ........    $27  '
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $28  (
              byte      %01110000               ' ....###.
              byte      %00111000               ' ...###..
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $29  )
              byte      %00001110               ' .###....
              byte      %00011100               ' ..###...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $2A  *
              byte      %01100110               ' .##..##.
              byte      %00111100               ' ..####..
              byte      %11111111               ' ########
                                                 
              byte      %00000000               ' ........    $2B  +
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
              byte      %01111110               ' .######.
                                                 
              byte      %00000000               ' ........    $2C  ,
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %00000000               ' ........    $2D  -
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %01111110               ' .######.
                                                 
              byte      %00000000               ' ........    $2E  .
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %00000000               ' ........    $2F  /
              byte      %01100000               ' .....##.
              byte      %00110000               ' ....##..
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $30  0
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
              byte      %01110110               ' .##.###.
                                                 
              byte      %00000000               ' ........    $31  1
              byte      %00011000               ' ...##...
              byte      %00011100               ' ..###...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $32  2
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
              byte      %00110000               ' ....##..
                                                 
              byte      %00000000               ' ........    $33  3
              byte      %01111110               ' .######.
              byte      %00110000               ' ....##..
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $34  4
              byte      %00110000               ' ....##..
              byte      %00111000               ' ...###..
              byte      %00111100               ' ..####..
                                                 
              byte      %00000000               ' ........    $35  5
              byte      %01111110               ' .######.
              byte      %00000110               ' .##.....
              byte      %00111110               ' .#####..
                                                 
              byte      %00000000               ' ........    $36  6
              byte      %00111100               ' ..####..
              byte      %00000110               ' .##.....
              byte      %00111110               ' .#####..
                                                 
              byte      %00000000               ' ........    $37  7
              byte      %01111110               ' .######.
              byte      %01100000               ' .....##.
              byte      %00110000               ' ....##..
                                                 
              byte      %00000000               ' ........    $38  8
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
              byte      %00111100               ' ..####..
                                                 
              byte      %00000000               ' ........    $39  9
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
              byte      %01111100               ' ..#####.
                                                 
              byte      %00000000               ' ........    $3A  :
              byte      %00000000               ' ........
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $3B  ;
              byte      %00000000               ' ........
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
                                                 
              byte      %01100000               ' .....##.    $3C  <
              byte      %00110000               ' ....##..
              byte      %00011000               ' ...##...
              byte      %00001100               ' ..##....
                                                 
              byte      %00000000               ' ........    $3D  =
              byte      %00000000               ' ........
              byte      %01111110               ' .######.
              byte      %00000000               ' ........
                                                 
              byte      %00000110               ' .##.....    $3E  >
              byte      %00001100               ' ..##....
              byte      %00011000               ' ...##...
              byte      %00110000               ' ....##..
                                                 
              byte      %00000000               ' ........    $3F  ?
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
              byte      %00110000               ' ....##..
                                                 
              byte      %00000000               ' ........    $40  @
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
              byte      %01110110               ' .##.###.
                                                 
              byte      %00000000               ' ........    $41  A
              byte      %00011000               ' ...##...
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $42  B
              byte      %00111110               ' .#####..
              byte      %01100110               ' .##..##.
              byte      %00111110               ' .#####..
                                                 
              byte      %00000000               ' ........    $43  C
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
              byte      %00000110               ' .##.....
                                                 
              byte      %00000000               ' ........    $44  D
              byte      %00011110               ' .####...
              byte      %00110110               ' .##.##..
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $45  E
              byte      %01111110               ' .######.
              byte      %00000110               ' .##.....
              byte      %00111110               ' .#####..
                                                 
              byte      %00000000               ' ........    $46  F
              byte      %01111110               ' .######.
              byte      %00000110               ' .##.....
              byte      %00111110               ' .#####..
                                                 
              byte      %00000000               ' ........    $47  G
              byte      %01111100               ' ..#####.
              byte      %00000110               ' .##.....
              byte      %00000110               ' .##.....
                                                 
              byte      %00000000               ' ........    $48  H
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
              byte      %01111110               ' .######.
                                                 
              byte      %00000000               ' ........    $49  I
              byte      %01111110               ' .######.
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $4A  J
              byte      %01100000               ' .....##.
              byte      %01100000               ' .....##.
              byte      %01100000               ' .....##.
                                                 
              byte      %00000000               ' ........    $4B  K
              byte      %01100110               ' .##..##.
              byte      %00110110               ' .##.##..
              byte      %00011110               ' .####...
                                                 
              byte      %00000000               ' ........    $4C  L
              byte      %00000110               ' .##.....
              byte      %00000110               ' .##.....
              byte      %00000110               ' .##.....
                                                 
              byte      %00000000               ' ........    $4D  M
              byte      %11000110               ' .##...##
              byte      %11101110               ' .###.###
              byte      %11111110               ' .#######
                                                 
              byte      %00000000               ' ........    $4E  N
              byte      %01100110               ' .##..##.
              byte      %01101110               ' .###.##.
              byte      %01111110               ' .######.
                                                 
              byte      %00000000               ' ........    $4F  O
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $50  P
              byte      %00111110               ' .#####..
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $51  Q
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $52  R
              byte      %00111110               ' .#####..
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $53  S
              byte      %00111100               ' ..####..
              byte      %00000110               ' .##.....
              byte      %00111100               ' ..####..
                                                 
              byte      %00000000               ' ........    $54  T
              byte      %01111110               ' .######.
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $55  U
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $56  V
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $57  W
              byte      %11000110               ' .##...##
              byte      %11000110               ' .##...##
              byte      %11010110               ' .##.#.##
                                                 
              byte      %00000000               ' ........    $58  X
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
              byte      %00111100               ' ..####..
                                                 
              byte      %00000000               ' ........    $59  Y
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
              byte      %00111100               ' ..####..
                                                 
              byte      %00000000               ' ........    $5A  Z
              byte      %01111110               ' .######.
              byte      %00110000               ' ....##..
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $5B  [
              byte      %01111000               ' ...####.
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $5C  \
              byte      %00000010               ' .#......
              byte      %00000110               ' .##.....
              byte      %00001100               ' ..##....
                                                 
              byte      %00000000               ' ........    $5D  ]
              byte      %00011110               ' .####...
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $5E  ^
              byte      %00010000               ' ....#...
              byte      %00111000               ' ...###..
              byte      %01101100               ' ..##.##.
                                                 
              byte      %00000000               ' ........    $5F  _
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %00000000               ' ........    $60  `
              byte      %10000000               ' .......#
              byte      %11000000               ' ......##
              byte      %01100000               ' .....##.
                                                 
              byte      %00000000               ' ........    $61  a
              byte      %00000000               ' ........
              byte      %00111100               ' ..####..
              byte      %01100000               ' .....##.
                                                 
              byte      %00000000               ' ........    $62  b
              byte      %00000110               ' .##.....
              byte      %00000110               ' .##.....
              byte      %00111110               ' .#####..
                                                 
              byte      %00000000               ' ........    $63  c
              byte      %00000000               ' ........
              byte      %00111100               ' ..####..
              byte      %00000110               ' .##.....
                                                 
              byte      %00000000               ' ........    $64  d
              byte      %01100000               ' .....##.
              byte      %01100000               ' .....##.
              byte      %01111100               ' ..#####.
                                                 
              byte      %00000000               ' ........    $65  e
              byte      %00000000               ' ........
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $66  f
              byte      %01110000               ' ....###.
              byte      %00011000               ' ...##...
              byte      %01111100               ' ..#####.
                                                 
              byte      %00000000               ' ........    $67  g
              byte      %00000000               ' ........
              byte      %01111100               ' ..#####.
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $68  h
              byte      %00000110               ' .##.....
              byte      %00000110               ' .##.....
              byte      %00111110               ' .#####..
                                                 
              byte      %00000000               ' ........    $69  i
              byte      %00011000               ' ...##...
              byte      %00000000               ' ........
              byte      %00011100               ' ..###...
                                                 
              byte      %00000000               ' ........    $6A  j
              byte      %00110000               ' ....##..
              byte      %00000000               ' ........
              byte      %00110000               ' ....##..
                                                 
              byte      %00000000               ' ........    $6B  k
              byte      %00000110               ' .##.....
              byte      %00000110               ' .##.....
              byte      %00110110               ' .##.##..
                                                 
              byte      %00000000               ' ........    $6C  l
              byte      %00011100               ' ..###...
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $6D  m
              byte      %00000000               ' ........
              byte      %01100110               ' .##..##.
              byte      %11111110               ' .#######
                                                 
              byte      %00000000               ' ........    $6E  n
              byte      %00000000               ' ........
              byte      %00111110               ' .#####..
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $6F  o
              byte      %00000000               ' ........
              byte      %00111100               ' ..####..
              byte      %01100110               ' .##..##.
                                                  
              byte      %00000000               ' ........    $70  p
              byte      %00000000               ' ........
              byte      %00111110               ' .#####..
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $71  q
              byte      %00000000               ' ........
              byte      %01111100               ' ..#####.
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $72  r
              byte      %00000000               ' ........
              byte      %00111110               ' .#####..
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $73  s
              byte      %00000000               ' ........
              byte      %01111100               ' ..#####.
              byte      %00000110               ' .##.....
                                                 
              byte      %00000000               ' ........    $74  t
              byte      %00011000               ' ...##...
              byte      %01111110               ' .######.
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $75  u
              byte      %00000000               ' ........
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
                                                
              byte      %00000000               ' ........    $76  v
              byte      %00000000               ' ........
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $77  w
              byte      %00000000               ' ........
              byte      %11000110               ' .##...##
              byte      %11010110               ' .##.#.##
                                                 
              byte      %00000000               ' ........    $78  x
              byte      %00000000               ' ........
              byte      %01100110               ' .##..##.
              byte      %00111100               ' ..####..
                                                 
              byte      %00000000               ' ........    $79  y
              byte      %00000000               ' ........
              byte      %01100110               ' .##..##.
              byte      %01100110               ' .##..##.
                                                 
              byte      %00000000               ' ........    $7A  z
              byte      %00000000               ' ........
              byte      %01111110               ' .######.
              byte      %00110000               ' ....##..
                                                 
              byte      %00000000               ' ........    $7B  {
              byte      %00111000               ' ...###..
              byte      %00011000               ' ...##...
              byte      %00011110               ' .###....
                                                 
              byte      %00011000               ' ...##...    $7C  |
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
              byte      %00011000               ' ...##...
                                                 
              byte      %00000000               ' ........    $7D  }
              byte      %00011100               ' ..###...
              byte      %00011000               ' ...##...
              byte      %01111000               ' ....###.
                                                 
              byte      %00000000               ' ........    $7E  ~
              byte      %11001100               ' ..##..##
              byte      %01111110               ' .######.
              byte      %00110011               ' ##..##..
                                                 
              byte      %00000000               ' ........    $7F
              byte      %00011100               ' ..###...
              byte      %00100010               ' .#...#..
              byte      %00100010               ' .#...#..

' *******************************************************************************************************
' second half of font longs...

              byte      %00011000               ' ...##...    $00
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %00000000               ' ........    $01
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........
                                                 
              byte      %00000000               ' ........    $02  USED FOR CURSOR
              byte      %00000000               ' ........
              byte      %11111110               ' .#######
              byte      %11111110               ' .####### 
                                                 
              byte      %00000000               ' ........    $03                          
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00001111               ' ####....    $04                          
              byte      %00001111               ' ####....                                 
              byte      %00001111               ' ####....                                 
              byte      %00001111               '.####....                                 
                                                                                           
              byte      %00001111               ' ####....    $05                          
              byte      %00001111               ' ####....                                 
              byte      %00001111               ' ####....                                 
              byte      %00001111               ' ####....                                 
                                                                                           
              byte      %00001111               ' ####....    $06                          
              byte      %00001111               ' ####....                                 
              byte      %00001111               ' ####....                                 
              byte      %00001111               ' ####....                                 
                                                                                           
              byte      %00001111               ' ####....    $07                          
              byte      %00001111               ' ####....                                 
              byte      %00001111               ' ####....                                 
              byte      %00001111               ' ####....                                 
                                                                                           
              byte      %11110000               ' ....####    $08                          
              byte      %11110000               ' ....####                                 
              byte      %11110000               ' ....####                                 
              byte      %11110000               ' ....####                                 
                                                                                           
              byte      %11110000               ' ....####    $09                          
              byte      %11110000               ' ....####                                 
              byte      %11110000               ' ....####                                 
              byte      %11110000               ' ....####                                 
                                                                                           
              byte      %11110000               ' ....####    $0A                          
              byte      %11110000               ' ....####                                 
              byte      %11110000               ' ....####                                 
              byte      %11110000               ' ....####                                 
                                                                                           
              byte      %11110000               ' ....####    $0B                          
              byte      %11110000               ' ....####                                 
              byte      %11110000               ' ....####                                 
              byte      %11110000               ' ....####                                 
                                                                                           
              byte      %11111111               ' ########    $0C                          
              byte      %11111111               ' ########                                 
              byte      %11111111               ' ########                                 
              byte      %11111111               '.########                                 
                                                                                           
              byte      %11111111               ' ########    $0D                          
              byte      %11111111               ' ########                                 
              byte      %11111111               ' ########                                 
              byte      %11111111               ' ########                                 
                                                                                           
              byte      %11111111               ' ########    $0E                          
              byte      %11111111               ' ########                                 
              byte      %11111111               ' ########                                 
              byte      %11111111               ' ########                                 
                                                                                           
              byte      %11111111               ' ########    $0F                          
              byte      %11111111               ' ########                                 
              byte      %11111111               ' ########                                 
              byte      %11111111               ' ########                                 
                                                                                           
              byte      %10000000               ' .......#    $10                          
              byte      %10000000               ' .......#                                 
              byte      %11111111               ' ########                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $11                          
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %10000000               ' .......#    $12                          
              byte      %10000000               ' .......#                                 
              byte      %10000000               ' .......#                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $13                          
              byte      %00000000               ' ........                                 
              byte      %11111111               ' ########                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %11111111               ' ########    $14                          
              byte      %11111111               ' ########                                 
              byte      %11111111               ' ########                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %11111000               ' ...#####    $15                          
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
                                                                                           
              byte      %11111111               ' ########    $16                          
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011111               ' #####...    $17                          
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
                                                                                           
              byte      %11111000               ' ...#####    $18                          
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00111111               ' ######..    $19                          
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00111000               ' ...###..    $1A                          
              byte      %00110000               ' ....##..                                 
              byte      %00100000               ' .....#..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011100               ' ..###...    $1B                          
              byte      %00001100               ' ..##....                                 
              byte      %00000100               ' ..#.....                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $1C                          
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01111110               ' .######.    $1D                          
              byte      %00111100               ' ..####..                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01111110               ' .######.    $1E                          
              byte      %00001100               ' ..##....                                 
              byte      %00001000               ' ...#....                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01111110               ' .######.    $1F                          
              byte      %00110000               ' ....##..                                 
              byte      %00010000               ' ....#...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $20  Space                   
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $21  !                       
              byte      %00000000               ' ........                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $22  "                       
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $23  #                       
              byte      %11111111               ' ########                                 
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100000               ' .....##.    $24  $                       
              byte      %00111110               ' .#####..                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00001100               ' ..##....    $25  %                       
              byte      %01100110               ' .##..##.                                 
              byte      %01100010               ' .#...##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %11110110               ' .##.####    $26  &                       
              byte      %01100110               ' .##..##.                                 
              byte      %11011100               ' ..###.##                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $27  '                  
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $28  (                       
              byte      %00111000               ' ...###..                                 
              byte      %01110000               ' ....###.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $29  )                       
              byte      %00011100               ' ..###...                                 
              byte      %00001110               ' .###....                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00111100               ' ..####..    $2A  *                       
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $2B  +                       
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $2C  ,                       
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
              byte      %00001100               ' ..##....                                 
                                                                                           
              byte      %00000000               ' ........    $2D  -                       
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $2E  .                       
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00001100               ' ..##....    $2F  /                       
              byte      %00000110               ' .##.....                                 
              byte      %00000010               ' .#......                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01101110               ' .###.##.    $30  0                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $31  1                       
              byte      %00011000               ' ...##...                                 
              byte      %01111110               ' .######.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $32  2                       
              byte      %00001100               ' ..##....                                 
              byte      %01111110               ' .######.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00110000               ' ....##..    $33  3                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00110110               ' .##.##..    $34  4                       
              byte      %01111110               ' .######.                                 
              byte      %00110000               ' ....##..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100000               ' .....##.    $35  5                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $36  6                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $37  7                       
              byte      %00001100               ' ..##....                                 
              byte      %00001100               ' ..##....                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $38  8                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100000               ' .....##.    $39  9                       
              byte      %00110000               ' ....##..                                 
              byte      %00011100               ' ..###...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $3A  :                       
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $3B  ;                       
              byte      %00011000               ' ...##...                                 
              byte      %00001100               ' ..##....                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $3C  <                       
              byte      %00110000               ' ....##..                                 
              byte      %01100000               ' .....##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $3D  =                       
              byte      %01111110               ' .######.                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $3E  >                       
              byte      %00001100               ' ..##....                                 
              byte      %00000110               ' .##.....                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $3F  ?                       
              byte      %00000000               ' ........                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01110110               ' .##.###.    $40  @                       
              byte      %00000110               ' .##.....                                 
              byte      %01111100               ' ..#####.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $41  A                       
              byte      %01111110               ' .######.                                 
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $42  B                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111110               ' .#####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000110               ' .##.....    $43  C                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $44  D                       
              byte      %00110110               ' .##.##..                                 
              byte      %00011110               ' .####...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000110               ' .##.....    $45  E                       
              byte      %00000110               ' .##.....                                 
              byte      %01111110               ' .######.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000110               ' .##.....    $46  F                       
              byte      %00000110               ' .##.....                                 
              byte      %00000110               ' .##.....                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01110110               ' .##.###.    $47  G                       
              byte      %01100110               ' .##..##.                                 
              byte      %01111100               ' ..#####.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $48  H                       
              byte      %01100110               ' .##..##.                                 
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $49  I                       
              byte      %00011000               ' ...##...                                 
              byte      %01111110               ' .######.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100000               ' .....##.    $4A  J                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011110               ' .####...    $4B  K                       
              byte      %00110110               ' .##.##..                                 
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000110               ' .##.....    $4C  L                       
              byte      %00000110               ' .##.....                                 
              byte      %01111110               ' .######.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %11010110               ' .##.#.##    $4D  M                       
              byte      %11000110               ' .##...##                                 
              byte      %11000110               ' .##...##                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01111110               ' .######.    $4E  N                       
              byte      %01110110               ' .##.###.                                 
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $4F  O                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00111110               ' .#####..    $50  P                       
              byte      %00000110               ' .##.....                                 
              byte      %00000110               ' .##.....                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $51  Q                       
              byte      %00110110               ' .##.##..                                 
              byte      %01101100               ' ..##.##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00111110               ' .#####..    $52  R                       
              byte      %00110110               ' .##.##..                                 
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100000               ' .....##.    $53  S                       
              byte      %01100000               ' .....##.                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $54  T                       
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $55  U                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $56  V                       
              byte      %00111100               ' ..####..                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %11111110               ' .#######    $57  W                       
              byte      %11101110               ' .###.###                                 
              byte      %11000110               ' .##...##                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00111100               ' ..####..    $58  X                       
              byte      %01100110               ' .##..##.                                 
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $59  Y                       
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00001100               ' ..##....    $5A  Z                       
              byte      %00000110               ' .##.....                                 
              byte      %01111110               ' .######.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $5B  [                       
              byte      %00011000               ' ...##...                                 
              byte      %01111000               ' ...####.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $5C  \                       
              byte      %00110000               ' ....##..                                 
              byte      %01100000               ' .....##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $5D  ]                       
              byte      %00011000               ' ...##...                                 
              byte      %00011110               ' .####...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %11000110               ' .##...##    $5E  ^                       
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $5F  _                       
              byte      %00000000               ' ........                                 
              byte      %01111110               ' .######.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00110011               ' ##..##..    $60  `                       
              byte      %00011110               ' .####...                                 
              byte      %00001100               ' ..##....                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01111100               ' ..#####.    $61  a                       
              byte      %01100110               ' .##..##.                                 
              byte      %01111100               ' ..#####.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $62  b                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111110               ' .#####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000110               ' .##.....    $63  c                       
              byte      %00000110               ' .##.....                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $64  d                       
              byte      %01100110               ' .##..##.                                 
              byte      %01111100               ' ..#####.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01111110               ' .######.    $65  e                       
              byte      %00000110               ' .##.....                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $66  f                       
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $67  g                       
              byte      %01111100               ' ..#####.                                 
              byte      %01100000               ' .....##.                                 
              byte      %00111110               ' .#####..                                 
                                                                                           
              byte      %01100110               ' .##..##.    $68  h                       
              byte      %01100110               ' .##..##.                                 
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $69  i                       
              byte      %00011000               ' ...##...                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00110000               ' ....##..    $6A  j                       
              byte      %00110000               ' ....##..                                 
              byte      %00110000               ' ....##..                                 
              byte      %00011110               ' .####...                                 
                                                                                           
              byte      %00011110               ' .####...    $6B  k                       
              byte      %00110110               ' .##.##..                                 
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $6C  l                       
              byte      %00011000               ' ...##...                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %11111110               ' .#######    $6D  m                       
              byte      %11010110               ' .##.#.##                                 
              byte      %11000110               ' .##...##                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $6E  n                       
              byte      %01100110               ' .##..##.                                 
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $6F  o                       
              byte      %01100110               ' .##..##.                                 
              byte      %00111100               ' ..####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $70  p                       
              byte      %00111110               ' .#####..                                 
              byte      %00000110               ' .##.....                                 
              byte      %00000110               ' .##.....                                 
                                                                                           
              byte      %01100110               ' .##..##.    $71  q                       
              byte      %01111100               ' ..#####.                                 
              byte      %01100000               ' .....##.                                 
              byte      %01100000               ' .....##.                                 
                                                                                           
              byte      %00000110               ' .##.....    $72  r                       
              byte      %00000110               ' .##.....                                 
              byte      %00000110               ' .##.....                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00111100               ' ..####..    $73  s                       
              byte      %01100000               ' .....##.                                 
              byte      %00111110               ' .#####..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $74  t                       
              byte      %00011000               ' ...##...                                 
              byte      %01110000               ' ....###.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $75  u                       
              byte      %01100110               ' .##..##.                                 
              byte      %01111100               ' ..#####.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $76  v                       
              byte      %00111100               ' ..####..                                 
              byte      %00011000               ' ...##...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %11111110               ' .#######    $77  w                       
              byte      %01111100               ' ..#####.                                 
              byte      %01101100               ' ..##.##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $78  x                       
              byte      %00111100               ' ..####..                                 
              byte      %01100110               ' .##..##.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %01100110               ' .##..##.    $79  y                       
              byte      %01111100               ' ..#####.                                 
              byte      %00110000               ' ....##..                                 
              byte      %00011110               ' .####...                                 
                                                                                           
              byte      %00011000               ' ...##...    $7A  z                       
              byte      %00001100               ' ..##....                                 
              byte      %01111110               ' .######.                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011110               ' .###....    $7B  {                       
              byte      %00011000               ' ...##...                                 
              byte      %00111000               ' ...###..                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011000               ' ...##...    $7C  |                       
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
              byte      %00011000               ' ...##...                                 
                                                                                           
              byte      %01111000               ' ....###.    $7D  }                       
              byte      %00011000               ' ...##...                                 
              byte      %00011100               ' ..###...                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00000000               ' ........    $7E  ~                       
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
              byte      %00000000               ' ........                                 
                                                                                           
              byte      %00011100               ' ..###...    $7F                          
              byte      %00000000               ' ........
              byte      %00000000               ' ........
              byte      %00000000               ' ........

' end of font
' *******************************************************************************************************
font_long0    byte      %00000000               ' ........    $00    \    this long copied to cogstart to
              byte      %00000000               ' ........           |      replace the jmp instruction
              byte      %00000000               ' ........           |
              byte      %00011000               ' ...##...           /
' *******************************************************************************************************


init                    mov     fonttab,font_long0      'replace the cogstart instruction with the font

                        rdlong  i_pin, par              'input parameters ( @screen << 8 | tvpin )
                        and     i_pin, #$FF             'extract TV pin#
                        rdlong  i_charptr, par   
                        shr     i_charptr, #8           'extract ptr to hub screen buffer

                        MOV     FRQB, xfrqb             'default = 40/140

                        MOVI    CTRA, #ictra
                        MOV     FRQA, xfrqa

                        MOVS    CTRB, i_pin             'set pin
                        MOV     count, #1
                        SHL     count, i_pin
                        MOV     DIRA, count             'set pin mask
                        MOV     count, i_pin                               '<=== can save this by next shr #4
                        SHR     count, #3
                        MOVD    VCFG, count             'set VGroup
                        MOV     count, #1
                        AND     i_pin, #7                                  '<=== poss to save?
                        SHL     count, i_pin
                        MOVS    VCFG, count             'set VPins
                        MOVI    VCFG, #%0_01_0_0_0_000  'VGA mode, 1 bit per pixel

                        mov     taskptr, #nextchar      'point to vt100 code

'**************************************************************************************************
frame                   add     framectr, #1            'inc frame counter
                        MOV     rownum, #oequal1
                        CALL    #equalizing             'equalisation pulses
'--------------------------------------------------------------------------------------------------
                        MOV     rownum, #oserr          'serration pulses
:loop                   MOV     VSCL, xsynch            'serration pulse (long)
                        WAITVID xFFOO, #0               
                        MOVI    CTRB, #0                'turn off blank
                        MOV     VSCL, xsync             'serration pulse (short)
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #%0_00110_000     'turn on blank
                        DJNZ    rownum, #:loop
'--------------------------------------------------------------------------------------------------
                        MOV     rownum, #oequal2
                        CALL    #equalizing             'equalisation pulses
'==================================================================================================
                        MOV     rownum, #oblank1
                        CALL    #doblank                'blank lines (top)
'==================================================================================================
'display active lines
                        MOV     rownum, #oactive
                        MOV     charptr, i_charptr      ' initialize character pointer
doactive                MOV     VSCL, xsync             ' 4.7uSec @ -40 IRE
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #0                ' turn off blank
                        TEST    rownum, #7      WZ      ' 8 lines per row (new char row?)
        IF_Z            MOV     fontptr, #0             ' reset fontptr if required (new char row)
        IF_NZ           SUB     charptr, #ocols         ' reset charptr if required (next pixel row)
        IF_NZ           ADD     fontptr, #1*8           ' advance to next pixel line (x8 to simplify maths)
                        test    fontptr,#4*8    wz      ' set nz flag for upper long (pixel rows 5..8)
                        MOV     count, #ocols           ' characters per line

                        MOV     VSCL, xbackp            ' back porch
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #%0_00110_000     ' turn on blank
                        MOV     VSCL, xvsclch           ' 1 PLLA per pixel, 8 PLLA per frame
'--------------------------------------------------------------------------------------------------
'hub screen & cog font: display entire pixel line
:active
                        RDBYTE  char, charptr           ' read character from HUB RAM
                        test    char, #$80      wc      ' inverse?
                        muxnz   char,#$80               ' if nz, upper font long (nz set at start)
                        movs    :getfont, char
                        ADD     charptr, #1             ' point to next character
:getfont                mov     char, 0-0               ' get font
                        shr     char, fontptr           ' shift pixels 0/8/16/24 (upper pixels ignored)
        if_c            xor     char, #$FF              ' inverse
                        WAITVID xFFOO, char             ' output to screen
                        DJNZ    count, #:active         ' do entire line
'--------------------------------------------------------------------------------------------------
                        MOV     VSCL, xfrontp           ' front porch
                        WAITVID xFFOO, #0               ' output blank
                        DJNZ    rownum, #doactive       ' next row
'==================================================================================================
                        mov     rownum, #oblank2
                        call    #doblank                'blank lines (bottom)
'==================================================================================================
                        JMP     #frame
'**************************************************************************************************

equalizing              MOV     VSCL, xequal            ' equalizing pulse (short)
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #0                ' turn off blank
                        MOV     VSCL, xequalh           ' equalizing pulse (long)
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #%0_00110_000     ' turn on blank
                        jmpret  taskret, taskptr        ' to vt100 code
                        DJNZ    rownum, #equalizing
equalizing_ret          RET
'--------------------------------------------------------------------------------------------------
doblank                 MOV     VSCL, xsync             ' 4.7uSec @ -40 IRE
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #0                ' turn off blank
                        MOV     VSCL, xsynch            ' blank line
                        WAITVID xFFOO, #0
                        MOVI    CTRB, #%0_00110_000     ' turn on blank
                        MOV     VSCL, xhalf             ' half line ???
                        WAITVID xFFOO, #0
                        DJNZ    rownum, #doblank
doblank_ret             RET
'**************************************************************************************************

'--------------------------------------------------------------------------------------------------
'' input parameters passed from spin - 2 contiguous longs       
i_pin                   long    0                       ' pin number
i_charptr               long    0                       ' pointer to screen (bytes)

'--------------------------------------------------------------------------------------------------
'constants > $1FF
'xmode                  long    omode
xhalf                   long    ohalf
xbackp                  long    obackp
xfrontp                 long    ofrontp
xequal                  long    oequal
xsync                   long    osync
xsynch                  long    osynch
xequalh                 long    oequalh
xvsclch                 long    ovsclch
xfrqa                   long    ifrqa
xfrqb                   long    ifrqb

d1                      LONG    1<<9                   ' destination = 1
d1s1                    LONG    1<<9+1                 ' destination = 1 source = 1
xFFOO                   LONG    $FF00                  ' white / black

char                    long    0                      ' current character / character bitmap
charptr                 long    0                      ' pointer to current character
fontptr                 long    0                      ' base address + line offset
count                   long    0                      ' all purpose counter
rownum                  long    0                      ' row counter

'**************************************************************************************************
' Tasks - performed in sections during invisible back porch lines

cls                     mov     screenptr, i_charptr    'set to start of screen        
                        mov     row, #orows             'clear .. lines
:lines                  mov     col, #ocols/4           'clear .. columns, 4 chars at a time
:chars                  wrlong  x20202020, screenptr    'clear 4 chars at a time
                        add     screenptr, #4           'inc hub ptr
                        djnz    col, #:chars
                        jmpret  taskptr, taskret        'return to video code
                        djnz    row, #:lines            'row=col=0
                        mov     posn, #0                'set cursor posn = home

nextchar                mov     ch, #0                  'clear input char
                        wrlong  ch, par
                        mov     cursorptr, i_charptr    'calc cursor hub ptr
                        add     cursorptr, posn
                        rdbyte  cursorchr, cursorptr    'get the cursor char
waitforchar             jmpret  taskptr,taskret         'return to video code
                        test    framectr,#flash wz      'flash rate
              if_z      wrbyte  x02, cursorptr          'cursor \flash cursor
              if_nz     wrbyte  cursorchr, cursorptr    'char   /                        
                        rdlong  ch, par                 'char avail?
                        tjz     ch, #waitforchar
                        wrbyte  cursorchr, cursorptr    'ensure cursor char replaced in screen buffer                        
                        and     ch, #$FF                'remove upper bits
                        cmp     ch, #_cls       wz
              if_z      jmp     #cls
                        cmp     ch, #_can       wz
              if_z      jmp     #cls
                        cmp     ch, #_vt        wz      'home
              if_z      jmp     #gohome
                        cmp     ch, #_bs        wz
              if_z      jmp     #bs
                        cmp     ch, #_cr        wz
              if_z      jmp     #cr_
                        cmp     ch, #_lf        wz
              if_z      jmp     #lf
                        cmp     ch, #_fs        wz      'right
              if_z      jmp     #leftright
                        cmp     ch, #_gs        wz      'left
              if_z      jmp     #leftright
                        cmp     ch, #_rs        wz      'up
              if_z      jmp     #up
                        cmp     ch, #_us        wz      'down
              if_z      jmp     #down
                        cmp     ch, #_spc       wc
              if_c      jmp     #nextchar               'ignore < $20                        
                                
'for now just display everything else
displaychar             mov     screenptr, i_charptr    'start of screen
                        add     screenptr, posn         '+ cursor posn
                        wrbyte  ch, screenptr           'store char
                        add     posn, #1                'next posn
                        cmp     posn, xeos      wc      'eos? end of screen?
              if_c      jmp     #nextchar               'no

                        jmp     #scroll                 'so scroll

gohome                  mov     posn, #0                'home
                        jmp     #nextchar

leftright               mov     col, #0
:leftright              add     col, #1                 'calc row no
                        sub     posn, #ocols    wc
              if_nc     jmp     #:leftright
                        add     posn, #ocols            'extract just col posn

                        cmp     ch, #_gs        wc      'set c if "right"

            if_c        add     posn, #1                '+1               \ right only
            if_c        cmp     posn, #ocols    wz      'wrap?            |
            if_c_and_z mov      posn, #0                'start of line    /

            if_nc       cmp     posn, #0        wz      'wrap?            \ left only
            if_nc       sub     posn, #1                '-1               |
            if_nc_and_z mov     posn, #ocols-1          'end of line      /

:leftright2             add     posn, #ocols            'add back rows
                        djnz    col, #:leftright2
                        sub     posn, #ocols            'correction
                        jmp     #nextchar

up                      sub     posn, #ocols    wc
              if_c      add     posn, xeos
                        jmp     #nextchar

down                    add     posn, #ocols
                        cmp     posn, xeos      wc      'eos?
              if_nc     sub     posn, xeos
                        jmp     #nextchar
              
bs                      mov     screenptr, i_charptr    'start of screen
                        sub     posn, #1        wc
              if_c      mov     posn, #0                'if < home, set to home
                        add     screenptr, posn         '+ cursor posn
                        wrbyte  x20202020, screenptr    'remove char
                        jmp     #nextchar

cr_                     mov     ch, #0
:cr                     add     ch, #1                  'calc row no
                        sub     posn, #ocols    wc
              if_nc     jmp     #:cr
                        mov     posn, #0                'home
                        cmp     ch, #orows      wz      'eos?
:cr2                    add     posn, #ocols            '=col*row
                        djnz    ch, #:cr2       
              if_nz     jmp     #nextchar               'not eos

scroll                  sub     posn, #ocols            'goto last line & then scroll
                        mov     cursorptr, i_charptr    'start of screen
                        mov     screenptr, i_charptr
                        add     screenptr, #ocols       'start of 2nd line
                        mov     col, #(ocols*(orows-1))/4 'calc no of longs to move
:scroll                 rdlong  ch, screenptr           'get 4 chars
                        add     screenptr, #4
                        wrlong  ch, cursorptr           'write them back 1 line up
                        add     cursorptr, #4
                        djnz    col, #:scroll
                        mov     col, #ocols/4           'calc no of longs on last line
:scroll2                wrlong  x20202020, cursorptr    'clear remaining line
                        add     cursorptr, #4
                        djnz    col, #:scroll2                         
                        jmp     #nextchar                        

lf                      add     posn, #ocols            'add row
                        cmp     posn, xeos      wc      'eos?
              if_c      jmp     #nextchar               'no
                        jmp     #scroll                 'if >eos, scroll

              
ch                      long    0                                                
col                     long    0
row                     long    0
posn                    long    0                       'current cursor posn
screenptr               long    0                       'screen hub ptr
cursorptr               long    0                       'cursor hub ptr
cursorchr               long    0                       'cursor char
framectr                long    0                       'frame counter (inc ea frame)
x02                     long    2                       'use for cursor char
x20202020               long    $20202020               '4 space chars      
xeos                    long    (ocols * orows)         'end of screen

taskptr                 long    0                       'to vt100 code
taskret                 long    0                       'returns to video code

                        long    0[$1F0-$]               'pad to fill cog space (because the screen lives here in hub) 
ends                    FIT     $1F0
                        org     0
                        long    0[4]                    'if 80*25 screen we require another 16 bytes 


{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    TERMS OF USE: Parallax Object Exchange License                                            │                                                            
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