{{

┌───────────────────────────────────────────────────────┐
│ CommandParser_Kdemo, program to test indexed command  │
│ object                                                │
│ Author: Eric Ratliff                                  │
│ Copyright (c) 2009 Eric Ratliff                       │
│ See end of file for terms of use.                     │
└───────────────────────────────────────────────────────┘

2009.10.24 by Eric Ratliff
}}

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
  NumCommands = 2

OBJ
  ConsoleSerialDriver : "Kermit EEPROM Console"
  nums : "Numbers"
  parser : "CommandParser"

VAR
  ' console serial port variables
  long rxPin ' where Propeller chip receives data
  long txPin ' where Propeller chip outputs data
  long SerialMode ' bit 0: invert rx, bit 1 invert tx, bit 2 open-drain source tx, ignore tx echo on rx
  ' individual components of mode
  long InvertRx
  long InvertTx
  long OpenDrainSourctTx
  long IgnoreTxEchoOnRx
  long baud ' (bits/second)

  ' interface for command lines
  byte CommandBuffer[ConsoleSerialDriver#LineLengthLimit+1] ' room for command and null terminator
  long argv[ConsoleSerialDriver#LineLengthLimit/2+1] ' where each element in command line begins
  long argc ' how many elements in command line, which is 1 command + n arguments
  long ByteCount ' how many bytes came back in the command
  long UseCommandLines,EchoInput

  long ProcessorResultFlags ' from input or receive file call
  long LastProcessorResultFlags ' history of previous loop
  long CommandList[NumCommands] ' command strings list
  long CommandIndex ' place in command list
  long ArgIndex ' index into argument list

DAT
' index in list followed by null terminated command string
OnCommand byte parser#DummyByte,"on",parser#null
OffCommand byte parser#DummyByte,"off",parser#null

PUB main

  nums.Init ' prepare for formatted output
  parser.Init(@CommandList) ' show parser where command array is

  ' console serial driver parameters
  rxPin := 31 ' 31 is for USB port
  txPin := 30
  
  InvertRx := FALSE   ' (does not matter, this program only transmits)
  InvertTx := FALSE   ' (must be FALSE)
  OpenDrainSourctTx := TRUE
  IgnoreTxEchoOnRx := FALSE
  SerialMode := (%1 & InvertRx)
  SerialMode |= (%10 & InvertTx)
  SerialMode |= (%100 & OpenDrainSourctTx)
  SerialMode |= (%1000 & IgnoreTxEchoOnRx)

  ' 57600 known to have worked with Kermit XBee 'program'
  'baud := 9600
  'baud := 19200 
  'baud := 38400  
  baud := 57600 ' (works with XBee)
  'baud := 115200 ' (almost works with 128 bte rx buffer, runs, more retries, fails, sometimes works)
  'baud := 230400 ' (fails)

  ' set up array of pointers call order defines the order.  This is how commands are defined.
  parser.AppendCommand(@OnCommand)
  parser.AppendCommand(@OffCommand)

  ' start object, letting it know if there are some variables to show and if full debug is happening
  ConsoleSerialDriver.start(rxpin, txpin, SerialMode, baud)
  UseCommandLines := true ' determines if we have single character input or line input
  EchoInput := true 
  ConsoleSerialDriver.SetCommandMode(UseCommandLines,EchoInput)

  repeat 5  ' let user have time to switch on Hyperterminal or start ZTerm, in case USB port is in use
    waitcnt(clkfreq+cnt)' wait 1 second
    ConsoleSerialDriver.str(string("."))
  Prompt ' let user know we are ready to receive commands

  ' set history to show we have not started a Kermit file receive
  LastProcessorResultFlags := false & ConsoleSerialDriver#KEC_ISM_KermitPacketDetected

  repeat
    ProcessorResultFlags := ConsoleSerialDriver.Process

    ' were we NOT processing a Kermit receive?
    if not(LastProcessorResultFlags & ConsoleSerialDriver#KEC_ISM_KermitPacketDetected)
      ' is a command ready?
      if ProcessorResultFlags & ConsoleSerialDriver#KEC_ISM_CommandReady
        ConsoleSerialDriver.ReadBytes(@CommandBuffer,@ByteCount)
        CommandIndex := parser.parse(@CommandBuffer,ByteCount,@argc,@argv)

        ConsoleSerialDriver.str(string("command line parsed to "))
        ConsoleSerialDriver.str(nums.ToStr(argc,nums#DEC))
        ConsoleSerialDriver.str(string(" elements:"))
        ConsoleSerialDriver.CRLF

        repeat ArgIndex from 0 to argc-1
          ConsoleSerialDriver.str(string("---"))
          ConsoleSerialDriver.str(argv[ArgIndex])
          ConsoleSerialDriver.str(string("---"))
          ConsoleSerialDriver.CRLF
        ' the whole purpose of having the commands in structures is to that programming is clear
        ' with case values that have some readable meaning
        case CommandIndex
          OnCommand:
            ConsoleSerialDriver.str(string("would do the on action"))
          OffCommand:
            ConsoleSerialDriver.str(string("would do the off action"))
          other:
            ConsoleSerialDriver.str(string("unrecognized command "))
        ConsoleSerialDriver.CRLF ' a white space blank line
        Prompt
    else ' we were processing a Kermit receive
      ' did Kermit process end?
      if not ProcessorResultFlags & ConsoleSerialDriver#KEC_ISM_KermitPacketDetected
        ' does file size equal declared or assumed size?
        if ProcessorResultFlags & ConsoleSerialDriver#KEC_ISM_KermitCompleted
          ConsoleSerialDriver.str(string("File Receive Finished"))
        else
          ConsoleSerialDriver.str(string("File Receive Stopped"))

    LastProcessorResultFlags := ProcessorResultFlags ' record present status for next loop

PRI Prompt
  ConsoleSerialDriver.CRLF
  ConsoleSerialDriver.str(string("Prompt> "))

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
