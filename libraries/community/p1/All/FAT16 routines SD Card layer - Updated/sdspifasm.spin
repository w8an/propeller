'   sdspi:  SPI interface to a Secure Digital card.
'
'   Copyright 2008   Radical Eye Software
'
'   See end of file for terms of use.
'
'   You probably never want to call this; you want to use fsrw
'   instead (which calls this); this is only the lowest layer.
'
'   Assumes SD card is interfaced using four consecutive Propeller
'   pins, as follows (assuming the base pin is pin 0):
'                3.3v
'                   
'                    20k
'   p0 ────────┻─┼─┼─┼─┼─┼────── do
'   p1 ──────────┻─┼─┼─┼─┼────── clk
'   p2 ────────────┻─┼─┼─┼────── di
'   p3 ──────────────┻─┼─┼────── cs (dat3)
'         150          └─┼────── irq (dat1)
'                        └────── p9 (dat2)
'
'   The 20k resistors
'   are pullups, and should be there on all six lines (even
'   the ones we don't drive).
'
'   This code is not general-purpose SPI code; it's very specific
'   to reading SD cards, although it can be used as an example.
'
'   The code does not use CRC at the moment (this is the default).
'   With some additional effort we can probe the card to see if it
'   supports CRC, and if so, turn it on.   
'
'   All operations are guarded by a watchdog timer, just in case
'   no card is plugged in or something else is wrong.  If an
'   operation does not complete in one second it is aborted.
'
con
   sectorsize = 512
   sectorshift = 9
var
   long cs, starttime, cog
   long command, param ' rendezvous between spin and assembly
pri send(outv)
'
'   Send eight bits, then raise di.
'
   param := outv
   command := "B"
   repeat while command
pri checktime
'
'   Did we go over our time limit yet?
'
   if cnt - starttime > clkfreq
      abort -41 ' Timeout during read
pri read | r
'
'   Read eight bits from the card.
'
   param := -1
   command := "B"
   repeat while command
   return param
pri readresp | r
'
'   Read eight bits, and loop until we
'   get something other than $ff.
'
   repeat
      if (r := read) <> $ff
         return r
      checktime
pri busy | r
'
'   Wait until card stops returning busy
'
   repeat
      if (r := read)
         return r
      checktime
pri cmd(op, parm)
'
'   Send a full command sequence, and get and
'   return the response.  We make sure cs is low,
'   send the required eight clocks, then the
'   command and parameter, and then the CRC for
'   the only command that needs one (the first one).
'   Finally we spin until we get a result.
'
   outa[cs] := 0
   read
   send($40+op)
   send(parm >> 15)
   send(parm >> 7)
   send(parm << 1)
   send(0)
   send($95)
   return readresp
pri endcmd
'
'   Deselect the card to terminate a command.
'
   outa[cs] := 1
   return 0
pub stop
   if cog
      cogstop(cog~ - 1)      
pub start(basepin)
'
'   Initialize the card!  Send a whole bunch of
'   clocks (in case the previous program crashed
'   in the middle of a read command or something),
'   then a reset command, and then wait until the
'   card goes idle.
'
   do := basepin++
   clk := basepin++ 
   di := basepin++
   cs := basepin
'
   outa[cs] := 1
   dira[cs] := 1
   stop
   command := "I"
   cog := 1 + cognew(@entry, @command)
   repeat while command
   starttime := cnt
   cmd(0, 0)
   endcmd
   repeat
      cmd(55, 0)
      basepin := cmd(41, 0)
      endcmd
      if basepin <> 1
         quit
   if basepin
      abort -40 ' could not initialize card
   return 0
pub readblock(n, b)
'
'   Read a single block.  The "n" passed in is the
'   block number (blocks are 512 bytes); the b passed
'   in is the address of 512 blocks to fill with the
'   data.
'
   starttime := cnt
   cmd(17, n)
   readresp
   param := b
   command := "R"
   repeat while command
   read
   read
   return endcmd
{
pub getCSD(b)
'
'   Read the CSD register.  Passed in is a 16-byte
'   buffer.
'
   starttime := cnt
   cmd(9, 0)
   readresp
   repeat 16
      byte[b++] := read
   read
   read
   return endcmd
}
pub writeblock(n, b)
'
'   Write a single block.  Mirrors the read above.
'
   starttime := cnt
   cmd(24, n)
   send($fe)
   param := b
   command := "W"
   repeat while command
   read
   read
   if ((readresp & $1f) <> 5)
      abort -42
   busy
   return endcmd
dat
        org
entry   mov comptr,par
        mov parptr,par
        add parptr,#4
' set up
        mov acca,#1
        shl acca,di
        or dira,acca
        mov acca,#1
        shl acca,clk
        or dira,acca
        mov acca,#1
        shl acca,do
        mov domask,acca
        mov phsb,negone
        mov frqb,#0
        mov acca,nco
        add acca,clk
        mov ctra,acca
        mov acca,nco
        add acca,di
        mov ctrb,acca
' send out 5000 clock pulses @ 10MHz
        mov frqa,hifreq
' wait 5000 * 8 = 40,000 clock cycles
        add waiter,cnt
        waitcnt waiter,#0
' reset frqa and the clock
finished
        mov frqa,#0
        wrlong frqa,comptr
        mov phsa,negone    
        mov phsb,negone
waitloop
        rdlong acca,comptr wz
        cmp acca,#"B" wz
   if_z jmp #byteio
        mov ctr2,sector
        rdlong accb,parptr
        cmp acca,#"R" wz
   if_z jmp #rblock
        cmp acca,#"W" wz
  if_nz jmp #waitloop
wblock
        mov frqa,negone
wbyte
        rdbyte phsb,accb
        shl phsb,#23
        add accb,#1
        mov ctr,#8
wbit    mov phsa,#8
        shl phsb,#1
        djnz ctr,#wbit
        djnz ctr2,#wbyte        
        mov frqa,#0
        jmp #finished
rblock
        sub accb,#1
rbyte
        mov phsa,hifreq
        mov frqa,freq
        add accb,#1
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        test domask,ina wc
        addx acca,acca
        mov frqa,#0
        test domask,ina wc
        addx acca,acca
        wrbyte acca,accb
        djnz ctr2,#rbyte        
        mov frqa,#0
        jmp #finished
byteio     
        rdlong phsb,parptr
        shl phsb,#24
        mov ctr,#8
        mov frqa,negone
        mov accb,#0
bit     mov phsa,#8
        test domask,ina wc
        addx accb,accb        
        shl phsb,#1
        djnz ctr,#bit
        wrlong accb,parptr
        jmp #finished

di      long 0
do      long 0
clk     long 0
negone  long -1
nco     long $1000_0000
hifreq  long $e0_00_00_00
freq    long $20_00_00_00
waiter  long 40_000
sector  long 512
domask  res 1
acca    res 1
accb    res 1
comptr  res 1
parptr  res 1
ctr     res 1
ctr2    res 1
{{
'  Permission is hereby granted, free of charge, to any person obtaining
'  a copy of this software and associated documentation files
'  (the "Software"), to deal in the Software without restriction,
'  including without limitation the rights to use, copy, modify, merge,
'  publish, distribute, sublicense, and/or sell copies of the Software,
'  and to permit persons to whom the Software is furnished to do so,
'  subject to the following conditions:
'
'  The above copyright notice and this permission notice shall be included
'  in all copies or substantial portions of the Software.
'
'  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
'  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
'  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
'  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
'  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
'  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
'  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}}