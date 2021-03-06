
{{
  This is the early prototype of the led_pwm driver. This runs entirely within cog ram, using hard coded values.
  It lights up all the LEDs at different values, and then decays them.

  This illustrates how to use self modifying code to process a sequence of values.

  Copyright (c) 2011 Colin Fox <greenenergy@gmail.com>
}}

_xinfreq = 5_000_000
_clkmode = xtal1 + pll16x



PUB Main

  cognew(@Persist, 0)

DAT
' PWM LED Brightness control. The wave is broken up into n steps (currently 64). Each LED has a value from 0 to n,
' and if the LED is > the current wave part, then it is turned on. At the end of each full wave output, the decay
' counter is decremented. If it reaches 0, then each non-zero LED value is decremented, and then it
' loops back to the beginning.
'
' decayrs - the number of full waves to output before decaying one step
' decaycount - the current decay value
' wavemax - the number of divisions of the PWM wave
' wavepart - the current wave value

        ORG   0
Persist
              mov             dira, pins
              mov             time, cnt                 ' Take the current time
              add             time, delay               ' And give ourselves time for setup
:mainloop
              mov             decaycount, decayrs
:decayloop
              mov             wavepart, wavemax
:waveloop
              mov             index, #LEDS
              mov             accum, #0
              mov             counter, #8               ' counter = number of LEDs
:ledloop
              movs            :set, index

              shl             accum, #1

              ' for
              '    cmp value1,value2
              '      if the wz flag is set, z is set if value1 = value2
              '      if the wc flag is set, c is set if value1 < value2

:set          cmp             wavepart, 0-0   wz,wc   '0-0 is a convention meaning "to be self-modified"
   if_c       or              accum, #1
              add             index, #1
              djnz            counter, #:ledloop

              shl             accum, #16

              waitcnt         time, delay

              mov             outa, accum
              djnz            wavepart, #:waveloop

              djnz            decaycount, #:decayloop

              ' Having this jump here disables decay.
              'jmp             #:mainloop

              mov             decaycount, decayrs

              ' Now, reduce the counters of all the LEDs

              mov             index, #LEDS
              mov             counter, #8

:loop2        movd            :tmpx,  index
              add             index,  #1
:tmpx         cmpsub          0-0,    #1
              djnz            counter,#:loop2

              jmp             #:mainloop


pins    long  255<<16 ' because the leds start at 16

LEDS    long  10
        long  20
        long  30
        long  40
        long  48
        long  55
        long  60
        long  64

delay   long  4000  ' Actual PWM carrier period will be delay * wavemax
decayrs long  7
wavemax long  64

' Make sure res elements always come last
wavepart res  1
decaycount res   1
index   res   1
counter res   1
time    res   1
accum   res   1

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


