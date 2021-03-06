'' *****************************
'' *  Timer_Plus_Countdown     *
'' *  Modified by Jagrifen     *
'' *  (C) 2006 Parallax, Inc.  *
'' *****************************
'' Timer_Plus_Countdown uses regular Timer object and adds the ability to utilize a countdown timer (jagrifen)

CON

  TIX_DLY = 1_000_000 / 10_000                          ' for 10 ms tix period
  MAX_STR = 16                                          ' maximum string length

  #0, TMR_TIX, TMR_SECS, TMR_MINS, TMR_HRS, TMR_DAYS


VAR

  long  cogon, cog                                      ' cog status
  long  tmrStack[12]                                    ' local stack
  long  tix, scs, mns, hrs, dys                         ' timer registers
  long  running                                         ' timer status
  byte  tmrStr[MAX_STR + 1]                             ' add one for zero terminator


PUB start_up : okay

'' Load background timer if cog available
'' -- timer is on hold and registers cleared

  stop
  reset
  okay := cogon := (cog := cognew(updateTimerUp, @tmrStack)) > 0

Pub start_down : okay

  stop
  reset
  okay := cogon := (cog := cognew(updateTimerDown, @tmrStack)) > 0

PUB stop

'' Unload timer object - frees a cog

  if cogon~                                             ' if object running, mark stopped
    cogstop(cog)                                        ' stop the cog


PUB set(h, m, s)

'' Put timer on hold and set hours, minutes, and seconds
'' -- tix and days registers are cleared

  hold                                                  ' put timer on hold
  tix := dys := 0                                       ' clear tix and days
  scs := ||s                                            ' set registers (force positive)
  mns := ||m
  hrs := ||h


PUB reset

'' Put timer on hold and clear registers

  hold                                                  ' stop timer
  tix := scs := mns := hrs := dys := 0                  ' reset registers


PUB hold

'' Put timer on hold without clearing registers

  running~                                              ' disable timer (set to false)


PUB run

'' Allow timer to run and update timer registers

  running~~                                             ' enable timer (set to true)


PUB rdReg(reg)

'' Read a timer register

  case reg
    TMR_TIX  : result := tix                            ' return requested register 
    TMR_SECS : result := scs
    TMR_MINS : result := mns
    TMR_HRS  : result := hrs
    TMR_DAYS : result := dys


PUB wrReg(reg, value)

'' Write value to timer register
'' -- value is forced positive and truncated if required for register

  case reg
    TMR_TIX  : tix := ||value // 100
    TMR_SECS : scs := ||value // 60
    TMR_MINS : mns := ||value // 60
    TMR_HRS  : scs := ||value // 24
    TMR_DAYS : dys := ||value 
  

PUB showTimer | t, s, m, h

  t := tix                                              ' capture timer registers
  s := scs
  m := mns
  h := hrs
  
  bytefill(@tmrStr, 0, MAX_STR + 1)                     ' clear string   

  tmrStr[0] := (h / 10) + "0"                           ' convert 10's digit to ASCII char
  tmrStr[1] := (h // 10) + "0"                          ' convert 1's digit to ASCII char
  tmrStr[2] := ":"
  tmrStr[3] := (m / 10) + "0"
  tmrStr[4] := (m // 10) + "0"
  tmrStr[5] := ":"     
  tmrStr[6] := (s / 10) + "0"
  tmrStr[7] := (s // 10) + "0"
  tmrStr[8] := "."     
  tmrStr[9] := (t / 10) + "0"
  tmrStr[10] := (t // 10) + "0"

  return @tmrStr                                        ' return address of string
  
  
PRI updateTimerUp

'' Updates timer registers
'' -- start method launches this method into separate cog

  repeat                                                ' run until cog unloaded
    if running                                          ' if timer enabled
      waitcnt(clkfreq / TIX_DLY + cnt)                  '   do tix delay
      tix := ++tix // 100                               '   update tix
      if (tix == 0)                                     '   rollover?
        scs := ++scs // 60                              '     yes, update seconds
        if (scs == 0)                                   '     rollover?
          mns := ++mns // 60                            '       yes, update minutes
          if (mns == 0)                                 '       rollover?
            hrs := ++hrs // 24                          '         yes, update hours
            if (hrs == 0)                               '         rollover? 
              ++dys                                     '           yes, increment days

PRI updateTimerDown
'-------------------------countdown ------------------------------------------------
   tix := 99
   repeat
      if running
         waitcnt(clkfreq/ TIX_DLY + cnt)
         tix := --tix
           if (tix == 0)
              tix := 100
              scs--
              if (scs == 0) AND (mns > 0)
                 scs := 60
                 mns--
                 if (mns == 0) AND (hrs > 0)
                    mns := 59
                    hrs--
                    if (hrs == 0)
                       dys--               
              if (scs == 0) AND (mns == 0 )
                 reset


{
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
}