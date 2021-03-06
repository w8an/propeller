{{
  ┌───────────────────────────────────────────┐                                                                    │
  │     Author:  John B. Fisher               │
  │    Version:  1.0 (February 2007)          │
  │      Email:  johnbfisher@earthlink.net    │
  │  Copyright:  None                         │
  └───────────────────────────────────────────┘
 
SevenSegment.spin.
Displays choices provided by five bits of Sony IR remote button pushes on
one seven segment display.

Propeller pin and ground connections:

         common cathode
           ────┬────
 pin:   19  18 │ 17  16
        ┌┴──┴──┴──┴──┴┐
        │      17     │
        │             │
        │ 18       16 │       
        │      19     │
        │             │
        │  22      20 │
        │             │
        │       21    │
        └┬──┬──┬──┬──┬┘
 pin:   22 21  │  20 dp(nc)
           ────┴────
    alternative common cathode
}}
        
CON

    _xinfreq = 5_000_000
    _clkmode = xtal1 + pll16x

VAR
    ' No variables

PUB Init

    dira[16..22]~~


PUB DisplayDigit(message)
        
    outa[16..22] := BitPattern[message]
    waitcnt((2*clkfreq/3)+cnt)
    outa[16..23] := 0

PUB LoudnessUp
    outa[16..22] := BitPattern[16]
    waitcnt((2*clkfreq/3)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)
    
    outa[16..22] := BitPattern[18]
    waitcnt((clkfreq/10)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)
    
    outa[16..22] := BitPattern[19]
    waitcnt((clkfreq/10)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)
 
    outa[16..22] := BitPattern[20]
    waitcnt((clkfreq/10)+cnt)
    outa[16..23] := 0
    waitcnt(clkfreq/17+cnt)


PUB LoudnessDown
    outa[16..22] := BitPattern[16]
    waitcnt((2*clkfreq/3)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)
    
    outa[16..22] := BitPattern[20]
    waitcnt((clkfreq/10)+cnt)
    outa[16..23] := 0
    waitcnt(clkfreq/17+cnt)

    outa[16..22] := BitPattern[19]
    waitcnt((clkfreq/10)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)

    outa[16..22] := BitPattern[18]
    waitcnt((clkfreq/10)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)

PUB ChannelUp

    outa[16..22] := BitPattern[12] 
    waitcnt((2*clkfreq/3)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)

    outa[16..22] := BitPattern[18]
    waitcnt((clkfreq/10)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)
    
    outa[16..22] := BitPattern[19]
    waitcnt((clkfreq/10)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)
 
    outa[16..22] := BitPattern[20]
    waitcnt((clkfreq/10)+cnt)
    outa[16..23] := 0
    waitcnt(clkfreq/17+cnt)    
    

PUB ChannelDown

    outa[16..22] := BitPattern[12] 
    waitcnt((2*clkfreq/3)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)
    
    outa[16..22] := BitPattern[20]
    waitcnt((clkfreq/10)+cnt)
    outa[16..23] := 0
    waitcnt(clkfreq/17+cnt)

    outa[16..22] := BitPattern[19]
    waitcnt((clkfreq/10)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)

    outa[16..22] := BitPattern[18]
    waitcnt((clkfreq/10)+cnt)
    outa[16..22] := 0
    waitcnt(clkfreq/17+cnt)
    
PUB Power

    outa[16..22] := BitPattern[17]
    waitcnt((2*clkfreq/3)+cnt)
    outa[16..23] := 0

PUB AroundTheBlock

    repeat 3
        outa[16..22] := %0100000
        waitcnt((clkfreq/20)+cnt)
        outa[16..22] := %1000000
        waitcnt((clkfreq/20)+cnt)
        outa[16..22] := %0000100
        waitcnt((clkfreq/20)+cnt)        
        outa[16..22] := %0000010
        waitcnt((clkfreq/20)+cnt)
        outa[16..22] := %0000001
        waitcnt((clkfreq/20)+cnt) 
        outa[16..22] := %0010000
        waitcnt((clkfreq/20)+cnt)
        outa[16..22] := %0100000
'        waitcnt((clkfreq/20)+cnt)
    outa[16..23] := 0
 

DAT

'                     Bit Pattern   Display           Offset

BitPattern     Byte     %1110111    '  0                 0
               Byte     %1000100    '  1                 1    
               Byte     %1101011    '  2                 2    
               Byte     %1101110    '  3                 3    
               Byte     %1011100    '  4                 4    
               Byte     %0111110    '  5                 5    
               Byte     %0011111    '  6                 6    
               Byte     %1100100    '  7                 7    
               Byte     %1111111    '  8                 8    
               Byte     %1111100    '  9                 9    
               Byte     %1111101    '  A                10   
               Byte     %0011111    '  b                11  
               Byte     %0110011    '  C                12  
               Byte     %1001111    '  d                13 
               Byte     %0111011    '  E                14 
               Byte     %0111001    '  F                15 
               Byte     %0010011    '  L                16 
               Byte     %1111001    '  P                17
               Byte     %0000010    '  Bottom Bar       18
               Byte     %0001000    '  Middle Bar       19
               Byte     %0100000    '  Top Bar          20