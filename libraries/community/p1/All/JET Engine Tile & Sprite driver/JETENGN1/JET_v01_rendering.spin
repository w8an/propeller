'' JET ENGINE v1
'' (C)2018 IRQ Interactive
'' Rendering Cog code
'' very loosley based on JT Cook's Ranquest driver
''
'' Specs:
'' Tilemap of 16x12 tiles
'' 32 Sprites per screen, 8 per line, lots of settings
CON
  SCANLINE_BUFFER = $7800
  NUM_LINES = 224
  SPR_BUCKETS = SCANLINE_BUFFER - (NUM_LINES*8)
  ROM_FONT        = $8000
  Last_Scanline = NUM_LINES-1 ''final scanline for a frame
  num_sprites = 32


  Sfield = 0
  DField = 9

{{
OAM looks like this:

oam1
oam1_enable    long %0
oam1_flip      long %0
oam1_mirror    long %0
oam1_yexpand   long %0
oam1_xexpand   long %0
oam1_solid     long %0
oam1_ypos      word 0[num_sprites]
oam1_xpos      word 0[num_sprites]
oam1_pattern   byte 1[num_sprites]
oam1_palette   byte 0[num_sprites]
oam1_end
}}
oam_enable     = 0
oam_flip       = 4
oam_mirror     = 8
oam_yexpand    = 12
oam_xexpand    = 16
oam_solid      = 20
oam_ypos       = 24
oam_xpos       = 24+(num_sprites*2)
oam_pattern    = 24+(num_sprites*4)
oam_palette    = 24+(num_sprites*5)

PUB start(cognum,buckets,readyptr)
'' Start Rendering Engine
  long[@cognumber] := cognum
  long[@sprite_buckets_ptr] := buckets
  cognew(@Entry, readyptr)
  repeat 10000 'wait for cog to boot...

PUB Return_Address ''used to get address where assembly code is so we can re-purpose space
    return(@Entry)

DAT
        org
Entry      ''Note: Init code gets reuses as variables, thus the labels
a0      mov a0, Par  ''read parameter
d0      rdbyte tile, a0 wz''is ready?
d1 if_z jmp #d0 'if not, repeat
        
        
'        rdlong Tiles_Adr, tile_adr ''read address of where tiles are at

''Main loop for renderer
new_frame
''wait until we hit scanline 0 so we can start with a fresh frame
'mov kak,#0
        mov currentscanline, cognumber ''reset current scanline for COG
        'rdword map_base, tilemap_ptr_adr ''read address of tile map
        'rdword tile_base, tile_ptr_adr ''read address of where tile graphics are stored
        rdword oam_base, oam_ptr_adr  '' read adress of OAM
        wrword oam_base, oam_in_use
        rdword text_color_base, text_color_ptr_adr

:reset_subscreen       
        rdword s_next,first_subscreen ' read pointer to first subscreen
        neg s_mode,#1 'init s_mode to invalid mode so if there is no subscreen, the screen gets filled with border
        rdword next_ystart,s_next ' y start of first subscreen
        'wrlong s_next,debug_shizzle

        mov a0,oam_base 'Load misc sprite-related stuff
        movd :ofl,#oam_flags
        mov d0,#oam_flags_end-oam_flags
:ofl    rdlong 0,a0
        add a0,#4 'advance pointer
        add :ofl,Dfield_1
        djnz d0,#:ofl
        
prepare_sprites
        mov a0,sprite_buckets_ptr 'clear sprite buckets
        mov d0,#NUM_LINES/2 '112 longs = 56 buckets
:clearloop
        wrlong zero,a0
        add a0,#4
        djnz d0,#:clearloop

 ''put sprites into buckets. Sprite 0 has the highest priority NOTE: sprite_enable gets clobbered
        'rdlong sprite_enable,oam_base ''oam_enable is first long in OAM
        neg d0,#1 ''Iterate d0 through spriteIDs, starting at 0
:nextsprite
        add d0,#1
        shr sprite_enable,#1 wz,wc
if_z_and_nc jmp #:sprites_done 'This sprite and all further ones are disabled, we can go home :P
if_nc   jmp #:nextsprite

        mov a0,d0 'Index into oam_ypos
        shl a0,#1 
        add a0,oam_base
        add a0,#oam_ypos
        rdword sprite_y,a0
        shl sprite_y,#16 'Sign-extend!
        sar sprite_y,#16
        cmps sprite_y,#last_scanline wc,wz 'Below last line?... 
if_a    jmp #:nextsprite '...Next please!
        cmps sprite_y,minus_32 wc,wz 'above the screen?
if_be   jmp #:nextsprite
        sub sprite_y,cognumber 'This cog handles all lines where (currentscanline % 4) == cognumber        
        add sprite_y,#3'+32 'Round up Y position toward multiple of 4 and add 32 lines of offset into the bucket list...
                           '...(first 8 buckets are unused)      
        andn sprite_y,#3   'continue rounding
        shl sprite_y,#1 'Divide by 4 and multiply by 8 to get bucket offset

        mov pixel_iter,#4 'Sprite is 16 lines tall, this cog handles 4 of them
        mov d1,#1
        shl d1,d0
        and sprite_yexpand,d1 nr,wz 'Y-expanded?
if_nz   shl pixel_iter,#1 'If yes, double height!
:insloop
        call #try_insert_sprite 'try inserting into a bucket
        add sprite_y,#2<<2 'add 4 lines (remember, sprite_y is shifted left)
        djnz pixel_iter,#:insloop

        jmp #:nextsprite
:sprites_done
        

  
:waitloop
        rdword currentrequest, request_scanline wz
if_nz   jmp #:waitloop

setup_line
        mov display_base,scanlines ' Calculate start of hub buffer for this scanline
        mov d0,currentscanline
        and d0,#7
        mov line_n_7,d0 'preserve (scanline&7) for later
        shl d0,#8
        add display_base,d0

:check_new_subscreen    'Check if a new subscreen needs to be loaded
        mov a0,s_next wz 'Is s_next a null pointer? (also copy s_next into a0)
        cmp currentscanline,next_ystart wc 'Have we reached the next subscreen yet?
if_z_or_c jmp #:no_subscreen 'If either of those is true, don't load a new subscreen
        movd :sub_rd_loop_d,#rd_subscreen
        mov s_ystart,next_ystart 'ystart of new subscreen is already in next_ystart
        mov tile_iter,#rd_subscreen_end-rd_subscreen 'get read length into d0
:sub_rd_loop
        add a0,#2    'advance pointer. this happens before rdword becasue we want to skip the first word.
        rdword d0,a0       
        shl d0,#16 'sign extend: important for numbers, ignore-able for pointers
        sar d0,#16
:sub_rd_loop_d
        mov 0,d0
        add :sub_rd_loop_d,Dfield_1
        djnz tile_iter,#:sub_rd_loop
        and s_mode,#1 nr,wz 'Is smooth scrolling mode?
if_nz   add xscroll,#8 'Account for scroll border
        rdword next_ystart, s_next 'read ystart of next subscreen
        jmp #:check_new_subscreen 'check if yet another one needs to be loaded. This should be avoided though

        

:no_subscreen
        mov d0,currentscanline
        add d0,yscroll
        
        mov tile_line, d0 'Which line of a tile is this line (0-15 when tile_height == 4)
        ror tile_line,tile_height
        neg d1,tile_height
        shr tile_line,d1

        mov map_ptr,d0 ' calculate start of tilemap line
        shr map_ptr,tile_height     ' shift out low 4 bits (divide by 16 = tile height) NOTE: tile_height is now a variable
        shl map_ptr,map_y_shift     ' and multiply with map width
        and map_ptr,map_mask
        add map_ptr,map_base

        mov map_ptr_end,map_ptr 'calculate end of tilemap line (this is the address of the first invalid tile)
        add map_ptr_end,map_width
        
        mov d0,map_width wz     'add x scrolling to map pointer
        sub d0,#1               'turn into mask (if map_width was zero, -1)
        mov d1,xscroll          
        shr d1,#2               'divide xscroll by 4 (remember, 1 byte of map is 4 gfx pixels wide)
        and d0,d1               'd0 is now offset into map line
        add map_ptr,d0          

:nowrap
        mov tile_ptr,tile_line
        shl tile_ptr,#2
        add tile_ptr,tile_base
        mov d0,tile_ptr 'copy low word into high word, for faster tile loop
        shl d0, #16     '^^
        or tile_ptr,d0  '^^

        mov curattrib_ptr,buffer_attribs_ptr ' Get address of this line's buffer attribute byte into a0
        add curattrib_ptr,line_n_7

        mov pixel_ptr,display_base


        cmp s_mode,#2*(linemode_table_end-linemode_table) wz,wc 'Is mode invalid? (or -1, the "official" number for the fallback mode)
        movs :lm_jmp,#linemode_table
        mov d0,s_mode
        shr d0,#1       'divide by two (lowest mode bit is scroll flag)
        add :lm_jmp,d0
if_ae   jmp #blank_line '... if invalid, fallback (done here due to pipelining)
:lm_jmp jmp 0

linemode_table
        long start_text_line_aa8
        long start_text_line_aa16
        long start_text_line_16
        long start_text_line_32
        long start_gfx_line 
linemode_table_end

        
blank_line ''Fallback mode that fills everything with border color
        wrbyte zero,curattrib_ptr 'use same buffer attrib as 256px gfx mode
        rdbyte d0,border_color
        mov pixel_iter,#256
:loop   wrbyte d0,pixel_ptr
        add pixel_ptr,#1
        djnz pixel_iter,#:loop
        jmp #scanline_finished

start_text_line_16 ''16-line text (1:1 bit mapping)
        mov taa0,tile_line
        shl taa0,#3
        mov taa1,#4
        jmp #start_text_line

start_text_line_32 ''32-line text (2:1 bit mapping)
        mov taa0,tile_line
        shl taa0,#2
        mov taa1,#0
        jmp #start_text_line

start_text_line_aa16 ''Antialiased 16-line text
        ''Note: there was some confusion between which sample is which (top/bottom). I hope everything is coherent now...
        mov a0,tile_line 'get aatable entries into taa0 (bottom?) and taa1(top?)
        shl a0,#1
        add a0,aatable
        jmp #start_text_line_aa

start_text_line_aa8 ''Antialiased 8-line text
        ''Note: there was some confusion between which sample is which (top/bottom). I hope everything is coherent now...
        mov a0,tile_line 'get aatable entries into taa0 (bottom?) and taa1(top?)
        shl a0,#1
        add a0,aatable8
        'drop through
        

start_text_line_aa      'preprocess antialiasing
        rdbyte taa0,a0
        {mov taa1,taa0
        and taa0,#$ff
        shr taa1,#8}
        add a0,#1
        rdbyte taa1,a0
        sub taa1,taa0 'substract taa0 from taa1 (so taa1 is distance of the top sample to the bottom sample)

start_text_line
        andn map_ptr,#1 'word-align map_ptr
        
        mov xscroll_tile,xscroll
        and xscroll_tile,#%0111
        mov d0,#$80
        and s_mode,#1 wz,nr 'Is this a smooth scrolling mode?
if_nz   or d0,xscroll_tile
if_nz   or d0,#$40
        wrbyte d0,curattrib_ptr

        

        mov tile_iter,#32
textchar
        rdword tile,map_ptr
        add map_ptr,#2
        cmp map_ptr,map_ptr_end wz,wc 'Wrap around?
if_e    sub map_ptr,map_width
        and tile,#2 nr,wz 'Is ROM char or delta tile?
if_nz   jmp #delta_to_text 'tile!
notile  mov a0,text_addr_bits
        and a0, tile 'isolate char address
        add a0, taa0 'index into char
        rdlong pattern,a0 ' read bottom sample
        add a0,taa1 'advance pointer
        rdlong pattern2, a0 ' read top sample
        
        mov a0, tile 'prepare reading palette
        and a0, text_color_bits '^^
        add a0,text_color_base  '^^
                                                          
        and tile,#1 nr,wz 'Get odd flag into nz
if_nz   shr pattern,#1 'if odd char, shift its bits into even bits of pattern
if_z    shl pattern2,#1      'if even char, shift its bits into odd bits of d0
        rdlong palette,a0 'Read palette

        and pattern,evenbits 'combine bits so that even bits come from bottom sample and odd bits from top sample
        andn pattern2,evenbits      '...and Antialiasing magic ensues
        wrlong palette,pixel_ptr 'Write palette                                               
        or  pattern,pattern2 'continue combining
        add pixel_ptr,#4 'adcance pointer
        wrlong pattern,pixel_ptr
        add pixel_ptr,#4 'adcance pointer

nextchar
        djnz tile_iter,#textchar 'iterate further
        
 
        jmp #scanline_finished 'No sprites on text lines!


delta_to_text ''Convert delta tile into two "regular" ones (for correct aspect ratio, also we need 32 bits to store the data)
              '' regular tiles for text mode display.
        cmps tile_iter,#1 wc,wz 'tiles not allowed on screen edge! (would complicate code a lot and has not that much use)
if_be   jmp #notile 'show corrupted mess instead :P
        mov pixel_iter,#8
        mov dtile_first_half,#2
        and tile,map_used_bits
        rdword pattern2,map_ptr 'load upper half of tile info (palette index and flip flag)
        add map_ptr,#2 'advance pointer
        cmp map_ptr,map_ptr_end wz,wc 'Wrap around?
if_e    sub map_ptr,map_width
        and pattern2,#1 wc,nr 'get flip flag into c
        and tile,#1     wz,nr 'get mirror flag into nz (mirroring is inverted in text mode,thus the strange code that follows)
        negnz dtile_shift,#4 'set this depending on mirror flag
        add tile,tile_ptr 'get pointer to pattern
if_c    xor tile, flip_mask 'apply flip
        rdlong pattern,tile 'read pattern
        add pattern2,tile_ptr 'get pointer to palette
if_c    xor pattern2, flip_mask 'apply flip
        rdlong palette, pattern2 'read palette 

if_z    add pixel_ptr,#8 'not mirrored: write second half first
        mov dtile_tmp1, dtile_pseudopal           
        mov pattern2,#0 ''pattern2 is now repurposed!
       
                                                                                                              
:tilepixel     ''get a pixel from pattern into two pixels (4 bits) of pattern2 (while also decoding them, ofc)
               ''this is somewhat inefficient, but whatever, text lines don't have sprites to slow them down
        rol pattern2,dtile_shift
        shl pattern,#1 wc
if_c    ror dtile_tmp1,#8
        shl pattern,#1 wc
if_c    ror dtile_tmp1,#4
        mov dtile_tmp2,#%%33
        and dtile_tmp2,dtile_tmp1 'isolate pixel (4 bits)
        or pattern2,dtile_tmp2 'add to pattern2   
        djnz pixel_iter,#:tilepixel
        
if_nz   rol pattern2,dtile_shift 'nz is still mirror flag! If mirrored, rotate once more
       
        wrlong palette,pixel_ptr 'write palette
        add pixel_ptr,#4
        mov pixel_iter,#8 'set back to sensible value
        wrlong pattern2,pixel_ptr 'write pattern
        add pixel_ptr,#4
        mov pattern2,#0
if_z    sub pixel_ptr,#16
        djnz dtile_first_half,#:tilepixel
        sub tile_iter,#1
if_z    add pixel_ptr,#24
        djnz tile_iter,#textchar
        jmp #scanline_finished


start_gfx_line 
        and s_mode,#1 wz,nr 'Is this a smooth scrolling mode?
if_nz   jmp #:start_gfx_line_240
        mov spritexoff,#0
        wrbyte zero,curattrib_ptr
        jmp #:start
:start_gfx_line_240
        mov xscroll_tile,xscroll
        and xscroll_tile,#%1111'$f
        mov spritexoff,xscroll_tile
        sub spritexoff,#8
        mov d0,xscroll_tile
        or  d0,#$40
        wrbyte d0,curattrib_ptr
        'drop through

:start                   
        andn map_ptr,#3 'long-align map_ptr
draw_tiles
        mov tile_iter, #16
        mov pixel_ptr_stride,#1
        {and currentscanline,#4 nr,wc
        mov test_pal,test_pal_2
if_c    rol test_pal,#8}

:nexttile
        'mov pattern,test_pat
        'mov palette, test_pal
        'andn currentscanline,#0 nr,wc
        'ror test_pal,#8
        
        rdlong tile,map_ptr
        add map_ptr,#4
        cmp map_ptr,map_ptr_end wz,wc 'Wrap around?
if_e    sub map_ptr,map_width
        and tile,flip_flag nr,wz 'get (vertical) flip flag (bit 16) into nz
        and tile,map_used_bits ' mask out bits we don't want 
        add tile,tile_ptr   'Add tileset pointer to masked tilemap data - becomes two(!) valid hub addresses        
if_nz   xor tile,flip_mask  ' This is why the tileset needs to be aligned...
        cmp pixel_ptr_stride,#1 wz' get previous mirror flag into nz        
        rdlong pattern,tile 'Upper half of tile gets thrown away
        ror tile,#16 wc 'get (horizontal) mirror flag (bit 0) into c and flip word order  
        negc pixel_ptr_stride,#1
        rdlong palette,tile
if_nz   add pixel_ptr,#17 'If previous tile was mirrored: correct pointer       
if_c    add pixel_ptr,#15 'If next tile is mirrored: advance pointer to end of tile

                                              
        mov pixel_iter, #16

:tilepixel
        shl pattern,#1 wc
if_c    ror palette,#16
        shl pattern,#1 wc
if_c    ror palette,#8
        wrbyte palette,pixel_ptr  
        add pixel_ptr,pixel_ptr_stride
        djnz pixel_iter,#:tilepixel
        
:rename_me
        'mov 0,test_pal

        'add :write_group,Dfield_1
        djnz tile_iter,#:nexttile

draw_sprites
        'jmp #scanline_finished ''DELETE ME!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        mov bucket_ptr,currentscanline 'Calculate bucket pointer for current line
        shl bucket_ptr,#1
        andn bucket_ptr,#7
        add bucket_ptr,sprite_buckets_ptr
        add bucket_ptr,#1<<2 'use second half first
        
        movs nexthalf+1,#:dohalf ' set up jump
        
:dohalf ' Actually the second half, but due to using painter's algorithm,
           ' lower priority sprites need to be drawn first
        rdlong bucket,bucket_ptr wz 'load from bucket_ptr!
        sub bucket_ptr,#1<<2                        
if_z    jmp #nexthalf 'This half-bucket is empty!

bloop
        and bucket,byte4 nr,wz
if_z    jmp #nextspd 'Empty! Try next slot..
        mov d0,bucket 'Slot filled!
        and d0,byte4
        
        shr d0,#24-1 'Shift sprite ID into position for indexing...
        sub d0,#2 'Remove +1 (currently left-shifted by 1, so +2) that was added during insertion
        mov sprite_id,d0 '... and shifting
        shr sprite_id,#1 
        mov sprite_id_mask,#1
        shl sprite_id_mask,sprite_id
        
        mov pixel_iter,#16 'Init pixel_iter depending on X-expansion
        and sprite_xexpand,sprite_id_mask wz,nr
if_nz   shl pixel_iter,#1

        mov a0,oam_base
        add a0,#oam_xpos
        add a0,d0 'index into array...
        rdword sprite_x,a0
        shl sprite_x,#16 'sign-extend
        sar sprite_x,#16
        add sprite_x,spritexoff 'sprites are independent of scrolling
        mov pixel_ptr,sprite_x 'sprite_x is the pixel_ptr! (scanline buffer pointer gets added later)
        mov sprite_tiley,currentscanline ' will be used later
        sub a0,#oam_xpos-oam_ypos
        'wrlong a0,debug_shizzle
        rdword sprite_y,a0
        shl sprite_y,#16 'sign-extend
        sar sprite_y,#16

        sub a0,sprite_id 'the rest of the OAM data is byte-wide
        sub sprite_tiley,sprite_y ' calculate y pos in tile as (currentscanline-sprite_y)
        and sprite_yexpand,sprite_id_mask wz,nr 'If Y-expanded...
if_nz   shr sprite_tiley,#1 '... divide by 2...
        shl sprite_tiley,#2  'shift left (tile lines are LONGs!)
        and sprite_tiley,#15<<2 'and with 15 to avoid sending bullshiz data to the TV
         'f
         'f  
        add a0,#oam_pattern-oam_ypos
        mov tile_ptr,tile_base 'init tile_ptr
        add tile_ptr,sprite_tiley
        rdbyte pattern,a0 'load pattern tile INDEX!
        shl pattern,#6 'shift index into place
        add a0,#oam_palette-oam_pattern
        rdbyte palette,a0 'load palette tile INDEX!
        shl palette,#6 'shift index into place
        add pattern, tile_ptr 'Add pointer...
        add palette, tile_ptr
        and sprite_flip,sprite_id_mask wz,nr 'If flipped...
if_nz   xor pattern, flip_mask '... do the flipping
if_nz   xor palette, flip_mask
        rdlong palette,palette 'load the actual palette
        'mov palette,test_pal
        'mov pattern,test_pat
        mov palette_orig,palette 'backup palette for transparency masking...
        cmps sprite_x,#0 wc,wz 'Is sprite at left edge?.....
        rdlong pattern,pattern 'load the actual pattern
if_b    jmp #left_edge '... if yes, adjust (needs palette and pattern)
        cmps sprite_x,#256-32 wc,wz 'Is sprite at/near right edge?.....
if_a    jmp #right_edge '....if yes, adjust
noedge  add pixel_ptr,display_base 'Needs to happen after edge cases!
        and sprite_mirror,sprite_id_mask wz,nr 'If mirrored...
if_nz   add pixel_ptr,pixel_iter 'Adjust pixel_ptr...
if_nz   sub pixel_ptr,#1
        negnz pixel_ptr_stride,#1 '... and its stride

        and sprite_xexpand,sprite_id_mask wz,nr 'X-expanded?
if_z    jmp #draw_a_sprite 'No
        jmp #draw_a_fat_sprite 'Yes
        
        
         
        


nextspd shl bucket,#8 wz
if_z    jmp #nexthalf 'This half is done!
        jmp #bloop
 
        


nexthalf
        movs nexthalf+1,#scanline_finished 'modify the following jump. Doesn't take effect immediatly!
        jmp #0

right_edge
        mov d1,#256
        sub d1,sprite_x 'd1 is now distance from edge
        maxs pixel_iter,d1 'pixel_iter is now limited by d1t (Note: min/max are swapped (compared to the C(++) functions)).
                           'Took some good headache to figure that one out
        cmps pixel_iter,#0 wc,wz
if_be   jmp #nextspd ' pixel_iter <= 0 : sprite is off the screen, skip.
        and sprite_mirror,sprite_id_mask wz,nr 'If not mirrored, return
if_z    mov fatsprite_start_odd,#0
if_z    jmp #noedge
        jmp #preshift_palette

left_edge 
        add pixel_iter,sprite_x 'pixel_iter is now either 0-31 or negative
        cmps pixel_iter,#0 wc,wz
if_be   jmp #nextspd ' pixel_iter <= 0 : sprite is off the screen, skip.
        mov pixel_ptr,#0
        and sprite_mirror,sprite_id_mask wz,nr 'If mirrored, return
if_nz   mov fatsprite_start_odd,#0
if_nz   jmp #noedge
        jmp #preshift_palette

preshift_palette ''decodes (pixel_iter) pixels and rotates the palette without actually writing to the buffer...
        mov fatsprite_start_odd,#1
        mov d1,pixel_iter
        and sprite_xexpand,sprite_id_mask wz,nr 'X-expanded?
if_nz   shr d1,#1 ' if yes, divide number by 2
                  'case of partial obstruction of a pixel by an edge is handled elsewhere
                  
        cmp d1,#15 wc,wz 'fix edge case: unexpanded mirrored sprite on right edge
if_a    jmp #noedge

        xor d1,#15 'invert, i.e 0->15 and 15->0
        add d1,#1  'off-by-one
:ploop  shl pattern,#1 wc
if_c    ror palette,#16
        shl pattern,#1 wc
if_c    ror palette,#8
        djnz d1, #:ploop
preshift_palette_end
        jmp #noedge
        
draw_a_sprite
        and sprite_solid,sprite_id_mask wz,nr 'Solid?
        muxnz :sprput,ifnz_bits 'Set wrbyte's condition to if_nz or if_always
:loop
        shl pattern,#1 wc
if_c    ror palette,#16
        shl pattern,#1 wc
if_c    ror palette,#8
        cmp palette,palette_orig wz 'When palette is the same as in hub (i.e. color 0), don't write pixel!
                                    'This can cause issues when the palette can be rotated in a way that
:sprput                             'ends up identical to the unrotated palette!
if_nz   wrbyte palette,pixel_ptr  
        add pixel_ptr,pixel_ptr_stride
        djnz pixel_iter,#:loop
draw_a_sprite_ret
        jmp #nextspd

draw_a_fat_sprite
        and sprite_solid,sprite_id_mask wz,nr 'Solid?
        muxnz :sprput,ifnz_bits 'Set wrbyte's condition to if_nz or if_always
        muxnz :continue,ifnz_bits 'Same for second pixel
        and pixel_iter,#1 nr,wz 'Is pixel_iter odd/even?
if_nz   mov fatsprite_start_odd,fatsprite_start_odd wz 'odd: is this set?
if_z    jmp #:loop 'even: jump into loop
        cmp palette,palette_orig wz ' odd and flag set: start at odd pixel
        jmp #:continue

:loop
        shl pattern,#1 wc
if_c    ror palette,#16
        shl pattern,#1 wc
if_c    ror palette,#8
        cmp palette,palette_orig wz 'When palette is the same as in hub (i.e. color 0), don't write pixel!
                                    'This can cause issues when the palette can be rotated in a way that
:sprput                             'ends up identical to the unrotated palette!
if_nz   wrbyte palette,pixel_ptr
        add pixel_ptr,pixel_ptr_stride
        djnz pixel_iter,#:continue
        jmp draw_a_fat_sprite_ret
:continue
if_nz wrbyte palette,pixel_ptr
        add pixel_ptr,pixel_ptr_stride
        djnz pixel_iter,#:loop
draw_a_fat_sprite_ret
        jmp #nextspd      



{        mov pixel_iter, #330
:hegg   rdbyte d0,#0
        rdbyte d0,#0
        djnz pixel_iter,#:hegg}
         

        
        

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''scanline rendering is finished, wait for request from TV driver
scanline_finished
        ''Uncomment this to test headroom!
        {mov d0,cnt
        add d0,junk
        waitcnt d0,#0}
        
        
                 
'' wait until TV requests the scanline we rendered
:wait
        rdword currentrequest, request_scanline
        cmps currentrequest, currentscanline wz, wc
if_b    jmp #:wait

'' copy scanline
start_tv_copy
        'movs :nextcopy, #scanbuffer
        'mov a0, display_base
       ' mov Buffer_Number, #64

:nextcopy
        'mov d0,scanbuffer
        'add :nextcopy, #1
        'wrlong d0, a0
        'add a0, #4
        'djnz Buffer_Number, #:nextcopy                      
scanlinedone
        ' Line is done, increment to the next one this cog will handle                        
        add currentscanline, #4 'add number of cogs = 4
        cmp currentscanline, #Last_Scanline wc, wz
if_be   jmp #setup_line
        ' The screen is completed, jump back to main loop a wait for next frame                        
        jmp #new_frame

''===========
''SPRITE INSERTION SUBROUTINE (why is there a banner for this?)
''===========
try_insert_sprite  ''Try to insert the spriteID in d0 into bucket no. (sprite_y<<1)
                   '' sprite_y needs to be shifted 1 bit left already!
        cmp sprite_y,#NUM_LINES*2 wc,wz 'reject if too large or negative (cmp is unsigned!)
if_ae   jmp try_insert_sprite_ret
        mov ins_spr,d0
        add ins_spr,#1 ''+1 the ID, as a null byte is used for empty slots
        mov bucket_ptr,sprite_y
        add bucket_ptr,sprite_buckets_ptr
        call #insert_long 'Try first half of bucket
        shr ins_spr,#24
        add bucket_ptr,#4
        call #insert_long 'Try second half of bucket
        'This line is only reached when sprites overflow... 

try_insert_sprite_ret
        ret

insert_long
        mov bucket_mask,#$FF 
:get    rdlong bucket,bucket_ptr

ins_loop   and bucket,bucket_mask nr,wz 'slot free?
if_z    jmp #do_insert ' If yes: insert 
        shl bucket_mask, #8 wz 'Not free? Advance to next slot...
insert_long_ret
if_z    ret                 ' ... or return to caller if last slot in long
        shl ins_spr, #8
        jmp #ins_loop

do_insert
        'movd :put,bucket_ptr                                                         
:put    or bucket,ins_spr
        wrlong bucket,bucket_ptr
        jmp try_insert_sprite_ret 'Jump back into main code...
                    'Not jmp #try_insert_sprite_ret, i.e. doesn't jump to :return,
                    'instead jumps to :return's S-field, saves some cycles        

        
        
           


''===========
''DATA STUFF
''===========

sprite_buckets_ptr      long SPR_BUCKETS        ''This gets initialized to the actual value before the cog is loaded!
cognumber               long -1                 ''which COG this rendering COG is

scanlines            long SCANLINE_BUFFER    ''scanline address
request_scanline        long SPR_BUCKETS-2      ''next scanline to render
'tilemap_ptr_adr            long SPR_BUCKETS-4      ''address of tile map
'tile_ptr_adr               long SPR_BUCKETS-6 ''address of tiles (must be 64-byte-aligned)
border_color           long SPR_BUCKETS-8 ''border color
oam_ptr_adr             long    SPR_BUCKETS-10      ''address of where sprite attribs are stored
oam_in_use              long SPR_BUCKETS-12
'debug_shizzle          long SPR_BUCKETS-16
text_color_ptr_adr      long SPR_BUCKETS-18
first_subscreen        long SPR_BUCKETS-20
buffer_attribs_ptr      long SPR_BUCKETS-28 'array of 8 bytes
aatable                long SPR_BUCKETS-60 'array of 32 bytes
aatable8               long SPR_BUCKETS-76 'array of 16 bytes

Dfield_1  long 1<<Dfield

''Tile map format:   ignore palette-tile ignore flip-flag ignore pattern-tile  ignore   mirror-flag
map_used_bits  long %000____1111111______0000_0__1_________000____1111111______0000_0___1
flip_mask      long %000____0000000______1111_0__0_________000____0000000______1111_0___0
flip_flag      long %000____0000000______0000_0__1_________000____0000000______0000_0___0

''Tile map format: (actually a word)
''                   Delta tile:
''                     bit 1: one, rest like regular tile map...
''                   Regular character:
''                    address   ? color zero     odd/even
text_addr_bits  long %111111111_0_0000__0________0
text_color_bits long %000000000_0_1111__0________0
                                             

dtile_pseudopal long %%3322110033221100
'test_pal              long $07_05_03_02
'test_pal_2              long $07_05_03_02
'test_pal_3              long $07_05_03_68
'test_pat               long %%0000111122223333
'test_pat              long %%0000100010001000
'test_pat2              long %%0000111122223333

ifnz_bits long %1010<<18 ''bits that make the difference between if_always and if_nz, for use with muxing
byte4   long $FF << 24
'clkreset long 1<<7
minus_32 long -32
evenbits  long $55555555 
'junk long 5200 'used for testing how much headroom there is...

'one long 1
'h80 long $80
zero long 0

next_ystart   res 1 'start of next subscreen
'' these are loaded from subscreen structures
s_ystart      res 1 ' start of current subscreen
rd_subscreen
s_next        res 1 ' pointer to next subscreen
yscroll       res 1 ' y scroll
xscroll       res 1 ' x scroll
s_mode        res 1 ' subscreen mode
tile_base     res 1
map_base      res 1
map_mask      res 1 ' map adress mask
map_width     res 1 ' xscroll mask (should ma
map_y_shift   res 1 ' map_y_shift (y-shift)
tile_height   res 1 ' well, technically log2(tile_height)  
rd_subscreen_end


xscroll_tile res 1 ''xscroll AND $f (not always valid)
taa0 res 1
taa1 'alias
spritexoff   res 1 ''x offset for sprites (to keep sprite coords uniform)
pixel_iter res 1
tile_iter res 1

bucket res 1

curattrib_ptr 'alias
pattern res 1
line_n_7 'alias
pattern2 res 1
palette res 1
dtile_tmp1 'alias
palette_orig res 1
pixel_ptr   res 1
pixel_ptr_stride res 1                   

oam_base res 1
text_color_base res 1
ins_spr 'alias
tile_ptr res 1
bucket_ptr 'alias
map_ptr res 1
map_ptr_end res 1

'these get loaded straight from OAM
oam_flags
sprite_enable res 1
sprite_flip res 1
sprite_mirror res 1
sprite_yexpand res 1
sprite_xexpand res 1
sprite_solid res 1
oam_flags_end

sprite_id_mask res 1
bucket_mask  'alias
sprite_id res 1
tile 'alias
sprite_y res 1
dtile_tmp2 'alias
sprite_x res 1
dtile_shift 'alias
sprite_tiley res 1

dtile_first_half 'alias
fatsprite_start_odd res 1

'sprite_buckets res (48)*2 ''each cog handles 48 lines
                        ''and there can be 8 sprites per line...
'sprite_buckets_end
 
'cogtotal res            1  ''total number of rendering COGs
currentscanline res      1 ''current scanline that TV driver is rendering
tile_line     res        1
currentrequest res       1 ''next scanline to render
display_base res         1

'kak res 1

fit  496

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