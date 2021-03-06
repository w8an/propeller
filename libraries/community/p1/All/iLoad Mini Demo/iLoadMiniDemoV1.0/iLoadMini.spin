{{
''***************************************
''* iLoad Mini V1.0                     *
''* (C) 2008 Loadstar Sensors           *
''* Author:  Oliver Theile              *
''* based on Ping_Demo                  *
''* Started: 01-10-2008                 *
''***************************************
This object is for the iLoad Mini Sensor from Loadstar Sensors Inc.

     
Pin connections (sensor)          (Propeller)
-------------------------------------------------------
  Red (+5VDC)       ────────────── +5V
  Black (Ground)    ────────────── VSS
                           1K
  Green (Frequency) ──────────── P0
  White (Control)   ────────────── P1


Equations:
----------
  CC        := 5,000,000 - 10 * (Fx - k*Fr)
  Load(lbs) := qA*CC*CC + qB*CC + qC - Tare

Provides functionality to:
--------------------------

  • use output to toggle control switch
  • constants: A,B,C and k0
  • tare when program started
  • output load
  • Cog used for measuring frequency
---------------------------------------------------------------------------------
}}

CON

  offset = 5_000_000                                    ' Offset to calculate CC

  ms_dly = 200                                          ' Delay in milliseconds to measure the frequency

OBJ

  F      :     "FloatMath"                              ' Floating-point math
  
VAR

  long stack[50]
  long Fx, Fr, CC, Tare, Load, qA, qB, qC, k0

PUB GetFreq(Freq_Pin, Ctrl_Pin)

  Tare := 0.0
  cognew(Measuring(Freq_Pin, Ctrl_Pin), @stack)         ' start measurement
  
PUB SetParam(A, B, C, k)
  qA  := A
  qB  := B
  qC  := C
  k0  := k

PUB SetTare
  GetLoad
  Tare := Tare + Load

PUB GetLoad: dspLd| Axx, Bx 

  Axx   := F.FMul(qA, F.FFloat(CC*CC))
  Bx    := F.FMul(qB, F.FFloat(CC))
  Load  := F.FAdd(Axx, F.FAdd(Bx, qC))                  ' Load = qA * CC^2 + qB * CC + qC
  Load  := F.FSub(Load, Tare)                           ' Load = Load - Tare
                                             
  dspLd := F.FRound(F.Fmul(F.FAbs(load),10.0))

PRI Measuring(Freq_Pin, Ctrl_Pin)

  DirA[Ctrl_Pin] := 1                                   ' Set output pins

  Repeat                                   
    OutA[Ctrl_Pin]    := 1                              ' Set Ctrl_Pin High
    Fx := (MeasureFrequency(Freq_Pin))                  ' Store Current Frequency 
    OutA[Ctrl_Pin]    := 0                              ' Set Ctrl_Pin Low
    Fr := (MeasureFrequency(Freq_Pin))                  ' Store Current Frequency (Reference)
    CalcCC                                              ' Calculate CC

PRI MeasureFrequency(Freq_Pin)

  DirA[Freq_Pin] := 0                                   'Set Freq_Pin as Input
  CTRA := 0                                             'Clear settings
  CTRA := (%01010 << 26 ) | (%001 << 23)| (Freq_Pin)    'Trigger to count rising edge on all Input Pin
  FRQA := 1000
  PHSA := 0                                             'Clear accumulated value
  waitcnt(clkfreq / 1_000 * ms_dly + cnt)               'Wait
  return PHSA/ ms_dly                                   'Calculate Freq

PRI CalcCC

  CC := offset - 10 * F.FRound(F.FSub(F.FFloat(Fx), F.FMul(k0,F.FFloat(Fr))))  'CC = Offset - 10 * (Fx - k*Fr)