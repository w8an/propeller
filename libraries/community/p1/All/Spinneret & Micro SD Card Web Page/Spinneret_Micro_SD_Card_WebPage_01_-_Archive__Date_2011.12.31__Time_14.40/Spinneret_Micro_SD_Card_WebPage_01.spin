'  Spinneret_Micro_SD_Card_WebPage_01.spin
'  Version 0.1
'  Compiled by Greg Denson, December, 2011
'  Copyright, 2011, Greg Denson
'  See MIT License at bottom of document for Terms of Use.
'
'  This demonstration program is built on the work of: 
'  Timothy D. Swieter, P.E. - as edited by Chris Cantrell
'  It also uses, and is built on the SD Card Object by Tomas Rokicki and Jonathan Dummer
'
'  I was having some trouble in figuring out how to store a web page on my Micro SD card, and then
'  retrieve and display the page from the card, when accessing the Spinneret web server.  So, after
'  spending a lot of time figuring it out, I thought there might be a lot of other beginning Spinneret
'  users that would like to have a little bit of a head start on getting this working.
'
'  This is a very, very simple demonstration of how to store your web page HTML on the SD card, and call
'  it up when you access the Spinneret web page.  Of course, in my testing, the server and client are
'  both on my home network.
'
'  So, if you want something more complex, you will have a bit of work to do on your own.  However, I hope you
'  will enjoy this as a starting point for learning how to use the Micro SD Card with your Spinneret.
'
'  I am planning to include, with the downloads for this object, the very small HTML web page file that I used
'  for testing this demo program.  If you want to use it, please do so.  Just save it on your Micro SD card
'  and insert the SD card into the Spinneret before running this demo.
'
'  Much thanks to Timothy, and Chris for their excellent work, none of which I would have figured out on my
'  in for years to come.
'
'  In addtion, much thanks to Tomas Rokicki and Jonathan Dummer for their fine 'fsrw' Object which I used to
'  pull together this Spinneret - SD Card demo.
'

CON               
  FWmajor       = 0
  FWminor       = 2

DAT
  TxtFWdate   byte "December 31, 2011",0
  
CON
  _clkmode = xtal1 + pll16x     'Use the PLL to multiple the external clock by 16
  _xinfreq = 5_000_000          'An external clock of 5MHz. is used (80MHz. operation)

  _OUTPUT       = 1             'Sets pin to output in DIRA register
  _INPUT        = 0             'Sets pin to input in DIRA register  
  _HIGH         = 1             'High=ON=1=3.3V DC
  _ON           = 1
  _LOW          = 0             'Low=OFF=0=0V DC
  _OFF          = 0
  _ENABLE       = 1             'Enable (turn on) function/mode
  _DISABLE      = 0             'Disable (turn off) function/mode

{
  '~~~~Propeller Based I/O~~~~
  'W5100 Module Interface
  _WIZ_data0    = 0             'SPI Mode = MISO, Indirect Mode = data bit 0.
  _WIZ_miso     = 0
  _WIZ_data1    = 1             'SPI Mode = MOSI, Indirect Mode = data bit 1.
  _WIZ_mosi     = 1
  _WIZ_data2    = 2             'SPI Mode unused, Indirect Mode = data bit 2 dependent on solder jumper on board.
  _WIZ_data3    = 3             'SPI Mode = SCLK, Indirect Mode = data bit 3.
  _WIZ_sclk     = 3
  _WIZ_data4    = 4             'SPI Mode unused, Indirect Mode = data bit 4 dependent on solder jumper on board.
  _WIZ_data5    = 5             'SPI Mode unused, Indirect Mode = data bit 5 dependent on solder jumper on board.
  _WIZ_data6    = 6             'SPI Mode unused, Indirect Mode = data bit 6 dependent on solder jumper on board.
  _WIZ_data7    = 7             'SPI Mode unused, Indirect Mode = data bit 7 dependent on solder jumper on board.
  _WIZ_addr0    = 8             'SPI Mode unused, Indirect Mode = address bit 0 dependent on solder jumper on board.
  _WIZ_addr1    = 9             'SPI Mode unused, Indirect Mode = address bit 1 dependent on solder jumper on board.
  _WIZ_wr       = 10            'SPI Mode unused, Indirect Mode = /write dependent on solder jumper on board.
  _WIZ_rd       = 11            'SPI Mode unused, Indirect Mode = /read dependent on solder jumper on board.
  _WIZ_cs       = 12            'SPI Mode unused, Indirect Mode = /chip select dependent on solder jumper on board.
  _WIZ_int      = 13            'W5100 /interrupt dependent on solder jumper on board.  Shared with _OW.
  _WIZ_rst      = 14            'W5100 chip reset.
  _WIZ_scs      = 15            'SPI Mode SPI Slave Select, Indirect Mode unused dependent on solder jumper on board.

  'I2C Interface
  _I2C_scl      = 28            'Output for the I2C serial clock
  _I2C_sda      = 29            'Input/output for the I2C serial data  

  'Serial/Programming Interface (via Prop Plug Header)
  _SERIAL_tx    = 30            'Output for sending misc. serial communications via a Prop Plug
  _SERIAL_rx    = 31            'Input for receiving misc. serial communications via a Prop Plug
}
  '~~~~Propeller Based I/O~~~~
  'W5100 Module Interface
  _WIZ_data0    = 0             'SPI Mode = MISO, Indirect Mode = data bit 0.
  _WIZ_miso     = 0
  _WIZ_data1    = 1             'SPI Mode = MOSI, Indirect Mode = data bit 1.
  _WIZ_mosi     = 1
  _WIZ_data2    = 2             'SPI Mode SPI Slave Select, Indirect Mode = data bit 2
  _WIZ_scs      = 2             
  _WIZ_data3    = 3             'SPI Mode = SCLK, Indirect Mode = data bit 3.
  _WIZ_sclk     = 3
  _WIZ_data4    = 4             'SPI Mode unused, Indirect Mode = data bit 4 
  _WIZ_data5    = 5             'SPI Mode unused, Indirect Mode = data bit 5 
  _WIZ_data6    = 6             'SPI Mode unused, Indirect Mode = data bit 6 
  _WIZ_data7    = 7             'SPI Mode unused, Indirect Mode = data bit 7 
  _WIZ_addr0    = 8             'SPI Mode unused, Indirect Mode = address bit 0 
  _WIZ_addr1    = 9             'SPI Mode unused, Indirect Mode = address bit 1 
  _WIZ_wr       = 10            'SPI Mode unused, Indirect Mode = /write 
  _WIZ_rd       = 11            'SPI Mode unused, Indirect Mode = /read 
  _WIZ_cs       = 12            'SPI Mode unused, Indirect Mode = /chip select 
  _WIZ_int      = 13            'W5100 /interrupt
  _WIZ_rst      = 14            'W5100 chip reset
  _WIZ_sen      = 15            'W5100 low = indirect mode, high = SPI mode, floating will = high.

  DO            = 16           'DATA OUT             I made some changes, here on these four pins, from the original program.
  CS            = 19           'CHIP SELECT          Wanted to keep the same pins I had used previously
  DI            = 20           'DATA IN              in the Micro SD Card demo that I had on hand.
  CLK           = 21           'CLOCK                As you can see, Pins 17 & 18, are not mentioned in this list,
                               '                     but are available for use with the SD card if needed.
  _SIO          = 22            

  _LED          = 23            'UI - combo LED and buttuon
  
  _AUX0         = 24            'MOBO Interface
  _AUX1         = 25
  _AUX2         = 26
  _AUX3         = 27

  'I2C Interface
  _I2C_scl      = 28            'Output for the I2C serial clock
  _I2C_sda      = 29            'Input/output for the I2C serial data  

  'Serial/Programming Interface (via Prop Plug Header)
  _SERIAL_tx    = 30            'Output for sending misc. serial communications via a Prop Plug
  _SERIAL_rx    = 31            'Input for receiving misc. serial communications via a Prop Plug

  _EEPROM0_address = $A0        'Slave address of EEPROM

  _bytebuffersize = 2048

VAR 

  'Configuration variables for the W5100
  byte  MAC[6]                  '6 element array contianing MAC or source hardware address ex. "02:00:00:01:23:45"
  byte  Gateway[4]              '4 element array containing gateway address ex. "192.168.0.1"
  byte  Subnet[4]               '4 element array contianing subnet mask ex. "255.255.255.0"
  byte  IP[4]                   '4 element array containing IP address ex. "192.168.0.13"

  'verify variables for the W5100
  byte  vMAC[6]                 '6 element array contianing MAC or source hardware address ex. "02:00:00:01:23:45"
  byte  vGateway[4]             '4 element array containing gateway address ex. "192.168.0.1"
  byte  vSubnet[4]              '4 element array contianing subnet mask ex. "255.255.255.0"
  byte  vIP[4]                  '4 element array containing IP address ex. "192.168.0.13"

  long  localSocket             '1 element for the socket number

  'Variables to info for where to return the data to
  byte  destIP[4]               '4 element array containing IP address ex. "192.168.0.16"
  long  destSocket              '1 element for the socket number

  'Misc variables
  byte  data[_bytebuffersize]
  long  stack[50]

  long  PageCount  

  byte TEXT[256]                'I added this buffer to hold web page text from the Micro SD Card
  

OBJ            

  ETHERNET      : "W5100_Indirect_Driver.spin" ' Driver as named in the repository

  'The serial terminal to use  
  PST           : "Parallax Serial Terminal.spin"       'A terminal object created by Parallax, used for debugging

  'Utility
  STR           :"STREngine.spin"                       'A string processing utility

  'SD Card
  sdfat : "fsrw"                       ' Download the fswr.spin object from the Parallax Propeller Object Exchange (OBEX), accessed from parallax.com  
                                       ' I added this object to bring in the SD Card functionality that is needed.
                                       
PUB main | temp0, temp1, temp2, readSize, insert_card, filesz    'I added the 'insert_card', and 'filesz' variables to help with the card functionality, too.

  PauseMSec(2_000)              'A small delay to allow time to switch to the terminal application after loading the device

  PST.Start(115_200)            'Start Serial Terminal 

  'Start the W5100 driver
  ETHERNET.StartINDIRECT(_WIZ_data0, _WIZ_addr0, _WIZ_addr1, _WIZ_cs, _WIZ_rd, _WIZ_wr,  _WIZ_rst, _WIZ_sen)


  'MAC Address to be assigned to W5100
  MAC[0] := $00                  'You need to change these to match the MAC Address on your Spinneret card.
  MAC[1] := $08                  'See the white label on the "Spider" side of the card.
  MAC[2] := $DC
  MAC[3] := $16
  MAC[4] := $F3
  MAC[5] := $5B

  'Subnet address to be assigned to W5100
  Subnet[0] := 255                 'Also make changes to match your subnet mask for your network.
  Subnet[1] := 255
  Subnet[2] := 255
  Subnet[3] := 0

  'IP address to be assigned to W5100
  IP[0] := 192                     'And this should be the IPv4 address for your Spinneret card on your network.
  IP[1] := 168                     'You are assigning that address here, so avoid conflicts with other devices
  IP[2] := 0                       'on your network.
  IP[3] := 240  

  'Gateway address of the system network.
  'I left these commented out because I never got the program to work correctly if i provided my gateway address.  
  'Gateway[0] := 192
  'Gateway[1] := 168
  'Gateway[2] := 0
  'Gateway[3] := 1

  'Local socket
  localSocket := 80            

  'Destination IP address - can be left zeros, the TCO demo echoes to computer that sent the packet
  destIP[0] := 0
  destIP[1] := 0
  destIP[2] := 0
  destIP[3] := 0

  destSocket := 80
    

  'Clear the terminal screen
  PST.Home
  PST.Clear

                                                               ' I added these lines to check for proper insertion of the SD card.
                                                               ' You have to have the serial terminal open to read these messages...
  insert_card := \sdfat.mount_explicit(DO, CLK, DI, CS)        ' Here we call the 'mount' method using the 4 pins described in the 'CON' section.
  if insert_card < 0                                           ' If mount returns a zero...
    pst.str(string(13))                                        ' Print a carriage return to get a new line.
    pst.str(string("The Micro SD Card was not found!"))        ' Print the failure message.
    pst.str(string(13))                                        ' Carriage return...
    pst.str(string("Insert card, or check your connections.")) ' Remind user to insert card or check the wiring.
    pst.str(string(13))                                        ' And yet another carriage return.
    abort                                                      ' Then we abort the program.
        
  
  pst.str(string(13))
  pst.str(string("Micro SD card was found!"))                  ' Let the user know the card is properly inserted.
  pst.str(string(13))

     
  'Draw the title bar
  PST.Str(string("    Prop/W5100 Web Page Serving Test ", PST#NL, PST#NL))

  'Set the W5100 addresses
  PST.Str(string("Initialize all addresses...  ", PST#NL))  
  SetVerifyMAC(@MAC[0])
  SetVerifyGateway(@Gateway[0])
  SetVerifySubnet(@Subnet[0])
  SetVerifyIP(@IP[0])

  'Addresses should now be set and displayed in the terminal window.
  'Next initialize Socket 0 for being the TCP server

  PST.Str(string("Initialize socket 0, port "))
  PST.dec(localSocket)
  PST.Str(string(PST#NL))

  'Testing Socket 0's status register and display information
  PST.Str(string("Socket 0 Status Register: "))
  ETHERNET.readIND(ETHERNET#_S0_SR, @temp0, 1)

  case temp0
    ETHERNET#_SOCK_CLOSED : PST.Str(string("$00 - socket closed", PST#NL, PST#NL))
    ETHERNET#_SOCK_INIT   : PST.Str(string("$13 - socket initalized", PST#NL, PST#NL))
    ETHERNET#_SOCK_LISTEN : PST.Str(string("$14 - socket listening", PST#NL, PST#NL))
    ETHERNET#_SOCK_ESTAB  : PST.Str(string("$17 - socket established", PST#NL, PST#NL))    
    ETHERNET#_SOCK_UDP    : PST.Str(string("$22 - socket UDP open", PST#NL, PST#NL))

  'Try opening a socket using an ASM method
  PST.Str(string("Attempting to open TCP on socket 0, port "))
  PST.dec(localSocket)
  PST.Str(string("...", PST#NL))
  
  ETHERNET.SocketOpen(0, ETHERNET#_TCPPROTO, localSocket, destSocket, @destIP[0])

  'Wait a moment for the socket to get established
  PauseMSec(500)

  'Testing Socket 0's status register and display information
  PST.Str(string("Socket 0 Status Register: "))
  ETHERNET.readIND(ETHERNET#_S0_SR, @temp0, 1)

  case temp0
    ETHERNET#_SOCK_CLOSED : PST.Str(string("$00 - socket closed", PST#NL, PST#NL))
    ETHERNET#_SOCK_INIT   : PST.Str(string("$13 - socket initalized/opened", PST#NL, PST#NL))
    ETHERNET#_SOCK_LISTEN : PST.Str(string("$14 - socket listening", PST#NL, PST#NL))
    ETHERNET#_SOCK_ESTAB  : PST.Str(string("$17 - socket established", PST#NL, PST#NL))    
    ETHERNET#_SOCK_UDP    : PST.Str(string("$22 - socket UDP open", PST#NL, PST#NL))

  'Try setting up a listen on the TCP socket
  PST.Str(string("Setting TCP on socket 0, port "))
  PST.dec(localSocket)
  PST.Str(string(" to listening", PST#NL))

  ETHERNET.SocketTCPlisten(0)

  'Wait a moment for the socket to listen
  PauseMSec(500)

  'Testing Socket 0's status register and display information
  PST.Str(string("Socket 0 Status Register: "))
  ETHERNET.readIND(ETHERNET#_S0_SR, @temp0, 1)

  case temp0
    ETHERNET#_SOCK_CLOSED : PST.Str(string("$00 - socket closed", PST#NL, PST#NL))
    ETHERNET#_SOCK_INIT   : PST.Str(string("$13 - socket initalized", PST#NL, PST#NL))
    ETHERNET#_SOCK_LISTEN : PST.Str(string("$14 - socket listening", PST#NL, PST#NL))
    ETHERNET#_SOCK_ESTAB  : PST.Str(string("$17 - socket established", PST#NL, PST#NL))    
    ETHERNET#_SOCK_UDP    : PST.Str(string("$22 - socket UDP open", PST#NL, PST#NL))

  PageCount := 0

  '
  'I added this section of code to read the text from the Micro SD Card, and store it in the 'TEXT' buffer.
  sdfat.popen(string("spinner.txt"), "r")  ' Open index.txt, a text file, to read a line of HTML.
  filesz := sdfat.get_filesize
  sdfat.pread(@TEXT, filesz+1)
  ' PST.Str(string("Text is:  "))            ' Added these lines in order to see the text in serial terminal during development.
  ' PST.Str(@TEXT)                           ' Left them here so you can un-comment them if you need to do the same.  Otherwise,
                                             ' you can delete them.
  
  'Infinite loop of the server
  repeat

    ' Assumption: one socket is enough.
    '
    ' This demo only uses one of the four sockets maintained by the W5100. It does not
    ' handle simultaneous browsers or simultaneous connections from the same browser.
    ' The alternative is to implement a multi-socket state machine (see Mike G's code).
    '
    ' For many applications the simplifying assumption here is acceptable and
    ' saves resources.

    'Waiting for a client to connect
    PST.Str(string("Waiting for a client to connect.", PST#NL))
    'Testing Socket 0's status register and looking for a client to connect to our server
    repeat while !ETHERNET.SocketTCPestablished(0)   
    PST.Str(string("Connection established.", PST#NL))

    ' Wait for data from the TCP stream
    bytefill(@data, 0, _bytebuffersize)
    PST.Str(string("Waiting for TCP data.", PST#NL)) 
    repeat
      ETHERNET.readIND(ETHERNET#_S0_SR, @temp0, 1)
      if(!ETHERNET.SocketTCPestablished(0))
        ' If the client has gone then break out of the loop. Ideally we should
        ' continue at the top of the main loop. For simplicity we'll just continue
        ' on as if nothing went wrong.
        quit
      readSize := ETHERNET.rxTCP(0, @data)     
      if(readSize>0)
        quit

    ' Assumption: all of the request comes in as one chunk of data that fits in the buffer.
    '
    ' The sender might send the request in chunks e.g. a-line-at-a-time that must be
    ' reassembled into one buffer. Be careful: the data buffer must be as large as the
    ' W500's configured read buffer. A large request could be larger than this buffer.
    ' In reality, nearly all requests from browsers are small and arrive all at once.
    '
    ' For many applications the simplifying assumption here is acceptable and
    ' saves resources.

    PST.Str(string("Read "))
    PST.dec(readSize)
    PST.Str(string(" bytes from TCP",PST#NL))

    ' There are several HTTP methods. This demo only handles GETs (starts with a "G")
    
    if data[0] == "G"
       
      PageCount++
    
      'PST.Str(text)
      PST.Str(string("serving page "))
      PST.dec(PageCount)
      PST.Str(string(PST#NL))
       
      'Send the web page - hardcoded here
      'status lin
      StringSend(0, string("HTTP/1.1 200 OK"))
      StringSend(0, string(PST#NL, PST#LF))
       
      'optional header
      'StringSend(0, string("Server: Parallax Spinneret Web Server/demo 1"))
      'StringSend(0, string("Connection: close"))
      'StringSend(0, string("Content-Type: text/html"))
      'StringSend(0, string(PST#NL, PST#LF))
       
      'blank line
      StringSend(0, string(PST#NL, PST#LF))
      PauseMSec(10) 
      'File
      
      StringSend(0, @TEXT)  ' This line sends out the text that will create the web page on the client system.
                            ' This replaces several lines of hard-coded HTML in the original demo.

      StringSend(0, string(PST#NL, PST#LF))             ' Create a new line after the above is sent.
       
    PauseMSec(5)

    'End the connection
    ETHERNET.SocketTCPdisconnect(0)

    PauseMSec(10)

    'Connection terminated
    ETHERNET.SocketClose(0)
    PST.Str(string("Connection complete.", PST#NL, PST#NL))

    'Once the connection is closed, need to open socket again
    OpenSocketAgain

  sdfat.pclose                            ' I added this line to close the file on the Micro SD Card.  Hopefully you have a card reader where you can
                                          ' insert the Micro SD Card to edit your own web page file, or add the example I included in the downloads.
                                            
  return 'end of main
  
'***************************************
PRI SetVerifyMAC(_firstOctet)
'***************************************

  'Set the MAC ID and display it in the terminal
  ETHERNET.WriteMACaddress(true, _firstOctet)

  
  PST.Str(string("  Set MAC ID........"))
  PST.hex(byte[_firstOctet + 0], 2)
  PST.Str(string(":"))
  PST.hex(byte[_firstOctet + 1], 2)
  PST.Str(string(":"))
  PST.hex(byte[_firstOctet + 2], 2)
  PST.Str(string(":"))
  PST.hex(byte[_firstOctet + 3], 2)
  PST.Str(string(":"))
  PST.hex(byte[_firstOctet + 4], 2)
  PST.Str(string(":"))
  PST.hex(byte[_firstOctet + 5], 2)
  PST.Str(string(PST#NL))

  'Wait a moment
  PauseMSec(500)
 
  ETHERNET.ReadMACAddress(@vMAC[0])
  
  PST.Str(string("  Verified MAC ID..."))
  PST.hex(vMAC[0], 2)
  PST.Str(string(":"))
  PST.hex(vMAC[1], 2)
  PST.Str(string(":"))
  PST.hex(vMAC[2], 2)
  PST.Str(string(":"))
  PST.hex(vMAC[3], 2)
  PST.Str(string(":"))
  PST.hex(vMAC[4], 2)
  PST.Str(string(":"))
  PST.hex(vMAC[5], 2)
  PST.Str(string(PST#NL))
  PST.Str(string(PST#NL))

  return 'end of SetVerifyMAC

'***************************************
PRI SetVerifyGateway(_firstOctet)
'***************************************

  'Set the Gatway address and display it in the terminal
  ETHERNET.WriteGatewayAddress(true, _firstOctet)

  PST.Str(string("  Set Gateway....."))
  PST.dec(byte[_firstOctet + 0])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 1])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 2])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 3])
  PST.Str(string(PST#NL))

  'Wait a moment
  PauseMSec(500)

  ETHERNET.ReadGatewayAddress(@vGATEWAY[0])
  
  PST.Str(string("  Verified Gateway.."))
  PST.dec(vGATEWAY[0])
  PST.Str(string("."))
  PST.dec(vGATEWAY[1])
  PST.Str(string("."))
  PST.dec(vGATEWAY[2])
  PST.Str(string("."))
  PST.dec(vGATEWAY[3])
  PST.Str(string(PST#NL))
  PST.Str(string(PST#NL))

  return 'end of SetVerifyGateway

'***************************************
PRI SetVerifySubnet(_firstOctet)
'***************************************

  'Set the Subnet address and display it in the terminal
  ETHERNET.WriteSubnetMask(true, _firstOctet)

  PST.Str(string("  Set Subnet......"))
  PST.dec(byte[_firstOctet + 0])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 1])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 2])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 3])
  PST.Str(string(PST#NL))

  'Wait a moment
  PauseMSec(500)

  ETHERNET.ReadSubnetMask(@vSUBNET[0])
  
  PST.Str(string("  Verified Subnet..."))
  PST.dec(vSUBNET[0])
  PST.Str(string("."))
  PST.dec(vSUBNET[1])
  PST.Str(string("."))
  PST.dec(vSUBNET[2])
  PST.Str(string("."))
  PST.dec(vSUBNET[3])
  PST.Str(string(PST#NL))
  PST.Str(string(PST#NL))

  return 'end of SetVerifySubnet

'***************************************
PRI SetVerifyIP(_firstOctet)
'***************************************

  'Set the IP address and display it in the terminal
  ETHERNET.WriteIPAddress(true, _firstOctet)

  PST.Str(string("  Set IP.........."))
  PST.dec(byte[_firstOctet + 0])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 1])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 2])
  PST.Str(string("."))
  PST.dec(byte[_firstOctet + 3])
  PST.Str(string(PST#NL))

  'Wait a moment
  PauseMSec(500)

  ETHERNET.ReadIPAddress(@vIP[0])
  
  PST.Str(string("  Verified IP......."))
  PST.dec(vIP[0])
  PST.Str(string("."))
  PST.dec(vIP[1])
  PST.Str(string("."))
  PST.dec(vIP[2])
  PST.Str(string("."))
  PST.dec(vIP[3])
  PST.Str(string(PST#NL))
  PST.Str(string(PST#NL))

  return 'end of SetVerifyIP

'***************************************
PRI StringSend(_socket, _dataPtr)
'***************************************

  ETHERNET.txTCP(0, _dataPtr, strsize(_dataPtr))

  return 'end of StringSend

'***************************************
PRI OpenSocketAgain
'***************************************

  ETHERNET.SocketOpen(0, ETHERNET#_TCPPROTO, localSocket, destSocket, @destIP[0])
  ETHERNET.SocketTCPlisten(0)

  return 'end of OpenSocketAgain
  
'***************************************
PRI PauseMSec(Duration)
'***************************************
''  Pause execution for specified milliseconds.
''  This routine is based on the set clock frequency.
''  
''  params:  Duration = number of milliseconds to delay                                                                                               
''  return:  none
  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)

  return  'end of PauseMSec

'***************************************

' I added this routine to help with the string handling for the web page text.  However, I
' ended up not using it.  Left it here in case you need to use it in manipulating strings.
'PRI SetString( dstStrPtr, srcStrPtr )
'  ByteMove(dstStrPtr, srcStrPtr, StrSize(srcStrPtr)+1)  '+1 for zero termination

'***************************************  
DAT
'TEXT byte "<HTML><HEAD><TITLE>Hello, Greg</TITLE></HEAD><BODY>SPINNERET-DAT</BODY></HTML>",0
'***************************************         

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