
{{

┌────────────────────────────────────────────────┐
│                                                │                          
│ Author: Brian McClure                          │
|  Email: brian.mcclure{at}gmail.com             │
│    web: www.n8vhf.com                          │
│                                                │               
│ Copyright (c) 2012                             │
│ See end of file for terms of use.              │
│                                                │                
└────────────────────────────────────────────────┘

I2C Interface for the Honeywell HIH-6130/6131 series of temperature and humidity
sensors and the LM76CHM from National Semi/TI


}}

CON
  _clkmode        =             xtal1 + pll8x
  _xinfreq        =             5_000_000
    
  CR            = 13
  HIH6131       = ($27 << 1)  '//Device I2C addess. This is not a pin selectable address. 
                              '//Can be changed using COMMAND MODE. Factory default is usually 0x27                         

OBJ
                                                         
  uarts         : "pcFullDuplexSerial4FC"
  hih           : "HIH6131_Object"
  i2c           : "Basic_I2C_Driver"
  lm76          : "LM76CHM_Object"
  fp            : "FloatString"
  f             : "Float32"
    
VAR
  long rawData   '//raw data from HIH6131
  long humRel    '//humidity from HIH6131 
  long tempC     '//temperature C from HIH6131
  byte status    '//status from HIH6131
  long lmData    '//rawData from LM76CHM
  
  

DAT
   
  
   
PUB Start    | fTempC, fTempF, fHumRel, lTempC, lTempF

  f.Start  '//Start the Floating Point Engine


  uarts.Init                                           'Init serial ports
  '  PUB AddPort(port,rxpin,txpin,ctspin,rtspin,rtsthreshold,mode,baudrate)
  '  Call AddPort to define each port
  '' port 0-3 port index of which serial port
  '' rx/tx/cts/rtspin pin number                          XXX#PINNOTUSED if not used
  '' rtsthreshold - buffer threshold before rts is used   XXX#DEFAULTTHRSHOLD means use default
  '' mode bit 0 = invert rx                               XXX#INVERTRX
  '' mode bit 1 = invert tx                               XXX#INVERTTX
  '' mode bit 2 = open-drain/source tx                    XXX#OCTX
  '' mode bit 3 = ignore tx echo on rx                    XXX#NOECHO
  '' mode bit 4 = invert cts                              XXX#INVERTCTS
  '' mode bit 5 = invert rts                              XXX#INVERTRTS
  

  uarts.AddPort(0,31,30,-1,-1,-1,0,57600)     '//serial out used for debugging or data
  
  
  uarts.Start   '//Start the ports

  pause (5000) '// give the user time to switch to the serial terminal if debugging
                                         
  uarts.str(0, string("Starting...", 13))  '//this lets shows that the Prop is alive.


  hih.Init(0, $27) '// initialize the HIH6131
  
  repeat

    '//read data from the LM76CHM
    lmData := 99999   '//clear lmData to something out of bounds
    
    lmData := lm76.ReadLM76(0,$96)>>3  '//shift right 3 bits to drop the status and alarm bits
        
    'lmData := $1e70 ' & $FFF   '//fake a negative temperature  for testing
        
    lTempC := f.FFloat(lmData & $FFF)    '//convert lmData to float, strip off sign bit

    uarts.str(0, string(13,10,"LM76 raw data: "))
    uarts.hex(0,lmData,8)
    uarts.str(0, string(13,10))
    uarts.str(0, string(13,10))

        
    if lmData>>12 == $1     '// check the sign bit to see if the temperature is <0c
      lTempC := f.FMul(f.FSub(4096.0,lTempC),-0.0625)  '// convert to temperature C,  note the negative 0.0625
    else
      lTempC := f.FMul(lTempC,0.0625)
    
    uarts.Str(0,fp.FloatToString(lTempC))
    uarts.str(0,string(" C",13,10))
 
    lTempF := f.FAdd(f.FMul(lTempC, 1.8), 32.0)   '//Convert to temperature F
    uarts.Str(0,fp.FloatToString(lTempF))
    
    uarts.str(0, string(13,10))
    uarts.str(0, string(13,10))
    uarts.str(0, string("=================================================", 13,10))

    
    uarts.str(0, string(13,10))


   '//read data from the LM76CHM

     rawData := 99999      '//clear rawData to something out of bounds 

  
    rawData :=  hih.readData32(0,HIH6131)   '// read the data from the i2c bus. I've found that any Prop I/O can be used for I2C

    uarts.str(0, string("HIH6131 raw data: "))  
    uarts.hex(0, rawData , 8)               '//Hex output of raw data from sensor
    uarts.str(0, string(13,10))

    status := rawData >> 30
    uarts.str(0, string("Status: ")) 
    uarts.bin(0,status,2)                   '//Hex output of STATUS data from sensor                                    
    uarts.str(0, string(13,10))

    humRel := (rawData << 2)>>18
    uarts.str(0, string("Raw HumRel ")) 
    uarts.hex(0,HumRel,8)                  '//Hex output of RAW Humidity from sensor
    uarts.str(0, string(13,10))

    tempC := (rawData & $0000FFFF )>>2
    uarts.str(0, string("Raw TempC ")) 
    uarts.hex(0,TempC,8)                   '//Hex output of RAW Temperature (Celcius) from sensor
    uarts.str(0, string(13,10))
   


    '//Calculate actual Humidity and Temp from Raw Values
    fTempC := f.FFloat(tempC)      '//convert tempC to float
        
    uarts.str(0, string(13,10))
    fTempC := f.FAdd(f.FMul(f.FDiv(fTempC,16383.0),165.0),-40.0)   '//Convert to temperature C
    uarts.Str(0,fp.FloatToString(fTempC))
    uarts.str(0,string(" C",13,10))
    

    fTempF := f.FAdd(f.FMul(fTempC, 1.8), 32.0)      '//Convert to temperature F
    uarts.Str(0,fp.FloatToString(fTempF))
    uarts.str(0,string(" F",13,10))
    uarts.str(0, string(13,10))

    uarts.str(0, string("=================================================", 13,10))

    
    pause(2000) 
  




PRI pause(Duration)                       '//found this delay function somewhere, can't remember who wrote it. Sorry
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return
 

{{
MIT License   http://www.opensource.org/licenses/mit-license.php

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies
 or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
}}