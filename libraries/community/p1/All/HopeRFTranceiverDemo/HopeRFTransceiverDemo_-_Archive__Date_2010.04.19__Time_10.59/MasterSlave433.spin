{{                 
                      HOPERF HM-TR 433Mhz Transceiver test program
                                  Author: Ray Tracy
                             Copyright (c) 2010 Ray Tracy
                        * See end of file for terms of use. *

                   ┌─────────────────────────────────────────────────┐
                   │                                                 └─┐
                   │   HOPERF HM-TR TTL  433Mhz Transceiver          ┌─┘ Antenna
                   │                                                 │
                   │ VCC DTx GND DRx CFG ENA                         │
               +5  │  1   2   3   4   5   6                          │          
                  └──┬───┬───┬───┬───┬───┬──────────────────────────┘   
               │      │   │   │   │   │   │     
               └──────┘   │      │      │
                          │       │       └─────────── Enable (EnaPin)
                          │       │                 
                          │       └─────────── Tx from Prop (TxPin)
                          │       
                          └───────────  Rx To Prop (RxPin)

     Note: #1 Tx from the Prop goes to DRx on the module
              Rx from the Prop goes to DTx on the module.
           #2 The HM-TR is really half duplex and automatically
              switches to receive after send.

 }}
CON
  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000
'===============< Precalculated Delay Times >=================
  Clock         = 80_000_000          '_CLKFREQ
  Sec5          = Clock * 5
  ms500         = Clock / 2
  ms100         = Clock / 10
  ms10          = Clock / 100
  ms2           = Clock / 500       
  ms1           = Clock / 1_000
  led1          = 16        

  PstBaud  = 115200
  HmTrBaud = 9600

OBJ
  Pst:  "Parallax Serial Terminal"
  Ser:  "Simple_Serial"
  
VAR  
  long Stack[32]          'Alocate stack space for the cog
  byte cog                'Cog ID
  
PUB Start(RxPin, TxPin, EnaPin, MS): Ok
'' Starts two cogs Master and Slave
'' Master transmits module printable characters and echos received characters to the Terminal
'' Slave receives characters and retransmits,  the number zero is translated to a CR
 
   If MS                                                                 ' Is this a Master or a Slave
      Ok := (cog := cognew( Master(RxPin, TxPin, EnaPin), @stack) + 1)   ' Launch the Master cog
   else
      Ok := (cog := cognew( Slave(RxPin, TxPin, EnaPin), @stack) + 1)    ' Launch the Slave cog

Pri Master(Rx, Tx, Ena) | I, Char   ' This code runs in the just launched cog
   Pst.Start(PstBaud)               ' Only one cog can talk to the terminal
   Ser.Init(Rx, Tx, HmTrBaud)       ' Initialize the serial interface
   dira[Ena]~~                      ' Make Enable Pin an output   
   outa[Ena]~~                      ' Wakeup the module       (Set Enable Pin High)
   repeat
      repeat  I from $30 to $7F     ' All the Printable Characters
           Ser.Tx( I )              ' Send 1 Char
           Char := Ser.Rx           ' Rcve 1 Char
           ifnot (Char==13)         ' 13 is a CR (newline)
              Pst.Char( Char )      ' Display the received Char
           else
              Pst.NewLine           ' or a newline
      waitcnt(Sec5+cnt)            ' wait half second
      
Pri Slave(Rx, Tx, Ena) | I, Char    ' This code runs in the just launched cog
   dira[Ena]~~                      ' Make Enable Pin an output   
   outa[Ena]~~                      ' Wakeup the module       (Set Enable Pin High)
   Ser.Init(Rx, Tx, HmTrBaud)       ' Initialize the serial interface
   repeat
       Char := Ser.Rx               ' Receive 1 Char
       if (Char==$30)               ' If we see the number zero        
          Char := 13                ' Send a newline instead
       Ser.Tx( Char )               ' Send 1 Char

Dat
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
              