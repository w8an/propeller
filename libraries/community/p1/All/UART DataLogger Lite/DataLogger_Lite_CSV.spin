{{
┌───────────────────────────────┬───────────────────┬────────────────────┐
│ DataLogger_Lite_CSV.spin v1.0 │ Author: I.Kövesdi │  Rel.: 12.07.2010  │  
├───────────────────────────────┴───────────────────┴────────────────────┤
│                    Copyright (c) 2010 CompElit Inc.                    │               
│                   See end of file for terms of use.                    │               
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  This application displays an UART driver object for The Memory Stick  │
│ Datalogger. It uses the Parallax Serial Terminal object to send demo   │
│ data to PST. The datalogger driver uses the same standard object for   │
│ its UART, where the buffer size has to be set to 256 byte.             │
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Background and Detail:                                                 │
│                                                                        │
│ - The Vinculum firmware for the VNC1L-1A in the Parallax Memory Stick  │
│ Datalogger (#27937) is pre-compiled as an USB host for thumb drives    │
│ that are formatted in FAT12, FAT16 or FAT32 file systems with a sector │
│ size of 512 bytes. No other file systems, partitions  or sector sizes  │
│ are allowed. It works with drives up to 64G or more.                   │
│                                                                        │
│ - Communication with the firmware monitor can be jumper selected as    │
│ serial UART with handshaking or SPI. This driver is designed for UART. │
│                                                                        │
│ - The driver can operate at standard baud rates from 9600 to 115200    │
│                                                                        │
│ - The DataLogger_Lite_Driver object supports:                          │
│                                                                        │
│                        CSV textfile storage                            │
│                                                                        │
│ - Peak data write speeds were measured:                                │
│                                                                        │ 
│               225 ASCII numbers / sec to CSV textfiles                 │ 
│                                                                        │ 
├────────────────────────────────────────────────────────────────────────┤
│ Note:                                                                  │
│                                                                        │
│ - It is prudent to test and verify different makes and models of disks │
│ before deployment.                                                     │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
}}


CON

_CLKMODE       = XTAL1 + PLL16x
_XINFREQ       = 5_000_000


{
------------------------------Pin assignements----------------------------
Tx on the Propeller must be connected to Rx on the Datalogger, Rx on the
Propeller to Tx on the Datalogger, similarly CTS and RTS also must be
crossed.
}


'            On Propeller                   On Memory Stick Datalogger
'-------------------------------------  ----------------------------------
'Symbol   IOP#          Function        Symbol   Pin       Function
'-------------------------------------------------------------------------
_RNG     = 0 'Out   Ring            -->  RI     8  In   Ring Indicator  
_RTS     = 1 'Out   Request To Send -->  CTS    6  In   Clear To Send 
_RX      = 2 ' In   Receive data    <--  TXD    5 Out   Transmit data 
_TX      = 3 'Out   Transmit data   -->  RXD    4  In   Receive data 
_CTS     = 4 ' In   Clear To Send   <--  RTS    2 Out   Request To Send
_RES     = 5 'Out   Reset           -->  Reset  R  In   Reset VNC1L-1A

{
'            On Propeller                   On Memory Stick Datalogger
'-------------------------------------  ----------------------------------
'Symbol   IOP#          Function        Symbol   Pin       Function
'-------------------------------------------------------------------------
_RNG     = 4 'Out   Ring            -->  RI     8  In   Ring Indicator  
_RTS     = 5 'Out   Request To Send -->  CTS    6  In   Clear To Send 
_RX      = 6 ' In   Receive data    <--  TXD    5 Out   Transmit data 
_TX      = 7 'Out   Transmit data   -->  RXD    4  In   Receive data 
_CTS     = 8 ' In   Clear To Send   <--  RTS    2 Out   Request To Send
_RES     = 9 'Out   Reset           -->  Reset  R  In   Reset VNC1L-1A
}
      
{
-------------------------------Schematics---------------------------------           
        
                 Memory Stick Datalogger

           - - - - - - - - - - - - - - - - - -        

            │                               │
       3V3  │                               │
        │   │                               │ 
        │   │                               │
    10K    │                               │
        │   │                               │
        │   │ ┌───┐                         │ The VNC1L-1A chip is a 3V3 
        ┣───┼─┼• │ R                       │ device and its pins can be
        │   │ ├───┤        Jumpered         │ directly connected to the                                   
        │   │ │ • │ G    to UART mode       │ pins of the Propeller. The                               
        │   │ ├───┤      ┌───┬──────┐       │ inputs of VNC1L-1A are 5V                                 
        │   │ │ • │ P    │ • │      │       │ tolerant, anyway. No need                     
        │   │ └───┘      └───┴──────┘       │ for serial resistors.
        │   │                               │
        │   │   1   2   3   4   5   6   8   │                          
        │   │  VSS RTS VDD RXD TXD CTS  RI  │                        
        │   └───┬───┬───┬───┬───┬───┬───┬───┘                             
        │       │      │                                  
 GND ───┼───────┘   │   │   │   │   │   │
        │           │   │   │   │   │   │                
        │           │   │   │   │   │   │       
  5V ───┼───────────┼───┘   │   │   │   │               P8X32A
(Reg)   │           │       │   │   │   │        ┌────────┬────────┐                        
        │           │       │   │   │   └───RNG─┤P0 |1      40|P31├                              
        │           │       │   │   └───────RTS─┤P1 |2      39|P30├                              
        │           │       │   └────────────RX─┤P2 |3      38|P29├                                         
        │           │       └────────────────TX─┤P3 |4      37|P28├                              
        │           └───────────────────────CTS─┤P4 |5      36|P27├                                                              
        └───────────────────────────────────RES──┤P5 |6      35|P26├  3V3                                     
                                                 ┤P6 |7      34|P25├ (Reg)                                   
                                                 ┤P7 |8      33|P24├   │                        
                                                 ┤VSS|9      32|VDD├───┘
                                                 ┤BOE|10     31| XO├
                                                 ┤RES|11     30| XI├        
                                                 ┤VDD|11     29|VSS├───┐           
                                                 ┤P8 |13     28|P23├   │          
                                                 ┤P9 |14     27|P22├                                               
                                                 ┤P10|15     26|P21├  GND          
                                                 ┤P11|16     25|P20├               
                                                 ┤P12|17     24|P19├ 
                                                 ┤P13|18     23|P18├ 
                                                 ┤P14|19     22|P17├ 
                                                 ┤P15|20     21|P16├ 
                                                 └─────────────────┘
                                           
Note:
-----
This schematics shows only those connections that are used for the
Memory Stick Datalogger in UART mode. For additional connections of the
complete circuit (crystal, etc...) see Propeller documentation. The
presented 'DataLogger_Lite_Driver' v1.0 was prototyped on a Propeller
DemoBoard using the P0,..,P5 IO pins shown  above. On this board the 1st
pin of the Prop chip is denoted as P0.

For the Memory Stick Datalogger find more info at

   ULR = http://www.parallax.com/detail.asp?product_id=27937

Handshake:
----------
- Propeller requests communication with setting its _RTS output (P0) Low.
This line is connected to Datalogger's CTS (Pin 6).
- Vinculum accepts it by setting its RTS output (Pin 2) Low. Propeller
senses it on its _CTS input (P3).
- When the number of data bytes stored in the Vinculum's UART FIFO buffer
reaches an upper threshold, the Memory Stick Datalogger sets its RTS
output High (inactive). This line is checked once by the driver before
sending any command sequence to the datalogger and is tested repeteadly
during block write. However, when this output of the Vinculum goes High
during block data transfer, the chip apparently goes wild. The  simple
minded method I tried in SPIN, e.g.:

                   Stop transmission when RTS goes Lo;
                   Wait Hi on Vinculum RTS patiently;
                   Continue transmission with next byte;
                   Send all remaining data
                            
does not work and I found neither any documentation, nor any working
code about the correct handling of this situation. Maybe the UART's buffer
is not empty and some more bytes are transmitted to Vinculum after its
RTS went down, independently from the stop in the SPIN code. An UART
would be great here with true hardware handshaking. The datalogger driver
regains control by brute force, but as the written data become corrupted,
it signals an error. Here is a place for significant improvement. Any help
is appreciated to make or find a good UART driver with handshaking
}

 
'Data buffer
_DATABUF_SIZE    = DLG#_SECTOR_SIZE


VAR

LONG       nFiles
LONG       ptrFN
LONG       ptrFS
LONG       nDirs
LONG       ptrDN
LONG       ptrDS
LONG       nIDDE
LONG       ptrID

BYTE       dataBuffer[_DATABUF_SIZE]

BYTE       highB 


OBJ

'-------------------------------UART for PST------------------------------
PST        :"Parallax Serial Terminal"   'From Parallax Inc. v1.0

'-----UART driver for Memory Stick Datalogger (Parallax item #27937)------                                        
DLG        :"DataLogger_Lite_Driver"     'From OBEX. v1.0


DAT '------------------------Start of SPIN code---------------------------


PUB Start_Application | cog_ID
'-------------------------------------------------------------------------
'---------------------------┌───────────────────┐-------------------------
'---------------------------│ Start_Application │-------------------------
'---------------------------└───────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: - Starts PST
''             - Calls "Demo" procedure
'' Parameters: None                                 
''    Returns: None
''+Reads/Uses: PST#CS, PST#NL                     (OBJ/CON)
''    +Writes: None                                    
''      Calls: Parallax Serial Terminal----------->PST.Stop
''                                                 PST.Start
''                                                 PST.Char
''                                                 PST.Str
''                                                 PST.Dec
''             Demo
'-------------------------------------------------------------------------
'Start Parallax Serial Terminal for debug. It will launch 1 COG
PST.Stop
cog_ID := PST.Start(57600)

IF (cog_ID == 0)             'No way to send message to the debug terminal
  ABORT                      'since UART hasn't been started
  
WAITCNT(6 * CLKFREQ + CNT)

PST.Char(PST#CS)
PST.Str(STRING("UART to PST started in cog "))
PST.Dec(cog_ID - 1)
PST.Chars(PST#NL, 2) 

WAITCNT(CLKFREQ + CNT)

Demo
'-------------------------------------------------------------------------


PUB Demo | ar, ec, oK, fk, fsize, nB, sl, done, r, fs, i, t, fp, s, pSD_
'-------------------------------------------------------------------------
'----------------------------------┌──────┐-------------------------------
'----------------------------------│ Demo │-------------------------------
'----------------------------------└──────┘-------------------------------
'-------------------------------------------------------------------------
''     Action: Demonstrates basic features of 'DataLogger_UART_Driver'
'' Parameters: None                                 
''    Returns: None                    
''+Reads/Uses: Many                               (CON)               
''             Many                               (OBJ/CON)
''             dataBuffer                         (VAR/BYTE array)
''    +Writes: highB                              (VAR/BYTE)
''      Calls: Many  procedures of 'DataLogger_UART_Driver'
''             Many  procedures of 'Parallax Serial Terminal'
''             DLG.Some_Error
''             Disp_Status_And_Quit
''             QueryChange
''             QueryReboot
''             List_IDD_data
''             List_Dirs
''             List_Files
''             Dump_File
''             Dump_Sector
'-------------------------------------------------------------------------
PST.Str(STRING("Datalogger_Lite_CSV Demo started... "))
PST.Chars(PST#NL, 2)

highB := FALSE

ar := TRUE                               'Autoreset for robust Start-Up
'                                        'Set this FALSE to test Vinculum
                                         'without reset at start. Stable
                                         'drives can be used that way

DLG.Start_Driver(_RX, _TX, _RTS, _CTS, _RNG, _RES, ar) 

PST.Str(STRING("Initialising Datalogger in UART mode... "))
PST.Chars(PST#NL, 2)

WAITCNT(CLKFREQ + CNT)

IF (DLG.Some_Error)
  IF (NOT (DLG.Error_Code == DLG#_NODISK))
    Disp_Status_And_Quit
    RETURN

PST.Str(STRING("Vinculum Monitor responded at baud rate "))
PST.Dec(DLG.Baud_Rate)
WAITCNT(CLKFREQ + CNT)

IF (NOT ar)
  PST.Chars(PST#NL, 4)
  PST.Str(STRING("Reset Monitor Firmware(Y/N)?"))
  PST.Chars(PST#NL, 4) 
  PST.Str(STRING("After Reset or power-on the baudrate is set to 9600,"))
  PST.Char(PST#NL)
  PST.Str(STRING("current directory is changed to root and number of"))
  PST.Char(PST#NL)
  PST.Str(STRING("free sectors has to be counted again when needed."))
  PST.Char(PST#NL)   
  PST.Str(STRING("Otherwise, the monitor continues with settings and"))
  PST.Char(PST#NL)
  PST.Str(STRING("counts from the previous run of the demo. You can try"))
  PST.Char(PST#NL)
  PST.Str(STRING("this by not using the AutoReset option of the Init proc."))
  PST.Char(PST#NL)
  PST.RxFlush
  r := PST.CharIn
  CASE r
    "Y", "y":
      PST.Char(PST#PX)
      PST.Char(0)
      PST.Char(32)
      PST.Char(PST#NL) 
      PST.Str(STRING("Resetting..."))
      PST.Chars(PST#NL, 2)
      DLG.Monitor_Reset
      IF (DLG.Some_Error)
        Disp_Status_And_Quit
        RETURN
    OTHER:

IF (NOT DLG.Disk_Online)
  PST.Char(PST#CS)
  PST.Str(STRING("Online drive was not found..."))
  PST.Chars(PST#NL, 2)
  PST.Str(STRING("Please switch off power before inserting USB Drive."))
  PST.Chars(PST#NL, 2)
  PST.Str(STRING("DataLogger UART Demo terminating..."))
  DLG.Monitor_Suspend
  WAITCNT(CLKFREQ + CNT)                     'To send this last message   
  PST.Stop                                   'Then stop UART
  RETURN

PST.Char(PST#CS) 
PST.Str(STRING("Online drive was found..."))
PST.Chars(PST#NL, 2)
PST.Str(STRING("Please deploy drive that was verified with CHKDSK."))
PST.Chars(PST#NL, 2)
WAITCNT((4 * CLKFREQ) + CNT)

PST.Char(PST#CS)
PST.Str(STRING("Select baud rate of Datalogger:"))
PST.Chars(PST#NL, 2) 
PST.Str(STRING("  1 -----> 115 200"))
IF (DLG.Baud_Rate == 115200)
  PST.Str(STRING(" (Current setting, see note)"))
ELSE
  PST.Str(STRING(" (See note)"))  
PST.Chars(PST#NL, 2)
PST.Str(STRING("  2 ----->  57 600"))
IF (DLG.Baud_Rate == 57600)
  PST.Str(STRING(" (Current setting)"))
PST.Chars(PST#NL, 2)   
PST.Str(STRING("  3 ----->  38 400"))
IF (DLG.Baud_Rate == 38400)
  PST.Str(STRING(" (Current setting)"))
PST.Chars(PST#NL, 2)
PST.Str(STRING("  4 ----->  19 200"))
IF (DLG.Baud_Rate == 19200)
  PST.Str(STRING(" (Current setting)"))
PST.Chars(PST#NL, 2)
PST.Str(STRING("  5 ----->   9 600"))
IF (DLG.Baud_Rate == 9600)
  PST.Str(STRING(" (Current setting)"))
PST.Chars(PST#NL, 2)
PST.Str(STRING("OTHER --->  57 600"))
  
PST.Chars(PST#NL, 4)
PST.Str(STRING("Some CSV operations involve random acces reads"))
PST.Char(PST#NL)
PST.Str(STRING("and those may not work at 115 Kbaud with some"))
PST.Char(PST#NL)
PST.Str(STRING("slower, almost full or fragmented thumb drives."))
PST.Chars(PST#NL, 2) 

PST.RxFlush
r := PST.CharIn
CASE r
  "1":DLG.Monitor_BaudRate(115200)
  "2":DLG.Monitor_BaudRate(57600)
  "3":DLG.Monitor_BaudRate(38400)
  "4":DLG.Monitor_BaudRate(19200)
  "5":DLG.Monitor_BaudRate(9600)
  OTHER:DLG.Monitor_BaudRate(57600)

PST.Char(PST#CS) 
PST.Str(STRING("Setting baud rate "))
PST.Dec(DLG.Baud_Rate)
PST.Chars(PST#NL, 2)
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN

PST.Str(STRING("Reading drive identification data... "))
PST.Chars(PST#NL, 2)  
DLG.Disk_IDDE(@nIDDE, @ptrID)
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
List_IDD_Data
WAITCNT(CLKFREQ + CNT)

PST.Str(STRING("Changing to root directory... "))
PST.Chars(PST#NL, 2)
DLG.Dir_Set_To_Root
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN

'Read file and dirrectory names on USB drive
PST.Str(STRING("Reading directory and filenames... "))
PST.Chars(PST#NL, 2)
DLG.Dir_List(@nFiles, @ptrFN, @nDirs, @ptrDN)
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
List_Dirs 
List_Files
WAITCNT(CLKFREQ + CNT)

PST.Str(STRING("Querying free space on drive..."))
PST.Chars(PST#NL, 2)
PST.Str(STRING("First free sector count on large capacity drives"))
PST.Char(PST#NL)
PST.Str(STRING("can take quite a few seconds. Please wait...")) 
PST.Chars(PST#NL, 2)
DLG.Disk_Free_K(@fk)
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
PST.Str(STRING("Free space = "))
PST.Dec(fk) 
PST.Str(STRING(" KBytes"))
PST.Chars(PST#NL, 2)

QueryChange

'{CSV TEXTLINE CODE BLOCK Selector Line. ON / OFF with 1st '<-------------
'=========================================================================
PST.Char(PST#CS)
PST.Str(STRING("CSV Textfile Demo... "))
PST.Chars(PST#NL, 2)

Query57Kbaud

PST.Char(PST#CS)
PST.Str(STRING("SPEED TEST: Appending Lines to CSV File..."))
PST.Chars(PST#NL, 2)

PST.Str(STRING("This test goes with appending 20 ASCII format numbers"))
PST.Char(PST#NL)
PST.Str(STRING("in 3 lines repeateadly using FAT filesystem operations"))
PST.Chars(PST#NL, 2) 

DLG.File_Close(STRING("CSVTEST.CSV"))
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
DLG.File_Delete(STRING("CSVTEST.CSV"))  
DLG.File_Open_For_Write(STRING("CSVTEST.CSV"))  
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
i~  
t := CNT
REPEAT 20       '"Collect" 400 datapoints into 60 lines
  DLG.Line_New
  DLG.Line_Append_Int(++i)
  DLG.Line_Append_Int(1)
  DLG.Line_Append_Int(-12)
  DLG.Line_Append_Int(123) 
  DLG.Line_Append_Int(-1234) 
  DLG.Line_Append_Int(12345)
  DLG.Line_Append_Int(-654321)
  DLG.Line_WriteCRLF
  IF (DLG.Some_Error)
    Disp_Status_And_Quit
    RETURN
 
  DLG.Line_New
  DLG.Line_Append_Int(++i)
  DLG.Line_Append_Int(DLG.StrToInt(STRING("-1234")))   
  DLG.Line_Append_Int(DLG.StrToInt(STRING("+1233")))   
  DLG.Line_Append_Int(DLG.StrToInt(STRING("1239")))
  DLG.Line_Append_Int(DLG.StrToInt(STRING("-987")))
  DLG.Line_Append_Int(DLG.StrToInt(STRING("9876.54")))
  DLG.Line_Append_Int(DLG.StrToInt(STRING("2010")))
  DLG.Line_WriteCRLF
  IF (DLG.Some_Error)
    Disp_Status_And_Quit
    RETURN

  DLG.Line_New
  DLG.Line_Append_Int(++i)
  DLG.Line_Append_Int(-2009) 
  DLG.Line_Append_Qval(DLG.StrToQval(STRING("-234.997"))) 
  DLG.Line_Append_Qval(DLG.StrToQval(STRING("+123.345")))
  DLG.Line_Append_Qval(DLG.StrToQval(STRING("654.321")))
  DLG.Line_Append_Qval(DLG.StrToQval(STRING("-1.2")))  
  DLG.Line_WriteCRLF
  IF (DLG.Some_Error)
    Disp_Status_And_Quit
    RETURN

DLG.File_Close(STRING("CSVTEST.CSV"))
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN

t := CNT - t
t := (CLKFREQ / (t / 400 ))        

PST.Str(STRING("The CSV textfile looks like..."))     
PST.Chars(PST#NL, 2)
WAITCNT((2 * CLKFREQ) + CNT)
Dump_File(STRING("CSVTEST.CSV"))
    
PST.Str(STRING("CSV Data Write speed is about "))
PST.Dec(t)
PST.Str(STRING(" ASCII form numbers/sec at baud "))
PST.Dec(DLG.Baud_Rate)
PST.Chars(PST#NL, 2)
WAITCNT((2 * CLKFREQ) + CNT)

PST.Char(PST#NL)
PST.Str(STRING("Reading 5 lines from line 44..."))       
PST.Chars(PST#NL, 2)
DLG.Line_Seek(STRING("CSVTEST.CSV"), 44)      'Seek 44th line
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
REPEAT 5   
  DLG.Line_Read(@dataBuffer)
  IF (DLG.Some_Error)
    Disp_Status_And_Quit
    RETURN  
  PST.Str(@dataBuffer)
  
PST.Char(PST#NL) 
PST.Str(STRING("Random Acces Reading data back from this file..."))
PST.Chars(PST#NL, 2)

DLG.Line_Seek(STRING("CSVTEST.CSV"), 60)         'Seek 60. line
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
DLG.Line_Read(@dataBuffer)                       'Read CSV textline
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
r :=  DLG.Value_Read(3, DLG#_QVAL, @dataBuffer)  'Read 3rd Qvalue in line
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
PST.Str(STRING("3rd data in line 60 = "))
PST.Str(DLG.QvalToStr(r))
PST.Char(PST#NL)

DLG.Line_Seek(STRING("CSVTEST.CSV"), 14)         'Seek 14th line
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
DLG.Line_Read(@dataBuffer)                       'Read CSV textline
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
r :=  DLG.Value_Read(3, DLG#_LONG, @dataBuffer)  'Read 3rd LONG value in line
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN                           
PST.Str(STRING("3rd data in line 14 = "))                     
PST.Dec(r)
PST.Char(PST#NL) 

DLG.Line_Seek(STRING("CSVTEST.CSV"), 57)         
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
DLG.Line_Read(@dataBuffer)                       
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
r :=  DLG.Value_Read(2, DLG#_LONG, @dataBuffer)  
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
PST.Str(STRING("2nd data in line 57 = "))  
PST.Str(DLG.IntToStr(r))
PST.Char(PST#NL)

DLG.Line_Seek(STRING("CSVTEST.CSV"), 56)      
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
DLG.Line_Read(@dataBuffer)                 
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
r :=  DLG.Value_Read(7, DLG#_LONG, @dataBuffer) 
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
PST.Str(STRING("7th data in line 56 = ")) 
PST.Dec(r)
PST.Char(PST#NL)

DLG.File_Close(STRING("CSVTEST.CSV"))
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
DLG.File_Delete(STRING("CSVTEST.CSV"))   

QueryReboot
'}'END OF CSV TEXTLINE CODE BLOCK-----------------------------------------



'Terminating demo application---------------------------------------------
PST.Char(PST#CS)
PST.Str(STRING("Terminating DataLogger UART Lite Demo... "))
PST.Chars(PST#NL, 2)

'Read file and dirrectory names on USB drive
PST.Str(STRING("Here is the content of your drive... "))
PST.Chars(PST#NL, 2)

DLG.Dir_List(@nFiles, @ptrFN, @nDirs, @ptrDN)
IF (DLG.Some_Error)
  Disp_Status_And_Quit
  RETURN
List_Dirs 
List_Files

PST.Str(STRING("Seting baud rate to default 9600... "))
PST.Chars(PST#NL, 2)
DLG.Monitor_BaudRate(9600) 

PST.Str(STRING("Suspending monitor... "))
PST.Chars(PST#NL, 2)
DLG.Monitor_Suspend
    
PST.Str(STRING("Please switch off power before removing USB drive."))
PST.Chars(PST#NL, 2)

PST.Str(STRING("DataLogger UART demo terminated normaly..."))
WAITCNT(CLKFREQ + CNT)                     'Time send the last message   
PST.Stop                                   'Then stop UART
'-------------------------------------------------------------------------


PUB Disp_Status_And_Quit
'-------------------------------------------------------------------------
'-------------------------┌─────────────────────┐-------------------------
'-------------------------│ Disp_Status_And_Quit│-------------------------
'-------------------------└─────────────────────┘-------------------------
'-------------------------------------------------------------------------
''     Action: - Displays status and error messages
''             - Terminates application
'' Parameters: None                                 
''    Returns: None                    
''+Reads/Uses: PST#NL                   
''    +Writes: None                                    
''      Calls: Parallax Serial Terminal----------->PST.Char
''                                                 PST.Str
''                                                 PST.Chars
''                                                 PST.Stop
'------------------------------------------------------------------------- 
PST.Char(PST#NL)
PST.Str(STRING("Status : "))
PST.Str(LONG[DLG.Status_Message])
PST.Char(PST#NL)
PST.Str(STRING(" Error : "))
PST.Str(LONG[DLG.Error_Message])
PST.Chars(PST#NL, 2)
IF (DLG.Error_Code == DLG#_BLOCKED)
  PST.Str(STRING("Please, decrease baud rate."))
  PST.Chars(PST#NL, 2)
WAITCNT(4 * CLKFREQ + CNT)
PST.Str(STRING("Datalogger_UART_Demo terminated with some ERROR..."))
WAITCNT(CLKFREQ + CNT)   
PST.Stop
'-------------------------------------------------------------------------


PUB List_IDD_Data | i
'-------------------------------------------------------------------------
'------------------------------┌───────────────┐--------------------------
'------------------------------│ List_IDD_Data │--------------------------
'------------------------------└───────────────┘--------------------------
'-------------------------------------------------------------------------
''     Action: Lists  Identify Disk Drive (Extended) results on PST
'' Parameters: None                                 
''    Returns: None                    
''+Reads/Uses: nIDDE                              (VAR/LONG)  
''             ptrID                              (VAR/LONG)
''             PST#NL                             (OBJ/CON)
''    +Writes: None                                    
''      Calls: "Parallax Serial Terminal"--------->PST.Str
''                                                 PST.Char
'-------------------------------------------------------------------------
IF (nIDDE>0)
  PST.Str(STRING("Drive data:"))
  PST.Char(PST#NL)
  i~    
  REPEAT nIDDE
    PST.Str(LONG[ptrID][i++])
    PST.Char(PST#NL)
ELSE
  IF (nIDDE == 0)
    PST.Str(STRING("No IDDE Data Loaded"))
    PST.Char(PST#NL)
PST.Char(PST#NL)
'-------------------------------------------------------------------------


PUB List_Dirs | i
'-------------------------------------------------------------------------
'-------------------------------┌───────────┐-----------------------------
'-------------------------------│ List_Dirs │-----------------------------
'-------------------------------└───────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Lists directories in current directory
'' Parameters: None                                 
''    Returns: None                    
''+Reads/Uses: nDirs                              (VAR/LONG)  
''             ptrDN                              (VAR/LONG array)
''             PST#NL                             (OBJ/CON)
''    +Writes: None                                    
''      Calls: Parallax Serial Terminal----------->PST.Str
''                                                 PST.Dec
''                                                 PST.Char
''       Note: Assumes Dir_List was performed right before to fill arrays
'------------------------------------------------------------------------- 
IF (nDirs>0)
  PST.Str(STRING("Dirs("))
  PST.Dec(nDirs)
  PST.Str(STRING("):"))
  PST.Char(PST#NL)
  i~    
  REPEAT nDirs
    PST.Str(LONG[ptrDN][i++])
    PST.Char(PST#NL)
ELSE
  IF (nDirs == 0)
    PST.Str(STRING("No Subdirectories."))
    PST.Char(PST#NL)
  ELSE
    PST.Str(STRING("Too Many Directory Items!"))
    PST.Char(PST#NL)      
PST.Char(PST#NL)
'-------------------------------------------------------------------------


PUB List_Files | i
'-------------------------------------------------------------------------
'------------------------------┌────────────┐-----------------------------
'------------------------------│ List_Files │-----------------------------
'------------------------------└────────────┘-----------------------------
'-------------------------------------------------------------------------
''     Action: Lists files in current directory
'' Parameters: None                                 
''    Returns: None                    
''+Reads/Uses: nFiles                             (VAR/LONG)  
''             ptrFN                              (VAR/LONG array)
''             PST#NL                             (OBJ/CON)
''    +Writes: None                                    
''      Calls: Parallax Serial Terminal----------->PST.Str
''                                                 PST.Dec
''                                                 PST.Char
''       Note: Assumes Dir_List was performed just before to fill arrays
'-------------------------------------------------------------------------
IF (nFiles>0)
  PST.Str(STRING("Files("))
  PST.Dec(nFiles)
  PST.Str(STRING("):"))
  PST.Char(PST#NL)
  i~    
  REPEAT nFiles
    PST.Str(LONG[ptrFN][i++])
    PST.Char(PST#NL)
ELSE
  IF (nDirs == 0)
    PST.Str(STRING("No Files."))
    PST.Char(PST#NL)
  ELSE
    PST.Str(STRING("Too Many Directory Items!"))
    PST.Char(PST#NL) 
PST.Char(PST#NL)
'-------------------------------------------------------------------------


PUB Dump_File(ptrFilename_) : yesNo | fSize, done, bdn, nrb, p
'-------------------------------------------------------------------------
'------------------------------┌───────────┐------------------------------
'------------------------------│ Dump_File │------------------------------
'------------------------------└───────────┘------------------------------
'-------------------------------------------------------------------------
''     Action: Dumps file to PST
'' Parameters: Pointer to file name                                 
''    Returns: TRUE if action successful, else FALSE                
''+Reads/Uses: _DATABUF_SIZE                      (CON)
''             PST#NL                             (OBJ/CON) 
''    +Writes: dataBuffer                         (VAR/BYTE array)                                    
''      Calls: Disp_Status_And_Quit
''             File_Size   
''             Parallax Serial Terminal------>PST.Str
''                                            PST.Dec
''                                            PST.Char
''             DataLogger_UART_Driver-------->DLG.File_Size
''                                            DLG.File_Random_Access_Read
''       Note: NL, <Bytes of file>, NL, NL is sent to the terminal
'-------------------------------------------------------------------------
'Gets file size
yesNo := DLG.File_Size(ptrFilename_, @fSize)
IF (NOT yesNO)
  Disp_Status_And_Quit
  RETURN
  
'Start transmission
PST.Str(ptrFileName_)
PST.Str(STRING("("))
PST.Dec(fSize)
PST.Str(STRING(" bytes):"))
PST.Char(PST#NL)

'Read and send file
IF (fSize > 0)
  done := FALSE
  bdn~                                   'BytesDone is zero 
  REPEAT UNTIL done                    
    IF (bdn < fSize)
      'Read next chunk of data----------------------------------------------
      IF ((bdn + _DATABUF_SIZE) > fSize)  'Last block follows
        nrb := fSize - bdn                   
      ELSE                                'Next full block
        nrb := _DATABUF_SIZE 

      yesNo := DLG.File_Random_Access_Read(ptrFilename_,bdn,nrb,@dataBuffer)

      IF (DLG.Some_Error)
        Disp_Status_And_Quit
        RETURN

      'Send bytes in buffer to terminal
      p~
      REPEAT nrb
        PST.Char(dataBuffer[p++])
      bdn += nrb                         'ByteDone+=NumberofReadBytes
      IF (bdn => fSize)                     
        done := TRUE                     'Job done

PST.Chars(PST#NL, 2)  
'-------------------------------------------------------------------------

{
PUB Dump_Sector(sectNumber) : yesNo | pD_, i, j, p, b
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ Dump_Sector │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Dumps sector data to PST
'' Parameters: Sector number                                 
''    Returns: TRUE if action successful, else FALSE                
''+Reads/Uses: None
''    +Writes: None                                    
''      Calls: Parallax Serial Terminal----------->PST.Str
''                                                 PST.Dec
''                                                 PST.Hex
''                                                 PST.Char
''             DataLogger_UART_Driver------------->DLG.Sector_Read 
''             Disp_Status_And_Quit
'-------------------------------------------------------------------------
yesNo := DLG.Sector_Read(sectNumber, @pD_)
IF (NOT yesNO)
  Disp_Status_And_Quit
  RETURN

PST.Str(STRING("Sector="))
PST.Dec(sectNumber) 
PST.Str(STRING(" (Addr.:$"))
PST.Hex(sectNumber * DLG#_SECTOR_SIZE, 8)
PST.Str(STRING("-$"))
PST.Hex((sectNumber * DLG#_SECTOR_SIZE) + DLG#_SECTOR_SIZE, 8)
PST.Str(STRING("):"))
PST.Char(PST#NL)
REPEAT i FROM 0 TO 31
  REPEAT j FROM 0 TO 15
    p := (i * 16) + j 
    b := BYTE[pD_ + p]
    PST.Hex(b, 2)
    PST.Char(" ")
  PST.Str(STRING("| "))
  REPEAT j FROM 0 TO 15
    p := (i * 16) + j 
    b := BYTE[pD_ + p]
    IF ((b > 27) AND (b < 128))
      PST.Char(b)
    ELSE  
      PST.Char(".")  
  PST.Char(PST#NL)   
'-------------------------------------------------------------------------
}

PRI QueryChange | done, r
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ QueryChange │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Queries for a drive change
'' Parameters: None                                
''    Returns: None                
''+Reads/Uses: PST#NL, PST#CS                     (OBJ/CON)
''    +Writes: None                                    
''      Calls: "Parallax Serial Terminal"--------->PST.Str
''                                                 PST.Char
''                                                 PST.RxFlush
''                                                 PST.CharIn
''             DataLogger_UART_Driver------------->DLG.Monitor_Suspend
'------------------------------------------------------------------------
PST.Str(STRING("[C]hange drive or press any other key to continue..."))
PST.Char(PST#NL)
done := FALSE
REPEAT UNTIL done
  PST.RxFlush
  r := PST.CharIn
  IF ((r == "C") or (r == "c"))
    PST.Char(PST#CS)
    PST.Str(STRING("Please switch off power before changing drive."))
    PST.Chars(PST#NL, 2)
    PST.Str(STRING("DataLogger UART Demo terminating..."))
    DLG.Monitor_Suspend
    WAITCNT(CLKFREQ + CNT)                     'To send this last message   
    PST.Stop                                   'Then stop UART
    RETURN
  ELSE
    done := TRUE
'-------------------------------------------------------------------------


PRI QueryReboot | done, r
'-------------------------------------------------------------------------
'------------------------------┌─────────────┐----------------------------
'------------------------------│ QueryReboot │----------------------------
'------------------------------└─────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Asks to reboot
'' Parameters: None                                
''    Returns: None                
''+Reads/Uses: PST#NL, PST#PX                     (OBJ/CON)
''             highB                              (VAR/BYTE)
''    +Writes: None                                    
''      Calls: "Parallax Serial Terminal"--------->PST.Str
''                                                 PST.Char
''                                                 PST.Chars 
''                                                 PST.RxFlush
''                                                 PST.CharIn
''             DataLogger_UART_Driver------------->DLG.Monitor_BaudRate
'------------------------------------------------------------------------
PST.Char(PST#NL)
IF highB
  PST.Str(STRING("Resetting 115 Kbaud...")) 
  DLG.Monitor_BaudRate(115200)
  PST.Str(STRING("Done"))
  PST.Chars(PST#NL, 2)
  highB := FALSE 
PST.Str(STRING("[R]eboot or press any other key to continue..."))
PST.Char(PST#NL)
done := FALSE
REPEAT UNTIL done
  PST.RxFlush
  r := PST.CharIn
  IF ((r == "R") OR (r == "r"))
    PST.Char(PST#PX)
    PST.Char(0)
    PST.Char(32)
    PST.Char(PST#NL) 
    PST.Str(STRING("Rebooting..."))
    WAITCNT((CLKFREQ / 10) + CNT) 
    REBOOT
  ELSE
    done := TRUE
'-------------------------------------------------------------------------


PRI Query57Kbaud | done, r
'-------------------------------------------------------------------------
'-----------------------------┌──────────────┐----------------------------
'-----------------------------│ Query57Kbaud │----------------------------
'-----------------------------└──────────────┘----------------------------
'-------------------------------------------------------------------------
''     Action: Asks to switch back to 57K from 115K
'' Parameters: None                                
''    Returns: None                
''+Reads/Uses: PST#NL, PST#PX                     (OBJ/CON)
''    +Writes: highB                              (VAR/BYTE)      
''      Calls: Parallax Serial Terminal----------->PST.Str
''                                                 PST.Char
''                                                 PST.RxFlush
''                                                 PST.CharIn
''             DataLogger_UART_Driver------------->DLG.Monitor_BaudRate
''                                                 DLG.Baud_Rate
'-------------------------------------------------------------------------
IF (NOT (DLG.Baud_Rate == 115200))
  RETURN
PST.Str(STRING("Might not work at 115 Kbaud with some drives"))
PST.Chars(PST#NL, 2)  
PST.Str(STRING("[S]et 57 Kbaud or any other key to continue..."))
PST.Char(PST#NL)
done := FALSE
REPEAT UNTIL done
  PST.RxFlush
  r := PST.CharIn
  IF ((r == "S") OR (r == "s"))
    PST.Char(PST#PX)
    PST.Char(0)
    PST.Char(32)
    PST.Char(PST#NL) 
    PST.Str(STRING("Setting 57 Kbaud...")) 
    DLG.Monitor_BaudRate(57600)
    PST.Str(STRING("Done"))
    PST.Chars(PST#NL, 2)     
    highB :=TRUE
    done := TRUE
  ELSE
    done := TRUE
'-------------------------------------------------------------------------


PRI UCASE(pStr_) | l, p, c
'-------------------------------------------------------------------------
'---------------------------------┌───────┐-------------------------------
'---------------------------------│ UCASE │-------------------------------
'---------------------------------└───────┘-------------------------------
'-------------------------------------------------------------------------
'     Action: Converts string in-place into uppercase
' Parameters: Pointer to string                                
'    Returns: Pointer to string (same)         
'+Reads/Uses: None                   
'    +Writes: None                                    
'      Calls: None
'-------------------------------------------------------------------------
l := STRSIZE(pStr_)
IF (l > 0)
  p := pStr_
  REPEAT l               
    IF (BYTE[p] => "a") AND (BYTE[p] =< "z")            
      BYTE[p] -= 32                                    '"A" = "a" - 32
    p++
RESULT := pStr_
'-------------------------------------------------------------------------
    

DAT '-----------------------------DAT section-----------------------------


strQBF     BYTE "The quick brown fox jumps over the lazy dog. ", 0


DAT '-----------------------------MIT License-----------------------------


{{
┌────────────────────────────────────────────────────────────────────────┐
│                        TERMS OF USE: MIT License                       │                                                            
├────────────────────────────────────────────────────────────────────────┤
│  Permission is hereby granted, free of charge, to any person obtaining │
│ a copy of this software and associated documentation files (the        │ 
│ "Software"), to deal in the Software without restriction, including    │
│ without limitation the rights to use, copy, modify, merge, publish,    │
│ distribute, sublicense, and/or sell copies of the Software, and to     │
│ permit persons to whom the Software is furnished to do so, subject to  │
│ the following conditions:                                              │
│                                                                        │
│  The above copyright notice and this permission notice shall be        │
│ included in all copies or substantial portions of the Software.        │  
│                                                                        │
│  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND        │
│ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     │
│ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. │
│ IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   │
│ CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   │
│ TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      │
│ SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 │
└────────────────────────────────────────────────────────────────────────┘
}}