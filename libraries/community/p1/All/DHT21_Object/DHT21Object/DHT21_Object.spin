
''******************************************
''*  Title: DHT21_Object                   *
''*  Author: Gregg Erickson  2012          *
''*  See MIT License for Related Copyright *
''*  See end of file and objects for .     *
''*  related copyrights and terms of use   *
''*  This object draws upon code from other*
''*  OBEX objects such as servoinput.spin  *
''*  and DHT C++  from Adafruit Industries *
''*                                        *
''*  This object reads the temperature and *
''*  humidity from an AM3201/DHT21 Sensor  *
''*  using a unique 1-wire serial protocol *
''*  with 5 byte packets where 0s are 26uS *
''*  long and 1s are 70uS.                 *
''*                                        *
''*  The object automatically returns the  *
''*  temperature and humidiy to variables  *
''*  memory every few seconds as Deg F and *
''*  relative percent respectively. It also*
''*  return an error byte where true means *
''*  the data received had correct parity  *
''*                                        *
''******************************************
{
   Vcc──────────────Red (Power)
                │
               10K (Pull-Up Resistor)
                │
   Prop Pin ────────Yellow (Data)


   VSS──────────────Black (Ground)

}
CON

  _clkmode = xtal1 + pll16x   'Set clock speed and mode
  _xinfreq = 5_000_000


VAR


byte cog
long Stack[50]


PUB Start(Apin,TempPtr,HumPtr,ErrorPtr) : result
{{  This method lauches the DHT_Read method in a new cog
    to read the DHT21 autonomously with variables updated
    every few seconds

    returns cog number + 1
}}

  stop
  cog := cognew(DHT_Read(Apin,TempPtr,HumPtr,ErrorPtr), @Stack) + 1
  result := cog


PUB Stop
{{
   stop cog if in use
}}

    if cog
      cogstop(cog~ -1)




Pub DHT_Read (Apin,TempPtr,HumPtr,ErrorPtr) |Data[5], Temp, Humid, ByteCount,BitCount,Pulsewidth,Parity
{{  This method reads the DHT21 autonomously with variables located at
    the pointers updated every few seconds
}}

                      'Apin is data line in from DHT21
                      'Data[5] bytes received in order from DHT21
                      'DATA = 8 bits of integral RH data
                      '     + 8 bits of decimal RH data
                      '     + 8 bits of integral temperature data
                      '     + 8 bits of decimal temperature data
                      '     + 8 bits check-sum (equals other 4 bytes added)

                      'ByteCount - Index counter for data Bytes
                      'BitCount  - Index counter for bits within data bytes
                      'Pulsewidth- Width of bits received from DHT21, 26uS = 0, 70S=1
                      'P         - Boolean - parity for data from DHT21

Repeat


  waitcnt(clkfreq*2+cnt)                ' Pause to allow DHT21 to stabilize

' Send a 500uS low to the DHT22 to request data

  DIRA[Apin]~~                            ' Set Pin 10 to output
  OUTA[Apin]~                             ' Pull Down Pin 10 for 500 uS to Request Data
  waitcnt(clkfreq/2000+cnt)             ' Pause for 500uS
  OUTA[Apin]~~                            ' Return Pin to High
  DIRA[Apin]~                             ' Set Pin 10 to Input and Release Control to DHT22

  'Set Counter A mode while waiting for DHT to respond

  ctra[30..26] := %11010                ' Set mode to "APIN=1"
  frqa := 1                             ' Increment phsa by 1 for each clock tick

' DHT21 reponds with a ready signal (80uS low, 80uS high, 40 uS low, before data)

  waitpeq(|<Apin,|<Apin,0)  ' Wait for low, high, low sequence
  waitpne(|<Apin,|<Apin,0)
  waitpeq(|<Apin,|<Apin,0)

' DHT21 will send 40 high bits where 0 is 26uS and 1 is 70uS

  waitpeq(|<Apin,|<Apin,0)  ' Hold Code Till Positive Edge of Pulse
  phsa:=0                               ' Clear Counter Before Positive Edge
  Repeat ByteCount from 0 to 4                 ' Store Data in 5 Bytes
      Data[ByteCount]:=0                       ' Clear Data of Each Byte Before Input
      Repeat BitCount from 7 to 0              ' Receive Data by Bit, MSB to LSB
         ctra[5..0] :=Apin                     ' Counter Accumulates During High Signal on APIN
         waitpne(|<Apin,|<Apin,0)                ' Resume Code After Negative Edge when Count is Done
         Pulsewidth:=phsa /(clkfreq/1_000_000)
         If Pulsewidth>48                                    ' If Pulse > 48 uS then bit is 1 else 0
             Data[ByteCount]:=(Data[ByteCount])|(|<BitCount) ' Store the bit in byte
         phsa:=0                                             ' Clear Counter Before Positive Edge


' Calculate Temperature

  Temp:=data[2]& $7f      ' Pull from data2 and mask except MSB Bit
  Temp*=256               ' Put into upper byte
  Temp+=data[3]           ' Add lower byte
  Temp/=10                ' Divide by 10
  Temp:=9*Temp/5   ' Convert from F to C
  Temp+=32
  if Temp & $80           ' Flag if negative
     Temp*=-1

' Calculate Humidity

  Humid:=data[0]              ' Pull from data0
  Humid*=256                  ' Put into upper byte
  Humid+=data[1]              ' Add lower byte
  Humid/=10                   ' Divide by 10

' Check Parity
  parity:=((data[0]+data[1]+data[2]+data[3])& $ff)==(data[4]) 'Last byte equals sum of first four bytes

' Return values to addresses provided in pointers

  Long[tempptr]:=temp                             ' Temperature
  Long[HumPtr]:=humid                             ' Humidity
  Long[ErrorPtr]:=parity                          ' Parity


return
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

