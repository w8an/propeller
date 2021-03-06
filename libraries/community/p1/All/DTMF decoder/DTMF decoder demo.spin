''***************************************
''*  DTMF decoder based on              *
''*  ADC and Goertzel waveform analyzer *
''*  Author: Thierry Eggen, ON5TE       *
''*  Copyright (c) 2014 Thierry Eggen   *
''*  See end of file for terms of use.  *
''***************************************

{
This demo uses a DTMF decoder based on  Multi-frequency, real time audio  ADC and Goertzel waveform analyzer written by Phil Pilgrim.
The "goertzel.spin" object is taken as it is, without any modification. It uses one Cog.

A second Cog is used to repeatedly see if a correct DTMF code is present, it means we get the two correct frequencies, and the other ones are considered as absent.
( See Treshold here below). When a DTMF code is present, we take it and loop until it diappers (some kind of debouncing).

This code is appended to the DTMFstring until the DTMFStringLength is reached. We can then compare with a set of commands, etc.
In this example, the DTMFstring is reset with receiving a "*", so you can't use it inside the command string itself.

The method GETDTMFCHAR here below is non blocking: it returns the character "X" if no valid DTMF detected.
If you want to make it blocking, simply remove the "other:" clause in the "case of" (see comments below).

It's currently used in a ham radio UHF repeater to remote control some functions.

The repeater logic is also in spin in the same propeller, it will be published soon.

Hardware: same as in the standard sigma delta ADC: one 100K resistor and two 1K capacitors plus inmput impedance adapter, see Parallax application note on ADC.     
}
con
  _CLKMODE = XTAL1 + PLL16X
  _CLKFREQ = 80_000_000

  INP_PIN         =       8               ' DTMF decoder input    ' ADC sigma delta
  FB_PIN          =       9               ' DTMF decoder input    ' ADC sigma delta
  
' goertzel specific

  NBINS         = 8             'Eight DTMF frequencies.
  SamplingRate  = 8000          ' frequency (Hz) at which the ADC is sampled.   
  GoertzelRate  = 5             ' number of times per second to report results
  GoertzelN     = 91            ' number of samples required to obtain each result. The higher this number is, the narrower the passband of the consequent filters.
  Treshold      = 500           ' treshold at which we consider that the corresponding frequency is present
  DTMFStringLength              = 4 ' lenght of the expected command string

DAT
  dtmf          long      697,770,852,941,1209,1336,1477,1633  '              ' frequencies to watch for DTMF detection
obj
  goertzel      : "goertzel" 
  pst           : "parallax serial terminal"     ' for debug only, not needed otherwise

VAR
  ' DTMF and Goertzel specific  
  long  bins[8], count, pcount                          ' these variables need to stay together, same order
 ' long  dtmfpointer                                     ' work variable
  long  DTMFStack[30]                                   ' most probably oversized
  byte  dtmfstring[DTMFStringLength]                    ' workarea
  byte  dtmfpattern, dtmfchar

  long  stringaddr

pub start
  pst.start(115200)    ' start serial terminal at 115200 bps
  waitcnt (160_000_000 + cnt)  ' wait while somebody loads the terminal on the PC
  pst.str(string("here we go",13))
  ' launch Goertzel algorithm to detect DTMF tones
  longmove(@bins, @dtmf, NBINS)                          ' tell Goertzel algorithm which frequencies to watch
  goertzel.start(INP_PIN, FB_PIN, NBINS, @bins, @count, SamplingRate, GoertzelRate, GoertzelN)
 
  cognew(DTMFProc,@DTMFStack)                            ' launch DTMF commands detection

  stringaddr := 0
  repeat
    repeat while stringaddr == 0
    pst.str(stringaddr)
    stringaddr := 0
    pst.newline
     
                           ' That's all folks!
                           ' =================
                           
Pri DTMFProc | dtmfpointer ' should be in its own cog to wait for command while your are busy somewhere else
   repeat
      dtmfpointer := 0
      repeat while dtmfpointer < DTMFStringLength ' is the string full ?
        dtmfchar := "X"               ' ste character received to invalid
        repeat while dtmfchar == "X"  ' loop until a valid DTMF received
          dtmfchar := getdtmfchar     ' take a copy
        repeat while getdtmfchar <> "X"  ' loop until DTMF finished
        if dtmfchar == "*"               ' if start character
          dtmfpointer := 0               ' point to begin of string
        else
          dtmfstring[dtmfpointer] := dtmfchar ' else append character received
          dtmfpointer++                       ' point to next free position
      if strcomp(@dtmfstring,string("A123")) == true  ' following is a simple demo
        stringaddr := string("123 received")
      elseif strcomp(@dtmfstring,string("B456")) == true
        stringaddr := string("B456 received")
      elseif strcomp(@dtmfstring,string("C789")) == true
        stringaddr := string("C789 received")
               
Pri GetDTMFChar | i                                    ' method not blocking, returns "X" if no valid DTMF code detected
                                                        ' to make it blocked until valid DTMF received, simply remove the "OTHER : return "X"' here below
  repeat                                                ' loop until Mr. Goertzel made his job
    repeat while count == pcount
    pcount := count
    dtmfpattern := 0                                    ' init DTMF byte to all zeroes
    repeat i from 0 to NBINS - 1                        ' for each frequency ...
      if bins[i] > treshold                             ' get Goertzel coefficients
        byte[@dtmfpattern] := byte[@dtmfpattern] | (1<<i)' reflect bit per bit in a byte 
   case dtmfpattern                                     ' decode corresponding DTMF and return it
     %00010001 : return "1"
     %00100001 : return "2"
     %01000001 : return "3"
     %10000001 : return "A"
     %00010010 : return "4"
     %00100010 : return "5"
     %01000010 : return "6"
     %10000010 : return "B"
     %00010100 : return "7"
     %00100100 : return "8"
     %01000100 : return "9"
     %10000100 : return "C"
     %00011000 : return "*"
     %00101000 : return "0"
     %01001000 : return "#"
     %10001000 : return "D"
     other     : return "X"                              ' return X if not valid DTMF received

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