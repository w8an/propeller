''stupid test program

CON

_clkmode = xtal1 + pll16x
_xinfreq = 5_000_000
 NUM_LINES = gfx#NUM_LINES
_stack   = 128
_free    = ($8000-gfx#text_colors+3)/4 ''TV parameter shiz+8 scanline buffers

 SCANLINE_BUFFER = gfx#SCANLINE_BUFFER
                                               
 request_scanline       = gfx#request_scanline 'address of scanline buffer for TV driver    
 border_color           = gfx#border_color 'address(!) of border color
 oam_adr                = gfx#oam_adr 'address of where sprite attribs are stored
 oam_in_use             = gfx#oam_in_use 'OAM adress feedback
 debug_shizzle          = gfx#debug_shizzle 'used for debugging, sometimes
 text_colors            = gfx#text_colors 'adress of text colors
 first_subscreen        = gfx#first_subscreen 'pointer to first subscreen
 buffer_attribs         = gfx#buffer_attribs 'array of 8 bytes
 aatable                = gfx#aatable 'array of 32 bytes
 aatable8               = gfx#aatable8 'array of 16 bytes
 text_colors            = gfx#text_colors 'array of 16 longs

 num_sprites    = gfx#num_sprites

VAR

OBJ

gfx : "JET_v02.spin"
kb  : "Keyboard"
music : "demo_music"



VAR

long framecnt
long scrollframe
word scrolloff
byte scrollchr
byte pal
long scroll

'long gfx_screen[32*16]
long cur_oam
byte color
long filter,border,memv
byte autoscroll,pause
long screen[16*4]
long scrollbuf[32]


PUB main | tileset_aligned, y, k, x, oam_length,s,t,u
  autoscroll~~
  music.Main
  bytemove(aatable,@aatabvals,32)
  bytemove(aatable8,@aatab8vals,16)                     
 'pst.start(115_200)
 kb.start(8,9)
 
 tileset_aligned := (@tileset + %1111_00)&(!%1111_11)
 if tileset_aligned & %1111_11
   reboot
 bytemove(tileset_aligned,@tileset+64,(@tileset_end-@tileset)-64)
 
 tiletest(true)   
 'longfill(@screen,%0000___000000_______0000_0__0_________0000___000001_______0000_0___0,32*12)

 'word[tilemap_adr] := @screen
 'word[tile_adr] := tileset_aligned
 word[oam_adr] := @oam1
 longmove(text_colors,@text_colos,16)
 word[first_subscreen] := @scroller_sub
 word[@scroller_sub+2] := @text_sub
 word[@text_sub+2] := @gfx_sub
 word[@gfx_sub+2] := @water_sub1
 word[@water_sub1+2] := @water_sub2
 word[@water_sub2+2] := @water_sub3
 word[@water_sub3+2] := @water_sub4
 word[@water_sub4+2] := @water_sub5
 word[@gfx_sub+10] := tileset_aligned
 word[@text_sub+10] := tileset_aligned
 word[@scroller_sub+10] := tileset_aligned
 word[@water_sub1+10] := tileset_aligned
 word[@water_sub2+10] := tileset_aligned
 word[@water_sub3+10] := tileset_aligned
 word[@water_sub4+10] := tileset_aligned
 word[@water_sub5+10] := tileset_aligned
 word[@gfx_sub+12] := @tilemap
 word[@water_sub1+12] := @watermap
 word[@water_sub2+12] := @watermap
 word[@water_sub3+12] := @watermap
 word[@water_sub4+12] := @watermap
 word[@water_sub5+12] := @watermap
 word[@text_sub+12] := @screen
 word[@scroller_sub+12] := @scrollbuf

 'longfill(@gfx_screen,((1) << 6) + (0 <<20),32*16)
 repeat y from 0 to 15
   repeat x from 0 to 31
     'gfx_screen[x+(y<<5)] := ((1+(x&1)) << 6) + (0 <<20) + 2 + ((x&8)>>3) + ((x&4)<<14)
        
 ''set up graphics driver
 gfx.start(%001_0101,%00) 'start graphics driver
 
 changefilter(0)
 changeborder(0)

 {oam1_enable  |= 0'%0000_0001_1111_1111_1111_1111_1111_1111
 oam1_mirror  |= %0000_0000_0000_0000_0000_0000_0000_0000
 oam1_flip    |= %0000_0000_0000_0000_0000_0000_0001_0001
 oam1_yexpand |= %0000_0000_0000_0000_0000_0000_1111_0001
 oam1_xexpand |= %0000_0000_0000_0000_0000_0000_1111_1111
 oam1_solid   |= %0000_0001_0000_0000_0000_0000_0000_1001
 
 oam2_enable  |= 0'%0000_0001_1111_1111_1111_1111_1111_1111
 oam2_mirror  |= %0000_0000_0000_0000_0000_0000_0000_0001
 oam2_flip    |= %0000_0000_0000_0000_0000_0000_0001_0001
 oam2_yexpand |= %0000_0000_0000_0000_0000_0000_1111_0001
 oam2_xexpand |= %0000_0000_0000_0000_0000_0000_1111_1111
 oam2_solid   |= %0000_0001_0000_0000_0000_0000_0000_1001

 repeat x from 0 to 7
  oam1_xpos.word[x] := ((x)*33)-1
  oam2_xpos.word[x] := ((x)*33)-1
 repeat x from 8 to 23
  oam1_xpos.word[x] := (x-8)*16
  oam2_xpos.word[x] := (x-8)*16
  oam1_ypos.word[x] := 40
  oam2_ypos.word[x] := 40
 repeat x from 24 to 31
  oam1_xpos.word[x] := 248
  oam2_xpos.word[x] := 248
  oam1_ypos.word[x] := 209
  oam2_ypos.word[x] := 209

 oam1_palette.byte[24] := 20
 oam2_palette.byte[24] := 20}
                       
 x := 1
 y := 100
 s := 96
 t := -3
 oam_length := @oam1-@oam1_end
 repeat
   {pst.str(string("aatable:",$0d))
   repeat k from 0 to 30 step 2
     pst.hex(byte[aatable+k],2)
     pst.char(" ")
     pst.hex(byte[aatable+k+1],2)
     pst.NewLine}
   'pst.hex(long[debug_shizzle],8)
   'pst.NewLine
   gfx.Wait_Vsync
   if cur_oam
     cur_oam := 0
     word[oam_adr] := @oam2
   else
     cur_oam := @oam2-@oam1
     word[oam_adr] := @oam1
   repeat 500 'fix screen tearing (a better method would involve double buffering subscreens)
   word[@gfx_sub+6] := scroll 
   
   
   k := kb.key
   case k
    $20: 'space
       NOT autoscroll
    $09:
       NOT pause
    $0D:
      changeborder(1)
    $C2:
      changefilter(-1)
    $C3:
      changefilter(1)
    $DC:
      gfx.tv_stop
      pal ^= 1
      gfx.tv_start(pal)

  if autoscroll
    scroll += 1
  
  if kb.keystate($C0)
    scroll -= 2
  if kb.keystate($C1)
    scroll += 2
  if kb.keystate($C6)
    memv-=4
    changeborder(0)
  if kb.keystate($C7)
    memv+=4
    changeborder(0)

  scroll &= (|<(4+5))-1
  if NOT pause
    framecnt++
  

  long[@oam1_enable+cur_oam] := 0
  long[@oam1_xexpand+cur_oam] := 0
  long[@oam1_yexpand+cur_oam] := 0


  s := (framecnt>>1) & 255
  if s < 128
    x := 224 + (s&127)
  else
    x:=  constant(224+128)-(s&127)

  long[@oam1_enable+cur_oam] |= |<26 
  byte[@oam1_pattern+cur_oam+26] := 31
  byte[@oam1_palette+cur_oam+26] := 30
  word[@oam1_xpos+cur_oam+(26<<1)] := ((x-scroll)<<23)~>23
  word[@oam1_ypos+cur_oam+(26<<1)] := 152

  long[@oam1_enable+cur_oam] |= |<27 
  byte[@oam1_pattern+cur_oam+27] := 31
  byte[@oam1_palette+cur_oam+27] := 30
  word[@oam1_xpos+cur_oam+(27<<1)] := ((x+16-scroll)<<23)~>23
  word[@oam1_ypos+cur_oam+(27<<1)] := 152

  long[@oam1_enable+cur_oam] |= |<25
  long[@oam1_flip+cur_oam] |= |<25
  byte[@oam1_pattern+cur_oam+25] := 29
  byte[@oam1_palette+cur_oam+25] := 27
  word[@oam1_xpos+cur_oam+(25<<1)] := ((x+6-scroll)<<23)~>23
  word[@oam1_ypos+cur_oam+(25<<1)] := 137
  
  long[@oam1_enable+cur_oam] |= |<31
  byte[@oam1_pattern+cur_oam+31] := 29
  byte[@oam1_palette+cur_oam+31] := 27
  word[@oam1_xpos+cur_oam+(31<<1)] := ((148-scroll)<<23)~>23
  word[@oam1_ypos+cur_oam+(31<<1)] := 48

  u := (framecnt/5)//6
  x := (-framecnt)&511

  long[@oam1_enable+cur_oam] |= |<8
  long[@oam1_xexpand+cur_oam] |= |<8 
  long[@oam1_yexpand+cur_oam] |= |<8 
  byte[@oam1_pattern+cur_oam+8] := lookupz(u:26,24,24,26,28,28)
  byte[@oam1_palette+cur_oam+8] := lookupz(u:25,23,23,25,27,27)
  word[@oam1_xpos+cur_oam+(8<<1)] := ((x-scroll)<<23)~>23
  word[@oam1_ypos+cur_oam+(8<<1)] := 56+(sin(framecnt*12)/3800)

  u := ((framecnt+2)/3)//6
  x := (framecnt<<1)&511

  long[@oam1_enable+cur_oam] |= |<9
  long[@oam1_mirror+cur_oam] |= |<9 
  'long[@oam1_yexpand+cur_oam] |= |<9 
  byte[@oam1_pattern+cur_oam+9] := lookupz(u:26,24,24,26,28,28)
  byte[@oam1_palette+cur_oam+9] := lookupz(u:25,23,23,25,27,27)
  word[@oam1_xpos+cur_oam+(9<<1)] := ((x-scroll)<<23)~>23
  word[@oam1_ypos+cur_oam+(9<<1)] := 72+(sin(framecnt*13)/2500)

  u := ((framecnt+3)/3)//6
  x := -((framecnt*3)>>1)&511

  long[@oam1_enable+cur_oam] |= |<10 
  byte[@oam1_pattern+cur_oam+10] := lookupz(u:26,24,24,26,28,28)
  byte[@oam1_palette+cur_oam+10] := lookupz(u:25,23,23,25,27,27)
  word[@oam1_xpos+cur_oam+(10<<1)] := ((x-scroll)<<23)~>23
  word[@oam1_ypos+cur_oam+(10<<1)] := 169+(sin(framecnt<<4)/3000)

  'u := hexchars.byte[(scroll-8)&15]
  'word[@screen+2] := $8000+((u>>1)<<7)+ ((u&1)) 
 

  {long[@oam1_enable+cur_oam] |= |<25
  long[@oam1_xexpand+cur_oam] |= |<25 
  long[@oam1_yexpand+cur_oam] |= |<25 
  byte[@oam1_pattern+cur_oam+25] := 24
  byte[@oam1_palette+cur_oam+25] := 23
  word[@oam1_xpos+cur_oam+(25<<1)] := 25
  word[@oam1_ypos+cur_oam+(25<<1)] := 128

  long[@oam1_enable+cur_oam] |= |<26
  byte[@oam1_pattern+cur_oam+26] := 26
  byte[@oam1_palette+cur_oam+26] := 25
  word[@oam1_xpos+cur_oam+(26<<1)] := 64
  word[@oam1_ypos+cur_oam+(26<<1)] := 48

  long[@oam1_enable+cur_oam] |= |<27
  long[@oam1_xexpand+cur_oam] |= |<27 
  long[@oam1_yexpand+cur_oam] |= |<27 
  byte[@oam1_pattern+cur_oam+27] := 26
  byte[@oam1_palette+cur_oam+27] := 25
  word[@oam1_xpos+cur_oam+(27<<1)] := 64
  word[@oam1_ypos+cur_oam+(27<<1)] := 128

  long[@oam1_enable+cur_oam] |= |<28
  byte[@oam1_pattern+cur_oam+28] := 28
  byte[@oam1_palette+cur_oam+28] := 27
  word[@oam1_xpos+cur_oam+(28<<1)] := 112
  word[@oam1_ypos+cur_oam+(28<<1)] := 48

  long[@oam1_enable+cur_oam] |= |<29
  long[@oam1_xexpand+cur_oam] |= |<29 
  long[@oam1_yexpand+cur_oam] |= |<29 
  byte[@oam1_pattern+cur_oam+29] := 28
  byte[@oam1_palette+cur_oam+29] := 27
  word[@oam1_xpos+cur_oam+(29<<1)] := 112
  word[@oam1_ypos+cur_oam+(29<<1)] := 128}

 { long[@oam1_enable+cur_oam] |= |<30
  byte[@oam1_pattern+cur_oam+30] := 29
  byte[@oam1_palette+cur_oam+30] := 27
  word[@oam1_xpos+cur_oam+(30<<1)] := 160
  word[@oam1_ypos+cur_oam+(30<<1)] := 48

  long[@oam1_enable+cur_oam] |= |<31
  long[@oam1_xexpand+cur_oam] |= |<31 
  long[@oam1_yexpand+cur_oam] |= |<31 
  byte[@oam1_pattern+cur_oam+31] := 29
  byte[@oam1_palette+cur_oam+31] := 27
  word[@oam1_xpos+cur_oam+(31<<1)] := 160
  word[@oam1_ypos+cur_oam+(31<<1)] := 128 }

   

  'word[@gfx_sub+4] := 0'sin(s*64)/$3FF
  'word[@gfx_sub+6] := 0'sin((s*(-64))+$800)/$3FF
  'word[@gfx_sub+8] := 8'lookupz(s&1:9,8)
  'word[@text_sub+8] := s&1
  'word[@gfx_sub+6] := -256
  'word[@text_sub+0] := s+100
  'word[@text_sub+4] := (-s)-100
  'word[@text_sub+6] := 0's/2

  word[@water_sub1+6] := (scroll*10 /  17) + (sin(framecnt*11)/4500)
  word[@water_sub2+6] := (scroll*10 /  15) + (sin(framecnt*23)/4000)
  word[@water_sub3+6] := (scroll*10 /  13) + (sin(framecnt*29)/3500)
  word[@water_sub4+6] := (scroll*9 /  7) + (sin(framecnt*41)/3000)
  word[@water_sub5+6] := (scroll*9 /  5) + (sin(framecnt*47)/2500)

  word[@water_sub1+4] := (-23*8) + ||(sin(framecnt*2)/4500)
  word[@water_sub2+4] := (-23*8) + ||(sin(framecnt*5)/4200)
  word[@water_sub3+4] := (-23*8) + ||(sin(framecnt*7)/4000)
  word[@water_sub4+4] := (-23*8) + ||(sin(framecnt*12)/3800)
  word[@water_sub5+4] := (-24*8) + (sin(framecnt*15)/3850)

  if scrollframe & %111
  else
    k := byte[@scrolltext+scrolloff]
    scrolloff++
    if k==0
      scrolloff~
      k := byte[@scrolltext+scrolloff]
      scrolloff++
    if k>$EF
      color := k&$F
      k := byte[@scrolltext+scrolloff]
      scrolloff++
    if k==1
      word[@scrollbuf+(((scrollchr-1)&%11111)<<1)] := byte[@scrolltext+(scrolloff++)] + (byte[@scrolltext+(scrolloff++)]<<8) 
    else
      word[@scrollbuf+(((scrollchr-1)&%11111)<<1)] := $8000+((k>>1)<<7)+ ((k&1)) + (color<<2) 
    scrollchr++
  word[@scroller_sub+6] := scrollframe
  scrollframe++

  
  
 

PUB tiletest(init) |  k, x,b0,b1,c,n
if init
  n~
  longfill(@screen,((1) << 6) + (0 <<20),16*4)
  repeat x from 0 to ((32*4)-1)
    k := byte[@text_str+x]
    word[@screen+(x<<1)] := $8000+((k>>1)<<7)+ ((k&1))
 
PUB sin(angle) : s | c,z
  c := angle & $800            'angle: 0..8192 = 360°
  z := angle & $1000
  if c
    angle := -angle
  angle |= $E000>>1
  angle <<= 1
  s := word[angle]
  if z
    s := -s                    ' return sin = -$FFFF..+$FFFF

DAT

gfx_sub
word 5*8  'ystart
word 0  ' next (gets set at runtime due to spin wierdness)
word -5*8 ' yscroll
word (-8)+(8*16) ' xscroll
word 9 ' mode
word 0  ' tile_base (must be 64-byte-aligned) (also gets set at run time)
word 0  ' map_base (also gets set at run time)
word %1111_11111_00 ' map_mask
word 32<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 5+2 ' map_y_shift
word 4 'tile_height (well, technically log2(tile_height))

water_sub1
word 224-(5*8)  'ystart
word 0  ' next (gets set at runtime due to spin wierdness)
word -5*8 ' yscroll
word -8  ' xscroll
word 9 ' mode
word 0  ' tile_base (must be 64-byte-aligned) (also gets set at run time)
word 0  ' map_base (also gets set at run time)
word %11_1_00 ' map_mask
word 2<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 1+2 ' map_y_shift
word 4 'tile_height (well, technically log2(tile_height))

water_sub2
word 224-(4*8)  'ystart
word 0  ' next (gets set at runtime due to spin wierdness)
word -5*8 ' yscroll
word -8  ' xscroll
word 9 ' mode
word 0  ' tile_base (must be 64-byte-aligned) (also gets set at run time)
word 0  ' map_base (also gets set at run time)
word %11_1_00 ' map_mask
word 2<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 1+2 ' map_y_shift
word 4 'tile_height (well, technically log2(tile_height))

water_sub3
word 224-(3*8)  'ystart
word 0  ' next (gets set at runtime due to spin wierdness)
word -5*8 ' yscroll
word -8  ' xscroll
word 9 ' mode
word 0  ' tile_base (must be 64-byte-aligned) (also gets set at run time)
word 0  ' map_base (also gets set at run time)
word %11_1_00 ' map_mask
word 2<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 1+2 ' map_y_shift
word 4 'tile_height (well, technically log2(tile_height))

water_sub4
word 224-(2*8)  'ystart
word 0  ' next (gets set at runtime due to spin wierdness)
word -5*8 ' yscroll
word -8  ' xscroll
word 9 ' mode
word 0  ' tile_base (must be 64-byte-aligned) (also gets set at run time)
word 0  ' map_base (also gets set at run time)
word %11_1_00 ' map_mask
word 2<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 1+2 ' map_y_shift
word 4 'tile_height (well, technically log2(tile_height))

water_sub5
word 224-(1*8)  'ystart
word 0  ' next (gets set at runtime due to spin wierdness)
word -5*8 ' yscroll
word -8  ' xscroll
word 9 ' mode
word 0  ' tile_base (must be 64-byte-aligned) (also gets set at run time)
word 0  ' map_base (also gets set at run time)
word %11_1_00 ' map_mask
word 2<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 1+2 ' map_y_shift
word 4 'tile_height (well, technically log2(tile_height))

text_sub
word 16 'ystart
word 0  ' next 
word -16  ' yscroll
word 0  ' xscroll
word 1  ' mode
word 0  ' tile_base (must be 64-byte-aligned) (also gets set at run time)
word 0  ' map_base (also gets set at run time)
word %11_1111_00 ' map_mask
word 16<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 4+2 ' map_y_shift
word 3 'tile_height (well, technically log2(tile_height))

scroller_sub
word 0 'ystart
word 0  ' next 
word 0  ' yscroll
word 0  ' xscroll
word 3  ' mode
word 0  ' tile_base (must be 64-byte-aligned) (also gets set at run time)
word 0  ' map_base (also gets set at run time)
word %11111_00 ' map_mask
word 16<<2 ' map_width in bytes (must be power of 2 for wraparound)
word 5+2 ' map_y_shift
word 4 'tile_height (well, technically log2(tile_height))


'byte 0[63]


text_str
byte "XJET Engine - Castlevania demo!X"
'byte 0[32]
'byte "X Space to toggle autoscroll  X"
byte "XPrint/SysRq to toggle NTSC/PALX"
'byte 0[32]
byte "X Arrows to scroll and filter  X"

scrolltext
byte $F0,"Test 1 2 3...... Hello there! Can you read me? "
byte "Yes?      Good.  It's me, the person writing a "
byte "graphics driver! This one is called JET ENGINE! "
byte "... ... Yes, it's yet another Propeller pun. "
byte "Anyways, here's a quick breakdown of it's features: "
byte "First off, this driver has multiple modes. Let's start with mode 8: "
byte "256x224 resolution == 16*12 tiles, 16x16 each. "
byte "tiles are ",$22,"pseudo 4 bits-per-pixel",$22,". "
byte "More on what the frick that means later. "
byte "Tiles can be flipped and mirrored at no cost. "
byte "32 sprites simultaneously! They use the same patterns and palettes as tiles. "
byte "Sprites can also be flipped and mirrored at no cost. "
byte "Additionally, sprites can be doubled in width and/or height. "
byte "(Note: Too many (especially double-width) sprites on one line can cause minor glitches due to insufficient fillrate.) "
byte "Sprites can also be made solid to use all palette colors (like tiles). "
byte "Also, the tile layer can be scrolled up and down. (Sprites are unaffected by scrolling) "
byte "Want to scroll left and right (or even 8-way!)? Mode 9 is for you! "
byte "It does all the things mode 8 does, but only at 240x224. "
byte "However, you can put cute little patterns on the masked out screen space.  ",$FF,"(^.^)/  ",$F0
byte "This is the mode used for the graphics below. "
byte "Now the other 9 modes are less interesting: Mode -1 is just the background color. Yawn. "
byte "Mode 0 is a 32x24 character mode. It uses ROM font style characters, but they don't neccessarily need to be in ROM, "
byte "any 32-long aligned address is fair game. "
byte "You may have noticed that those characters are only 8 lines high, but the ROM font is 32 lines high. How can this 1:4 scaling ratio be achieved "
byte "with reasonable results? Optimized antialiasing, of course. For each scanline of a character, two lines of the font, determined by a table, are read "
byte "and rearranged into a single 4-color line. Just mess around with aaedit.spin to figure it out. "
byte "Mode 1 is the same as mode 0, but with scrolling. This is the mode used for the instruction text directly below this scroller! "
byte "Mode 2 is the same as mode 0, but the characters are twice as tall. "
byte "Mode 3 is the same as mode 2, but with scrolling. "
byte "Mode 4 is the same as mode 2, but instead of using a lookup table, it uses a 1:1 bit mapping. i.e. each bit of the "
byte "character becomes one bit of the output. "
byte "Mode 5 is the same as mode 4, but with scrolling. "
byte "Mode 6 is the same as mode 4, but the characters are twice as tall again. This looks similiar to what TV.spin does. "
byte "Mode 7 is the same as mode 6, but with scrolling. "
byte "These text modes also support inserting graphics tiles. However, this only really makes sense for 16-line-per-character modes. "
byte "(Actually, one can make clever use of GFX tiles in 8-line text mode)"
byte "Also, they can glitch at the edge of a horizontally scrolling screen. "
byte "Here are some... poor skelington: "
byte 1
byte word (8<<6)+2
byte 1
byte word (1<<6)+0
byte "  Block: "
byte 1
byte word (7<<6)+2
byte 1
byte word (1<<6)+0  
byte "   Oh, and you can have 16 ",$F1,"d",$F2,"i",$F3,"f",$F4,"f",$F5,"e",$F6,"r",$F7,"e",$F8,"n",$F9,"t ",$FA,"t",$FB,"e",$FC,"x",$FD,"t ",$FE,"c",$FF,"o",$F1,"l",$F2,"o",$F3,"r",$F4,"s",$F0,". You can even choose them yourself! "
byte "I think that is about it....   except it's not. "
byte "You may have wondered how I can use multiple modes at the same time. "
byte "SUBSCREENS! Subscreens for everone! What is a subscreen even? "
byte "A subscreen is a data structure that stores configuration for a horizontal strip of the screen. "
byte "Stuff like mode, scroll positions, tilemap properties, tileset pointer and a pointer to the next subscreen. "
byte "Yes, they are a linked list. You can have an infinite amount of them (well, as many as you can fit in memory). "
byte "Note: this demo does not double-buffer the subscreens. This can cause issues when moving them around. "
byte "But doing it in Spin is a little bit annoying due to the lack of structs and it doesn't matter much in this demo. "
byte "Also, if you pressed some buttons while staring at the screen, you may have seen another unique feature: "
byte "Full-screen post-processing. Oh yes. Well, post-",$22,$22,$22,"processing",$22,$22,$22,". "
byte "Basically, you can apply two instructions per four-pixel group. What this can do obviously depends on "
byte "the pixel format. Currently, only NTSC/PAL60, minus saturated colors (they make filtering impossible and don't work with SVideo) are supported, "
byte "but support for SCART-style 15khz RGB in 64 and 256 color varieties shouldn't be too hard to add, seeing as the NTSC/PAL specific part of the driver is neatly seperated. "
byte "VGA however, due to its 31khz line rate, is impossible. well, as impossible as is possible on the propeller ;-) "
byte "Are we done yet? I think we are. Still awake? No. Darn it. "
byte "       Well, I'm here anyways, so let's talk about that pseudo 4bpp thing i mentioned earlier. "
byte "Now, each tile is 16x16. Each is represented by a pattern, 16 longs. But w w wwwait that's only 2bpp?? "
byte "How do we solve this conundrum? With another kind of tile! Palette tiles! Yes. "
byte "These contain a seperate 4 color palette for every scanline. 16 longs. This is a nice compromise of true 4bpp, 2bpp and 8bpp. "
byte "Now, some misfeatures for a change: Tiles must be delta coded. Essentially, imagine color as a 2 bit accumulator "
byte "that indexes into the palette and that the pixel values are added to. (of course, this gets reset for every tile/sprite) "
byte "This is done to save 16 cycles per tile pixel.... "
byte "Also, some 4 color palettes, can cause unexpected results when used on sprites: if the top and bottom 16 bits are equal.... "
byte "Altough you could use that for some kind of effect, i guess. "
byte "Another downside is the high resource usage: It needs some 4K of memory just for scratch space and of course, 5 jam-packed cogs... "  
byte "As you may have noticed, the stuff below "
byte "is a rough approximation of a part of a level from Castlevania "
byte "1. This doesn't really show the potential of the JET engine, but "
byte "when a person on Discord suggested it, I remembered the first Retronitus demo tune, "
byte "which of course is from Castlevania, too. What a perfect fit. "
byte "Well, i added a nice parallax (heh) water effect. Very nice. "
byte "I should tell you that i made this without any kind of map or tile editor. This is why the scene is only ~2 screens (32 tiles) wide: "
byte "Not becasue there isn't enough memory (heck, you've seen all this text), but because typing stuff in is painful and im not a masochist :P  "
byte $FF,"    Wuerfel_21 signing out. ",0

hexchars
byte "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

''01213355
''789ACBED
''FGIHKJLM
''NOPQSSTU
aatabvals
byte  0<<2, 1<<2
byte  2<<2, 1<<2
byte  4<<2, 3<<2
byte  6<<2, 5<<2
byte  7<<2, 8<<2
byte  9<<2,10<<2   
byte 11<<2,12<<2
byte 14<<2,13<<2
byte 15<<2,16<<2
byte 18<<2,17<<2
byte 20<<2,19<<2
byte 22<<2,21<<2
byte 24<<2,23<<2
byte 25<<2,26<<2
byte 28<<2,28<<2
byte 29<<2,30<<2
''2467CBEF
''IHJLOQST
aatab8vals      
byte  2<<2, 4<<2
byte  6<<2, 7<<2
byte 12<<2,11<<2
byte 14<<2,15<<2
byte 18<<2,17<<2
byte 19<<2,21<<2
byte 24<<2,26<<2
byte 28<<2,29<<2


org 0
oam1
oam1_enable    long %0
oam1_flip      long %0
oam1_mirror    long %0
oam1_yexpand    long %0
oam1_xexpand    long %0
oam1_solid     long %0
oam1_ypos      word 3[num_sprites]
oam1_xpos      word 2[num_sprites]
oam1_pattern   byte 2[num_sprites]
oam1_palette   byte 0[num_sprites]
oam1_end

'org 0
oam2
oam2_enable    long %0
oam2_flip      long %0
oam2_mirror    long %0
oam2_yexpand    long %0
oam2_xexpand    long %0
oam2_solid     long %0
oam2_ypos      word 3[num_sprites]
oam2_xpos      word 2[num_sprites]
oam2_pattern   byte 2[num_sprites]
oam2_palette   byte 0[num_sprites]
oam2_end

text_colos
text_white     long $07_05_04_02
               long $0E_0C_0B_02
               long $1E_1C_1B_02
               long $2E_2C_2B_02
               long $3E_3C_3B_02
               long $4E_4C_4B_02
               long $5E_5C_5B_02
               long $6E_6C_6B_02
               long $7E_7C_7B_02
               long $8E_8C_8B_02
               long $9E_9C_9B_02
               long $AE_AC_AB_02
               long $BE_BC_BB_02
               long $CE_CC_CB_02
               long $DE_DC_DB_02
               long $EE_EC_EB_02



{text_grey    long $06_03_03_02
text_white    long $07_03_03_02

text_white2   long $07_04_04_02
text_white3   long $07_05_05_02
text_noaa   long $07_02_02_02
text_or   long $07_07_07_02
text_t1   long $07_05_04_02
text_t2   long $07_04_05_02
text_rednew   long $CD_CC_CC_02

text_red    long $CD_CB_CB_02
'text_red2    long $48_CC_CC_02
text_purple    long $ED_EB_EB_02
'text_purple2    long $68_EC_EC_02
text_violet   long $0D_0B_0B_02
'text_violet2    long $88_0C_0C_02
text_blue   long $2D_2B_2B_02
'text_blue2    long $A8_2C_2C_02
text_teal   long $4D_4B_4B_02
'text_teal2    long $C8_4C_4C_02
text_green   long $6D_6B_6B_02
'text_green2    long $E8_6C_6C_02
text_yellow   long $8D_8B_8B_02
'text_yellow2    long $08_8B_8B_02}


tileset

long 0[16] ' = alignment buffer

' tiles, both of the "palette" and "pattern" variety

{long $07_04_0D_0C
long $07_04_1D_1C
long $07_04_2D_2C
long $07_04_3D_3C
long $07_04_4D_4C
long $07_04_5D_5C
long $07_04_6D_6C
long $07_04_7D_7C
long $07_04_8D_8C
long $07_04_9D_9C
long $07_04_AD_AC
long $07_04_BD_BC
long $07_04_CD_CC
long $07_04_DD_DC
long $07_04_ED_EC
long $07_04_FD_FC}
long $0C_0B_BA_02[16]

long $07_AE_AD_02[6]
long $07_AE_AC_02[3]
long $07_AE_AB_02[4]
long $07_AD_AB_02[3] 

'long $07_1C_BC_02[16]

long $1B_1A_03_02[9]
long $1C_2B_2A_03[7]

long $1D_2C_2B_2A[9]
long $1E_2D_2C_2B[7]

long $07_3E_2D_2C[16]

'long $07_BE_BC_02[16]
'long $07_BE_BC_02[16]
long $07_AE_AC_02[16]

' pattern tiles are 2-bit delta encoded

'nothing
long %%0000_0000_0000_0000[16]

'block
long %%0000_0000_0000_0000
long %%0020_0031_0000_0011
long %%0113_0000_0000_0011
long %%0100_0010_0031_0001
long %%0100_1000_0000_0001
long %%0101_0000_0000_0311
long %%0110_0000_0000_0001
long %%0101_0000_0000_0002
long %%0110_0000_0000_0000
long %%0231_0000_0000_0000
long %%0231_0000_0000_0000
long %%0231_0000_0000_0000
long %%0110_0000_0000_0000
long %%0103_2002_2000_0000
long %%0000_2020_2222_2000
long %%0000_0000_0000_0000

'skelington
long %%0003_1031_0021_0320
long %%3010_0301_0210_0032
long %%0301_0031_2110_3001
long %%0030_1031_2110_3122
long %%0021_1000_0300_1022
long %%0002_0200_3322_2022
long %%3010_0312_0000_0020
long %%3320_0310_0020_2000
long %%0000_0310_3100_0301
long %%0310_3010_0310_0301
long %%0301_0003_1033_2000
long %%0031_0000_3100_0310
long %%0030_1031_0332_3100
long %%0303_2030_1000_0000
long %%3001_0313_0000_0100
long %%3302_3103_1000_0000

'rocks 1
long %%2100_0010_2001_0010
long %%2100_0010_2001_0010
long %%2010_0001_2221_0010
long %%0220_0301_0003_0010
long %%0300_0130_1000_3000
long %%0303_1013_3020_2100
long %%0030_3110_3003_1000
long %%2230_1301_3310_0000
long %%2100_0010_2130_0103
long %%2100_0010_3300_1030
long %%2010_0001_3322_1030
long %%0220_0301_3103_0030
long %%0300_0130_3203_3000
long %%0303_1013_1210_3000
long %%0030_3110_0303_1300
long %%2230_1301_0303_1300

'rocks 2 (right edge)
long %%3302_0002_2000_0000
long %%2002_0002_2000_0000
long %%2002_0002_0020_0000
long %%2000_2020_1000_1000
long %%0020_2000_2001_0100
long %%0220_0211_2131_0100
long %%0000_0301_3000_0001
long %%0000_3001_2010_0012
long %%0020_0200_3300_2033
long %%0002_0022_1300_1003
long %%3102_0022_1302_3030
long %%3001_2112_1302_3030
long %%3001_0330_0023_0300
long %%3001_0202_2023_0302
long %%1200_1200_0203_3002
long %%1200_1002_0203_3020

'rocks 3 (left edge)
long %%0000_0000_2100_0010
long %%0000_0000_2100_0010
long %%0000_0000_2010_0001
long %%0000_0000_0220_0301
long %%0000_0000_0300_0130
long %%0000_0000_0303_1013
long %%0000_0000_0030_3110
long %%0000_0000_2230_1301
long %%0000_0000_0033_0200
long %%0000_0000_0030_0020
long %%0000_0000_0003_0032
long %%0000_0000_0000_2200
long %%0000_0000_0000_2200
long %%0000_0000_0000_2230
long %%0000_0000_0000_0201
long %%0000_0000_0000_0021

'rocks 4
long %%2130_0103_0001_0010
long %%3300_1030_0001_0010
long %%3322_1030_0221_0010
long %%3103_0030_2003_0010
long %%2203_3000_2000_3000
long %%0210_3000_0020_2100
long %%0303_1300_1003_1000
long %%0303_1300_1310_0000
long %%2001_0010_2010_0001
long %%2001_0010_3000_0001
long %%2221_0010_3000_3101
long %%0003_0010_2001_0310
long %%0000_3000_0100_2010
long %%2020_2100_3222_2010
long %%3003_1000_1022_2010
long %%3310_0000_3000_0001

'rocks 5
long %%0020_0200_3302_0002
long %%0002_0022_0002_0002
long %%3102_0022_0002_0002
long %%3001_2112_0000_2020
long %%3001_0330_2020_2000
long %%3001_0202_0220_0211
long %%1200_1200_2000_0301
long %%1200_1002_2000_3001
long %%0000_0210_3200_0033
long %%0000_0300_1000_0330
long %%0000_0300_1021_0300
long %%0000_0003_1210_3000
long %%0000_0003_3100_3000
long %%0002_2000_3000_3000
long %%2200_0000_3000_3000
long %%2200_2202_1003_0000

'rocks 6
long %%2010_0001_2130_0103
long %%3000_0001_3300_1030
long %%3000_3101_3322_1030
long %%2001_0310_0103_0030
long %%3100_2010_3203_3000
long %%2222_2010_1210_3000
long %%0022_2010_1303_1300
long %%2000_0001_1303_1300
long %%3300_2033_0001_0010
long %%3300_1003_0001_0010
long %%3302_3030_0221_0010
long %%3302_3030_2003_0010
long %%2023_0300_2000_3000
long %%2023_0302_2020_2100
long %%2203_3002_3003_1000
long %%2203_3020_3310_0000

'rocks 7 (topleft corner)
long %%2100_0010_3010_3032
long %%2100_0010_3013_0010
long %%2010_0001_0210_0010
long %%0220_0301_2010_0100
long %%0300_0130_3022_1100
long %%0303_1013_3022_0200
long %%0030_3110_2230_1000
long %%2230_1301_3010_0000
long %%3010_3032_0000_0000
long %%3013_0010_0000_0000
long %%0210_0010_0000_0000
long %%2010_0100_0000_0000
long %%2022_1100_0000_0000
long %%2022_0200_0000_0000
long %%2230_1000_0000_0000
long %%3010_0000_0000_0000

'rocks 8 (top thingy)
long %%0033_0200_3302_0002
long %%0030_3020_2002_0002
long %%0003_0032_2002_0002
long %%0000_2200_2000_2020
long %%0000_2200_0020_2000
long %%0000_2230_1220_0211
long %%0000_0201_1000_0301
long %%0000_0021_1000_3001
long %%0000_0000_0000_0000[8]

'rocks 9 (bottomleft corner)
long %%0000_0000_0000_0000[10]
long %%2020_0000_0000_0000
long %%3000_1000_0000_0000
long %%2001_0100_0000_0000
long %%2131_0100_0000_0000
long %%3000_0001_0000_0000
long %%2010_0012_2000_0000

'rocks 10 (topright corner)
long %%0000_0000_0033_0200
long %%0000_0000_0030_3020
long %%0000_0000_0003_0030
long %%0000_0000_0000_2200
long %%0000_0000_0000_2200
long %%0000_0000_0000_2230
long %%0000_0000_0000_0201
long %%0000_0000_0000_0021
long %%0000_0000_0000_0000[8]
         
'rocks 11
long %%0000_0000_0000_0000
long %%0000_0000_0030_0000
long %%0000_0000_3000_0000
long %%0000_0000_3031_3000
long %%0000_0000_2000_0000
long %%0000_0003_3000_0000
long %%0000_0030_0300_0000
long %%0000_0303_0000_0002
long %%2010_0001_2001_0010
long %%3000_0001_2001_0010
long %%3000_3101_2221_0010
long %%2001_0310_1003_0010
long %%3100_2010_1000_3000
long %%2222_2010_3020_2100
long %%0022_2010_0003_1000
long %%2000_0001_0310_0000

'"pillar" left
long %%0011_0200_0020_0200
long %%0010_1020_0002_0022
long %%0001_0012_1302_0022
long %%0000_2200_1003_2332
long %%0000_2200_1003_0110
long %%0000_2210_0003_0202
long %%0000_0203_2200_3200
long %%0000_0023_2200_3002
long %%0000_1010_0003_0030
long %%0000_1001_0003_0030
long %%0000_1001_0223_0030
long %%0000_1000_3001_0030
long %%0000_1012_0000_1000
long %%0001_0300_2020_2300
long %%0001_0300_1001_3000
long %%0010_0000_0130_0000

'"pillar" right
long %%2300_0030_1030_1012
long %%2300_0030_1031_0030
long %%2030_0003_0230_0030
long %%0220_0103_2030_0300
long %%0100_0310_1022_3300
long %%0101_3031_1022_0200
long %%0010_1330_2210_3000
long %%2210_3103_1030_0000
long %%1100_2011_2000_0000
long %%1100_3001_2000_0000
long %%1102_1010_0020_0000
long %%1102_1010_3000_3000
long %%2021_0100_0003_0300
long %%2021_0102_2313_0300
long %%2201_1002_1000_0003
long %%2201_1020_2030_0032

' water
long %%1003_0130_0010_3012
long %%1201_0320_2002_2000
long %%3000_0002_2000_0000
long %%3002_2000_0000_3010
long %%1001_3130_0001_0030
long %%1103_1313_1000_1003
long %%2100_0331_0031_0000
long %%2020_0200_0000_0000
long %%0000_0003_0100_0030
long %%0003_0100_0010_3030
long %%0012_0020_3302_0301
long %%1020_0203_0120_0002
long %%1200_0200_0200_2202
long %%3300_0100_0301_0220
long %%2000_0010_3000_0000
long %%2000_1030_0000_0103

' bat frame 1 (wings up) palette
long $BD_3A_3B_02
long $BD_BB_9D_02
long $BD_BB_9E_02
long $3A_3B_9D_02

long $BD_BB_3A_02[7]
long $BD_3A_3B_02

long $3D_3A_3B_02
long $3C_3A_3B_02
long $3D_3A_3B_02[2]

' bat frame 1 (wings up) pattern
long %%0000_0000_0010_1030
long %%0000_0001_0010_0100
long %%0000_0101_0000_1001
long %%0000_1020_0000_3003

long %%0000_1001_0001_0001
long %%0001_0013_0020_0010
long %%0032_0132_3120_2010
long %%0001_0010_1310_2030

long %%0001_0131_0100_0010
long %%0001_0010_1000_0100
long %%0010_0132_3100_1000
long %%0320_1000_0010_2300

long %%0101_0030_0010_3210
long %%0002_3020_0020_1321
long %%0000_0010_0001_2000
long %%0000_0000_0000_0000


' bat frame 2 (middle) palette
long $3B_3B_3B_02[6]
long $9E_9D_3D_02
long $9D_3B_3C_02

long $BB_3B_3C_02
long $BD_3B_3C_02
long $BD_3A_3B_02
long $BB_3A_3B_02

long $3C_3A_3B_02[4]

' bat frame 2 (middle) pattern
long %%0000_0000_0000_0000[6]
long %%0021_3300_0300_0000
long %%0021_2001_3131_2000

long %%0000_3033_1313_0030
long %%0022_2010_0331_0033
long %%0320_1000_0100_2133
long %%0101_0030_0100_1032

long %%0002_3020_0021_0330
long %%0000_0010_0010_2000
long %%0000_0000_0000_0000[2]

' bat frame 3 (wings down) palette
long $3A_3C_3B_02[2]
long $3C_BD_3B_02
long $3C_9D_3B_02

long $3A_3C_3B_02
long $3A_9E_3B_02
long $3A_9D_3B_02
long $3A_3C_3B_02

long $3A_9D_3B_02
long $3A_9E_3B_02
long $3A_9D_3B_02
long $3A_3C_3B_02

long $3A_3C_3B_02[4]

' bat frame 3 (wings down) pattern
long %%0000_0000_0000_0000
long %%0031_0000_0000_0000
long %%0230_0022_0300_0000
long %%0100_2300_1200_3000

long %%0001_0010_3000_0210
long %%0230_0000_0002_2030
long %%0101_0300_0202_0300
long %%0230_0130_2023_0000

long %%0100_0022_0003_0000
long %%0100_0002_0212_0000
long %%0010_0022_2230_0000
long %%0010_0222_2300_0000

long %%0001_2000_2300_0000
long %%0001_0202_0300_0000
long %%0000_0100_1200_0000
long %%0000_0000_0000_0000

' bat frame 4 (hanging) pattern
long %%0000_0013_0013_0000
long %%0000_0302_2222_3000
long %%0000_0100_0000_3000
long %%0000_0100_0000_3000

long %%0000_1112_2310_2300
long %%0000_1000_2220_2300
long %%0000_1002_0022_2300
long %%0000_1000_2022_2300

long %%0003_2130_0200_0230
long %%0003_2130_2200_2230
long %%0001_0130_0001_0110
long %%0000_1002_0000_2300

long %%0000_0032_0201_0000
long %%0000_0002_3030_0000
long %%0000_0013_0013_0000
long %%0000_0000_0000_0000

'platform palette
long $8E_9D_BB_02[3]
long $8E_9D_AB_02[5]
long $02_02_02_02[8]

'platform pattern
long %%0300_0001_0300_0001
long %%3200_0002_0200_0002
long %%3200_0002_0200_0002
long %%3200_0002_0200_0002
long %%3200_0002_0200_0002
long %%3200_0002_0200_0002
long %%2030_0023_0030_0023
long %%0020_0020_0020_0002
long %%1000_1000_1000_1000[8]









 
{long %%0000_0003_0100_0000 
long %%0000_0003_0100_0000 
long %%0000_0031_0310_0000 
long %%0000_0031_0310_0000 
long %%0000_0310_0031_0000 
long %%0000_0310_0031_0000 
long %%0000_3100_0003_1000 
long %%0000_3100_0003_1000 
long %%0003_1000_0000_3100 
long %%0003_1000_0000_3100 
long %%0031_0000_0000_0310 
long %%0031_0000_0000_0310 
long %%0310_0000_0000_0031 
long %%0310_0000_0000_0031 
long %%3100_0000_0000_0003 
long %%3100_0000_0000_0003}

{long %%2000_0000_0000_0000 
long %%0000_0000_0000_0000 
long %%0000_0000_0000_0000 
long %%0000_0000_0000_0000 
long %%0000_0000_0003_1000 
long %%0000_0000_0003_0100 
long %%0000_0000_0003_0010 
long %%0300_0000_0000_0001 
long %%0300_0000_0000_0001 
long %%0000_0000_0003_0010 
long %%0000_0000_0003_0100 
long %%0000_0000_0003_1000 
long %%0000_0000_0000_0000 
long %%0000_0000_0000_0000 
long %%0000_0000_0000_0000 
long %%2000_0000_0000_0000}

long %%31<<28[16]
long %%31<<26[16]
long %%31<<24[16]
long %%31<<22[16]
long %%31<<20[16]
long %%31<<18[16]
long %%31<<16[16]
long %%31<<14[16]
long %%31<<12[16]
long %%31<<10[16]
long %%31<<8[16]
long %%31<<6[16]
long %%31<<4[16]
long %%31<<2[16]
long %%31[16]
long %%3[16]
long %%0[16]

long $07_05_03_02[16]  

org 0 ' long align
tileset_end

tilemap
long  ((0<<22)+(0<<16)+(9<<6)+0) , ((0<<22)+(0<<16)+(10<<6)+0), ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0)
long  ((23<<22)+(0<<16)+(6<<6)+0) , ((25<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0)
long  ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(11<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)

long  ((0<<22)+(0<<16)+(14<<6)+0), ((0<<22)+(0<<16)+(15<<6)+0), ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0)
long  ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0)
long  ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(16<<6)+0), ((0<<22)+(1<<16)+(10<<6)+1)
long  ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1), ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1)
long  ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1), ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1)
long  ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1), ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1)
long  ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1), ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1)
long  ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1), ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1)

long  ((0<<22)+(0<<16)+(15<<6)+0), ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0)
long  ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0)
long  ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(11<<6)+0)
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(11<<6)+1), ((0<<22)+(0<<16)+(15<<6)+1), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(0<<16)+(11<<6)+1), ((0<<22)+(0<<16)+(15<<6)+1)

long  ((0<<22)+(0<<16)+(10<<6)+0), ((0<<22)+(0<<16)+(17<<6)+0), ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0)
long  ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0)
long  ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0)
long  ((0<<22)+(0<<16)+(15<<6)+1), ((0<<22)+(1<<16)+(10<<6)+0), ((0<<22)+(0<<16)+(16<<6)+0), ((0<<22)+(1<<16)+(10<<6)+1)
long  ((0<<22)+(1<<16)+(10<<6)+1), ((0<<22)+(0<<16)+(15<<6)+0), ((0<<22)+(0<<16)+(16<<6)+0), ((0<<22)+(1<<16)+(10<<6)+1) 
long  ((0<<22)+(1<<16)+(10<<6)+1), ((0<<22)+(0<<16)+(15<<6)+0), ((0<<22)+(0<<16)+(15<<6)+1), ((0<<22)+(1<<16)+(10<<6)+0)
long  ((0<<22)+(1<<16)+(18<<6)+0), ((0<<22)+(0<<16)+(17<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0) 
long  ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(1<<16)+(10<<6)+0), ((1<<22)+(0<<16)+(6<<6)+0) , ((1<<22)+(0<<16)+(6<<6)+0)

long  ((0<<22)+(0<<16)+(9<<6)+0) , ((0<<22)+(0<<16)+(10<<6)+0), ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0)
long  ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0)
long  ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(1<<16)+(6<<6)+1)
long  ((0<<22)+(0<<16)+(18<<6)+0), ((0<<22)+(1<<16)+(17<<6)+0), ((0<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(11<<6)+0)
long  ((0<<22)+(0<<16)+(15<<6)+0), ((1<<22)+(0<<16)+(6<<6)+0) , ((1<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(11<<6)+0) 
long  ((0<<22)+(0<<16)+(15<<6)+0), ((1<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(18<<6)+0), ((0<<22)+(1<<16)+(17<<6)+0)
long  ((1<<22)+(0<<16)+(8<<6)+0) , ((0<<22)+(1<<16)+(11<<6)+1), ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1) 
long  ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(0<<16)+(10<<6)+0), ((1<<22)+(0<<16)+(6<<6)+0) , ((1<<22)+(0<<16)+(6<<6)+0)

long  ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1), ((0<<22)+(0<<16)+(10<<6)+0), ((0<<22)+(0<<16)+(17<<6)+0)
long  ((0<<22)+(1<<16)+(18<<6)+0), ((0<<22)+(0<<16)+(19<<6)+0), ((0<<22)+(0<<16)+(10<<6)+0), ((0<<22)+(0<<16)+(17<<6)+0)
long  ((0<<22)+(1<<16)+(18<<6)+0), ((0<<22)+(0<<16)+(17<<6)+0), ((0<<22)+(1<<16)+(18<<6)+0), ((0<<22)+(0<<16)+(19<<6)+0)
long  ((0<<22)+(0<<16)+(10<<6)+0), ((0<<22)+(0<<16)+(17<<6)+0), ((0<<22)+(1<<16)+(18<<6)+0), ((0<<22)+(0<<16)+(19<<6)+0)
long  ((0<<22)+(0<<16)+(10<<6)+0), ((0<<22)+(0<<16)+(17<<6)+0), ((1<<22)+(0<<16)+(6<<6)+0) , ((1<<22)+(0<<16)+(6<<6)+0) 
long  ((1<<22)+(0<<16)+(6<<6)+0) , ((1<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(1<<16)+(18<<6)+0), ((0<<22)+(0<<16)+(19<<6)+0)
long  ((0<<22)+(1<<16)+(12<<6)+0), ((0<<22)+(1<<16)+(13<<6)+1), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0) 
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(0<<16)+(10<<6)+0), ((0<<22)+(0<<16)+(17<<6)+0)

long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0), ((0<<22)+(0<<16)+(9<<6)+0) , ((0<<22)+(0<<16)+(10<<6)+0)
long  ((0<<22)+(0<<16)+(19<<6)+0), ((0<<22)+(1<<16)+(10<<6)+1), ((0<<22)+(0<<16)+(9<<6)+0) , ((0<<22)+(0<<16)+(10<<6)+0)
long  ((1<<22)+(0<<16)+(8<<6)+0) , ((0<<22)+(0<<16)+(11<<6)+1), ((0<<22)+(0<<16)+(19<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0)
long  ((0<<22)+(0<<16)+(9<<6)+0) , ((0<<22)+(0<<16)+(10<<6)+0), ((0<<22)+(0<<16)+(19<<6)+0), ((0<<22)+(1<<16)+(10<<6)+1)
long  ((0<<22)+(0<<16)+(9<<6)+0) , ((0<<22)+(0<<16)+(10<<6)+0), ((1<<22)+(0<<16)+(6<<6)+0) , ((1<<22)+(0<<16)+(6<<6)+0) 
long  ((1<<22)+(0<<16)+(6<<6)+0) , ((1<<22)+(0<<16)+(6<<6)+0) , ((0<<22)+(0<<16)+(19<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(15<<6)+0), ((0<<22)+(0<<16)+(11<<6)+0), ((1<<22)+(0<<16)+(8<<6)+1) , ((1<<22)+(1<<16)+(8<<6)+0) 
long  ((1<<22)+(0<<16)+(8<<6)+1) , ((1<<22)+(1<<16)+(8<<6)+0) , ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)

long  ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) 
long  ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0)
long  ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) , ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(1<<16)+(9<<6)+1)
long  ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) , ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(9<<6)+1)
long  ((0<<22)+(0<<16)+(9<<6)+1) , ((0<<22)+(1<<16)+(10<<6)+1), ((0<<22)+(0<<16)+(10<<6)+0), ((0<<22)+(0<<16)+(17<<6)+0)
long  ((0<<22)+(1<<16)+(18<<6)+0), ((0<<22)+(0<<16)+(19<<6)+0), ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0) 
long  ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) 
long  ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0) , ((1<<22)+(0<<16)+(7<<6)+0)

 
long  ((1<<22)+(0<<16)+(20<<6)+0), ((1<<22)+(0<<16)+(21<<6)+0),((1<<22)+(0<<16)+(20<<6)+0), ((1<<22)+(0<<16)+(21<<6)+0)
long  ((1<<22)+(0<<16)+(20<<6)+0), ((1<<22)+(0<<16)+(21<<6)+0),((1<<22)+(0<<16)+(20<<6)+0), ((1<<22)+(0<<16)+(21<<6)+0)
long  ((1<<22)+(0<<16)+(20<<6)+0), ((1<<22)+(0<<16)+(21<<6)+0),((0<<22)+(0<<16)+(11<<6)+1), ((0<<22)+(0<<16)+(15<<6)+1)
long  ((1<<22)+(0<<16)+(20<<6)+0), ((1<<22)+(0<<16)+(21<<6)+0),((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0),((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0)
long  ((0<<22)+(0<<16)+(12<<6)+0), ((0<<22)+(0<<16)+(13<<6)+0),((0<<22)+(0<<16)+(11<<6)+1), ((0<<22)+(0<<16)+(15<<6)+1)
long  ((1<<22)+(0<<16)+(20<<6)+0), ((1<<22)+(0<<16)+(21<<6)+0),((1<<22)+(0<<16)+(20<<6)+0), ((1<<22)+(0<<16)+(21<<6)+0)
long  ((1<<22)+(0<<16)+(20<<6)+0), ((1<<22)+(0<<16)+(21<<6)+0),((1<<22)+(0<<16)+(20<<6)+0), ((1<<22)+(0<<16)+(21<<6)+0)


watermap
long ((2<<22)+(0<<16)+(22<<6)+0),((2<<22)+(0<<16)+(22<<6)+1)
long ((3<<22)+(0<<16)+(22<<6)+0),((3<<22)+(0<<16)+(22<<6)+1)
long ((4<<22)+(0<<16)+(22<<6)+0),((4<<22)+(0<<16)+(22<<6)+1)
long ((1<<22)+(0<<16)+(7<<6)+0)[2]


PUB changefilter(d)
  filter += d
  case filter
    -1:
      changefilter(1+22)
    0: ''No filter
      gfx.Set_Filter(%100000_000,0,0,0,%100000_000,0,0,0)
    1: ''Monochrome
      gfx.Set_Filter(%011000_001,@monofilter1,@monofilter1+4,@monofilter1,%100000_000,0,0,0)
    2: ''Fog 1/desaturate
      gfx.Set_Filter(%011000_001,@fog1,@fog1+4,@fog1,%100000_000,0,0,0)
    3: ''Fog 2
      gfx.Set_Filter(%011000_001,@fog2,@fog2+4,@fog2,%011010_000,0,0,0)
    4: ''Fog 2 (brighter)
      gfx.Set_Filter(%011000_001,@fog2,@fog2+4,@fog2,%011010_001,@fog2_o,@fog2_o+4,@fog2_o)
    5: ''Fog 3 / tint blue
      gfx.Set_Filter(%011000_001,@fog2,@fog2+4,@fog2,%011010_001,@fog3,@fog3+4,@fog3)
    6: ''Fog 4 / tint green
      gfx.Set_Filter(%011000_001,@fog2,@fog2+4,@fog2,%011010_001,@fog4,@fog4+4,@fog4)
    7: ''black lines vertical
      gfx.Set_Filter(%011000_001,@halfmask,@halfmask+4,@halfmask,%011010_001,@vertb,@vertb+4,@vertb)
    8: ''black lines horizontal
      gfx.Set_Filter(%011000_001,@horb_a,@horb_a+8,@horb_a,%011010_001,@horb_o,@horb_o+8,@horb_o)
    9: ''black lines diagonal
      gfx.Set_Filter(%011000_001,@diagb_a,@diagb_a+16,@diagb_a,%011010_001,@diagb_o,@diagb_o+16,@diagb_o)
    10: ''black checkerboard
      gfx.Set_Filter(%011000_001,@halfmask,@halfmask+8,@halfmask,%011010_001,@checkb,@checkb+8,@checkb)
    11: ''reverse chroma
      gfx.Set_Filter(%011011_001,@chromainvert,@chromainvert+4,@chromainvert,%011010_000,0,0,0)
    12: ''rainbow 1
      gfx.Set_Filter(%011000_000,0,0,0,%011011_001,@rainbow,@rainbow+constant(16*4),@rainbow)
    13: ''rainbow 2
      gfx.Set_Filter(%011000_001,@rainbow2,@rainbow2+4,@rainbow2,%011011_001,@rainbow,@rainbow+constant(16*4),@rainbow)
    14: ''rainbow 3
      gfx.Set_Filter(%011000_001,@noir,@noir+4,@noir,%011011_001,@rainbow3,@rainbow3+constant(16*4),@rainbow3)
    15: ''Noir
      gfx.Set_Filter(%011000_001,@noir,@noir+4,@noir,%011000_000,0,0,0)
    16: ''Chroma limit / posterize 1
      gfx.Set_Filter(%011000_001,@chromalimit,@chromalimit+4,@chromalimit,%011000_000,0,0,0)
    17: ''Color limit / posterize 2
      gfx.Set_Filter(%011000_001,@colorlimit,@colorlimit+4,@colorlimit,%011000_000,0,0,0)
    18: ''Two-Tone
      gfx.Set_Filter(%011000_001,@twotone,@twotone+4,@twotone,%011000_000,0,0,0)
    19: ''some other color thingy
      gfx.Set_Filter(%011011_001,@thingy,@thingy+4,@thingy,%011010_000,0,0,0)
    20: ''black snaky pattern thing
      gfx.Set_Filter(%011001_001,@snaky_an,@snaky_an+20,@snaky_an,%011010_001,@snaky_o,@snaky_o+20,@snaky_o)
    21: ''crazy nonsense
      gfx.Set_Filter(%011000_010,@crazy,@crazy+4,@crazy,%011100_001,@chromainvert,@chromainvert+4,@chromainvert)
    22: ''1 bit
      gfx.Set_Filter(%011000_001,@onebit,@onebit+4,@onebit,%011010_001,@horb_o,@horb_o+4,@horb_o)
      
    other:
      changefilter(-filter)

DAT

monofilter1    long $07_07_07_07

fog1           long $07_FF_07_FF

halfmask       long $FF_00_FF_00
               long $00_FF_00_FF

checkb         long $00_02_00_02
               long $02_00_02_00
               
fog2           long $FF_06_FF_06

fog2_o         long $00_01_00_01
               
fog3           long $00_18_00_18

fog4           long $00_58_00_58

vertb          long $00_02_00_02

horb_a         long 0
               long -1
horb_o         long $02_02_02_02
               long 0

diagb_a       long $00_FF_FF_FF
              long $FF_00_FF_FF
              long $FF_FF_00_FF
              long $FF_FF_FF_00
diagb_o       long $02_00_00_00
              long $00_02_00_00
              long $00_00_02_00
              long $00_00_00_02

chromainvert  long $80_80_80_80

noir          long $06*$01010101
rainbow2      long $0F*$01010101
chromalimit   long $CF*$01010101
colorlimit    long $CE*$01010101
twotone       long $8F*$01010101

rainbow       long $10101010*$0
              long $10101010*$1
              long $10101010*$2
              long $10101010*$3
              long $10101010*$4
              long $10101010*$5
              long $10101010*$6
              long $10101010*$7
              long $10101010*$8
              long $10101010*$9
              long $10101010*$A
              long $10101010*$B
              long $10101010*$C
              long $10101010*$D
              long $10101010*$E
              long $10101010*$F

rainbow3      long $10101010*$0 + $08_08_08_08
              long $10101010*$1 + $08_08_08_08
              long $10101010*$2 + $08_08_08_08
              long $10101010*$3 + $08_08_08_08
              long $10101010*$4 + $08_08_08_08
              long $10101010*$5 + $08_08_08_08
              long $10101010*$6 + $08_08_08_08
              long $10101010*$7 + $08_08_08_08
              long $10101010*$8 + $08_08_08_08
              long $10101010*$9 + $08_08_08_08
              long $10101010*$A + $08_08_08_08
              long $10101010*$B + $08_08_08_08
              long $10101010*$C + $08_08_08_08
              long $10101010*$D + $08_08_08_08
              long $10101010*$E + $08_08_08_08
              long $10101010*$F + $08_08_08_08

snaky_an      long $FF*$01010101
              long $FF*$00000001
              long $FF*$00010001
              long $FF*$00010101
              long $FF*$00000000
snaky_o       long $02*$01010101
              long $02*$00000001
              long $02*$00010001
              long $02*$00010101
              long $02*$00000000

thingy        long $F0F0F0F0
crazy         long $08080808
onebit        long $04040404

PUB changeborder(d)
  border += d
  case border
    -1:
      changeborder(1+4)
    0:
      gfx.Set_Border_Color($02)
      gfx.Set_Scrollborder($07_05_03_02,@testbdr,@testbdr+64,@testbdr)
    1:
      gfx.Set_Border_Color($02)
      gfx.Set_Scrollborder($07_05_03_02,@testbdr+32,@testbdr+64,@testbdr)
    2:
      gfx.Set_Border_Color($04)
      gfx.Set_Scrollborder($07_AE_AD_02,@testbdr,@testbdr+64,@testbdr)
    3:
      gfx.Set_Border_Color($5E)
      gfx.Set_Scrollborder($07_05_03_02,$9F80,$9F80+128,$9F80)
    4:   
      gfx.Set_Border_Color($04)
      gfx.Set_Scrollborder($07_05_03_02,memv,0,0)
    other:
      changeborder(-border)
      
DAT

testbdr       ''stolen from Unterwelt
              LONG %%0_0_1_1_1_1_1_1_1_1_1_1_1_0_0_0
              LONG %%0_1_2_2_2_2_2_2_2_2_2_2_2_3_0_0
              LONG %%1_1_1_2_2_2_2_2_2_2_2_2_3_3_3_0
              LONG %%0_1_1_1_2_2_2_2_2_2_2_3_3_3_2_1
              LONG %%0_0_1_1_1_1_1_1_1_1_1_3_3_2_2_1
              LONG %%0_0_0_1_1_1_1_1_1_1_1_1_2_2_2_1
              LONG %%0_0_0_1_1_1_1_1_1_1_1_1_2_2_2_1
              LONG %%0_0_0_1_1_1_1_1_1_1_1_1_2_2_2_1
              LONG %%0_0_0_1_1_1_1_1_1_1_1_1_2_2_2_1
              LONG %%0_0_0_1_1_1_1_1_1_1_1_1_2_2_2_1
              LONG %%0_0_0_1_1_1_1_1_1_1_1_1_2_2_2_1
              LONG %%0_0_0_1_1_1_1_1_1_1_1_1_2_2_2_1
              LONG %%0_0_0_0_1_1_1_1_1_1_1_1_1_2_2_1
              LONG %%0_0_0_0_0_0_0_0_0_0_0_1_1_1_2_1
              LONG %%0_0_0_0_0_0_0_0_0_0_0_0_1_1_1_0
              LONG %%0_0_0_0_0_0_0_0_0_0_0_0_0_1_0_0


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