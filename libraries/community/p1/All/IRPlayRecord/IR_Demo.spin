{{
*****************************************
* 38KHz PWM IR Remote record/playback   *
* Author: Christopher Cantrell          *               
* See end of file for terms of use.     *               
*****************************************
}}

'' Operation:

'' This object demonstrates the IRPlayRecord object -- a universal IR remote control with
'' record/playback functions.

'' Simply connect a 3-pin GP1UX311QS IR sensor and an LED IR LED to the propeller demo
'' board. Then use a TV and keyboard interface to record and playback IR sequences from
'' any remote.

'' For instance, Type "+TV_Volumne_up" and press enter. Then press the VOLUME UP on the target TV
'' remote. Then type "*TV_Volume_up" to play the sequence back and turn the volume up on the TV.

'' A large number of sequences can be stored in the IRPlayRecord object's database. The object
'' can be the basis of a universal remote control project.

CON 
        _clkmode        = xtal1 + pll16x
        _xinfreq        = 5_000_000

VAR

' Command box to talk to IRPlayRecord cog        
        long command        
        long paramError
        long bufPtr

' Named-sequence database
        byte sequenceData[8192]

' Scratch area for input string
        byte stringBuffer[200]

OBJ                                 
        term     : "tv_text"                
        kb       : "Keyboard"

        ir       : "IRPlayRecord"   

PUB start | c, i

  'start the tv text
  term.start(12)

  'start the keyboard
  kb.start(26, 27)

  paramError:= (7<<8) | 0  ' Output/Input pin numbers
  bufPtr:=@sequenceData    ' The sequence table
  command:=1               ' Driver clears after init
  ir.start(@command)       ' Start the IRPlayRecord
  repeat while command<>0  ' Wait for driver to start

  command:=$50
  repeat while command<>0  ' Wait for driver to start 

  printHelp

  repeat
    term.out(":")
    getString(@stringBuffer,200)

    if stringBuffer[0]=="+"
        term.str(string("Press button on remote",13))
        bufPtr:=@stringBuffer+1
        paramError:= 200
        command:=$10    
        repeat while command<>0  

    elseif stringBuffer[0]=="*"
        bufPtr:=@stringBuffer+1
        command:=$20           
        repeat while command<>0    
              
    else
      term.str(string("Unknown command",13))
      printHelp
      

PUB printHelp
  term.str(string("+TVVolUp   records sequence 'TVVolUp'",13))
  term.str(string("*TVVolUp   plays sequence 'TVVolUp'",13))
  term.out(13)

'' Simple keyboard string-input function  
PUB getString(buffer,size) | cursize, c

  cursize :=0      ' Current size of input 

  repeat
    term.out("_")        ' Cursor (too bad it doesn't blink)
    c:= kb.getKey        ' Wait for a key
    term.out(8)          ' Clear the ...
    term.out(" ")        ' ... cursor ...
    term.out(8)          ' ... character
    if c==$C8                   ' Backspace?
      if cursize<>0               ' Make sure there is something to erase
        term.out(8)               ' Back off the last screen character
        cursize:=cursize-1        ' Back off last input character
    elseif c==13                ' Enter?
       byte[buffer+cursize]:=0    ' Null terminate the string
       term.out(13)               ' The user DID press enter
       return                     ' Done here
    else                        ' Plain old character
     if cursize<size              ' Make sure there is room
       term.out(c)                   ' Put the character on the screen
       byte[buffer+cursize]:=c       ' Put the character in the buffer
       cursize:=cursize+1            ' Increment the buffer

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
           