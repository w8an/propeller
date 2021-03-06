{{

CONNECTION DIAGRAM:

               propeller xmit to sim900 receive    
      ┌───▶─────────────────────────────────────────────────────────────────────────────────┐    
      │                                                                                     │
      │        propeller rcv to sim900 xmit                                                 │                            │
   ┌──┼───◀────────────────────────────────────────────────────────────────────────────┐    │                                                                                     │
   │  │                                                                                │    │
   │  │                                           ┌───────────────────────────┐        │    │                    │
   │  │    ┌───────────────┐                      │                           │        │    │
   │  └ P0 ┤1            40├P31                   │   G P        S            │        │    │
   └─── P1 ┤2            39├P30                   │   N W        I        ‣   │        │    │        
        P2 ┤3      P     38├P29                   │   D R        M        ‣   │        │    │
        P3 ┤4      R     37├P28            ┌──────┼───• •        9        ‣   │        │    │
        P4 ┤5      O     36├P27            │      │              0        ‣   │        │    │
        P5 ┤6      P     35├P26            │      │   ‣          0        ‣   │        │    │
        P6 ┤7      E     34├P25            │      │   ‣                   ‣   │        │    │
        P7 ┤8      L     33├P24            │      │   ‣              JP ‣ ‣   │  XMIT  │    │
           ┤GND    L   3.3V├               │      │   ‣                 ‣ ‣   │──▶─────┘    │
           ┤BOEN   E     X0├               │      │   ‣                       │             │
           ┤RESN   R     X1┤               │      │   ‣                   ‣   │──◀──────────┘
           ┤3.3V        GND├───────────────┘                      │       ‣   │  RECEIVE                                        o
        P8 ┤13           28├ P23                  │   ‣                   ‣   │
        P9 ┤14           27├ P22                  │   ‣                   ‣   │
        P10┤15           26├ P21                  │   ‣                   ‣   │        
        P11┤16           25├ P20                  │   ‣    ┌─────┐ uart   ‣   │                                                                 o
        P12┤17           24├ P19                  │   ‣    │P  J │ • •─•  ‣   │ 
        P13┤18    │      23├ P18                  │   ‣    │W  A │ • •─•  ‣   │          
        P14┤19           22├ P17                  │        │R  C │            │                
        P15┤20           21├ P16                  └────────┤   K ├────────────┘           
           └───────────────┘                               └─────┘            

                                                              UART JUMPERS

                                                                 gprs tx
                                                                  • •─•
                                                         xduino   • •─•     swserial
                                                                  gprs rx
                                                                                                ┼

========================================================================================================                             


}}
CON 
  _clkmode      = xtal1 + pll16x                        'Set clock to 80MHz
  _xinfreq      = 5_000_000                             'Crystal is 5MHz.                                                     
   QUOTE        = 34          'used in the case statement to display the quote sign "             ' "
     
OBJ
  phone         : "FullDuplexSerial"   
  debug         : "FullDuplexSerial" 
'  sn            : "simple_numbers"          
'  f             : "FloatMath"
'  FP            : "FLOATSTRING" 

VAR
  byte  rxByte, rxbyte1,rxbyte2,NBR,PHONENUMBER , datafromsim900[140] 

 
pub BASIC_FUNCTIONS

'____________________________________________________________________________________________
     debug.start(31, 30, %0000, 19200)
     DEBUG.str(string("______________________________________________________________________________________",13))
     DEBUG.str(string("ATE1 command",13))
     DEBUG.str(string("ECHO ON COMMAND, RESPONSE IS OK",13))
     waitcnt(clkfreq/10+cnt)    
     phone.start(0, 1,  %0000, 19200)
     phone.str(string("ATE1",13))           '
     readwrite

 '____________________________________________________________________________________________
     debug.start(31, 30, %0000, 19200)
         
     DEBUG.str(string("______________________________________________________________________________________",13))
     DEBUG.str(string("GSN command",13))
     DEBUG.str(string("response is the unique imei number printed on the sim900 module",13))     
     DEBUG.str(string("followed by OK",13)) 
     waitcnt(clkfreq/10+cnt)    
     phone.start(0, 1,  %0000, 19200)
     phone.str(string("AT+GSN",13))           'GETS THE IMEI NUMBER FROM THE MODULE
     readwrite

'__________________________________________________________________________________________________________________________

     debug.start(31, 30, %0000, 19200)
     DEBUG.str(string("______________________________________________________________________________________",13)) 
     DEBUG.str(string("GMM command",13))
     DEBUG.str(string("response is the sim900 model number followed by OK ",13))
     waitcnt(clkfreq/10+cnt)    
     phone.start(0, 1,  %0000, 19200)
     phone.str(string("AT+GMM",13))             
     readwrite

'__________________________________________________________________________________________________________________________

     debug.start(31, 30, %0000, 19200)
     DEBUG.str(string("______________________________________________________________________________________",13)) 
     DEBUG.str(string("CSQ command",13))
     DEBUG.str(string("response is the radiosignal level, 0 to 30 and the bit error rate, 0 to 7",13))
     DEBUG.str(string("followed by OK",13)) 
     waitcnt(clkfreq/10+cnt)    
     phone.start(0, 1,  %0000, 19200)
     phone.str(string("AT+CSQ",13))  'GETS THE RADIO SIGNAL LEVEL  RESPONSE WILL BE BETWEEN 0 AND 31
     readwrite
'_______________________________________________________________________________________________________________________      
     
     debug.start(31, 30, %0000, 19200)
     DEBUG.str(string("______________________________________________________________________________________",13))
     DEBUG.str(string("CMTE command",13))
     debug.str(string(13,"first digit in response will be a one or zero, one enables auto"))
     debug.str(string(13,"temperature shutdown, zero disables auto temperature shutdown"))
     debug.str(string(13,"second and thirds digits in response are the temperature in celcius, range is"))
     debug.str(string(13,"-40 to 90, followed by ",13))
     waitcnt(clkfreq/2+cnt)
     phone.start(0, 1,  %0000, 19200)
     phone.str(string("AT+CMTE?",13)) 'GETS THE TEMPERATURE FROM  THE SIM900  0,29 THE 29 IS TEMP IN CELCIUS
     readwrite
'_______________________________________________________________________________________________________________________

     debug.start(31, 30, %0000, 19200)
     DEBUG.str(string("______________________________________________________________________________________",13))
     DEBUG.str(string("CBC command",13))
     debug.str(string(13,"first digit in response can be a zero, indicates not charging"))
     debug.str(string(13,"a one indicates charging, a two indicates charging completed."))
     debug.str(string(13,"second digit indicates the state of charge, 0 to 100 percent"))
     debug.str(string(13,"third digit indiates supply voltage in millivolts, followed by OK"))
     waitcnt(clkfreq/2+cnt)
     phone.start(0, 1,  %0000, 19200)
     phone.str(string("AT+CBC",13))   'GETS THE POWER IN MV   0,100,4211   'THE 0 INDICATES NOT CHARGING
     readwrite                                                             'THE 100 INDICATES STATE OF CHARGE
'_______________________________________________________________________________________________________________________

     debug.start(31, 30, %0000, 19200)
     DEBUG.str(string("______________________________________________________________________________________",13))
     DEBUG.str(string("CMGF command",13))
     debug.str(string(13,"operate the sim900 in sms mode, response is ok"))
     waitcnt(clkfreq/2+cnt)
     phone.start(0, 1,  %0000, 19200) 
     phone.str(string("AT+CMGF=1",13))   'OPERATE IN SMS MODE
     readwrite                                               
'_______________________________________________________________________________________________________________________

     debug.start(31, 30, %0000, 19200)
     DEBUG.str(string("______________________________________________________________________________________",13))
     DEBUG.str(string("CMGR command",13))
     debug.str(string(13,"reads and displays the first message from the sim900 memory, if no message is found"))
     debug.str(string(13,"the response will be OK. to test this function send a text message to the phone number  "))
     debug.str(string(13,"associated with the sim card purchased followed by OK "))     
     waitcnt(clkfreq/2+cnt)
     phone.start(0, 1,  %0000, 19200)
     phone.str(string("AT+CMGR=1" , 13)) 'READ THE NUMBER 1 MESSAGE IN MEMORY
     readwrite
'_____________________________________________________________________________________________

     debug.start(31, 30, %0000, 19200)
     DEBUG.str(string("______________________________________________________________________________________",13))
     DEBUG.str(string("CMGD=1,4 command ",13))
     debug.str(string(13,"deletes all messages in the sim900 memory, response is OK"))
     waitcnt(clkfreq/2+cnt)
     phone.start(0, 1,  %0000, 19200)
     phone.str(string("AT+CMGD=1,4" , 13)) 'DELETES ALL MESSAGES IN MEMORY
     readwrite 
'_____________________________________________________________________________________________

     debug.start(31, 30, %0000, 19200)
     DEBUG.str(string("______________________________________________________________________________________",13))
     DEBUG.str(string("CMGD=1 command",13))
     debug.str(string(13,"deletes the first message in the sim900 memory, response is OK"))
     waitcnt(clkfreq/2+cnt)
     phone.start(0, 1,  %0000, 19200)
     phone.str(string("AT+CMGD=1" , 13))   'DELETES THE FIRST MESSAGE IN MEMORY
     readwrite 

'_____________________________________________________________________________________________

     debug.start(31, 30, %0000, 19200)
     DEBUG.str(string("______________________________________________________________________________________",13))
     DEBUG.str(string("CLTS and CCLK command",13))
     debug.str(string(13,"reads and displays the time and date, format is yy/mm/dd:hh:mm:ss+zz, followed by OK"))
     debug.str(string(13,"the sim900 default setup is with the clock function enabled, if not the CLTS command"))
     debug.str(string(13,"must be sent, see the AT command listing for more details"))
     waitcnt(clkfreq/2+cnt)
     phone.start(0,1,%0000,19200)
     waitcnt (clkfreq+cnt)     
     phone.str(string("AT+CLTS=1" , 13))    'enables clock function
     waitcnt (clkfreq+cnt)     
     phone.str(string("AT+CCLK?" , 13))      'shows the time
     readwrite

' ________________________________________________________________________________

{PUB LISTdatafromsim900
       nbr:=0
   repeat 140
     debug.str(string("datafromsim900  number = "))
     debug.dec(nbr)
     debug.str(string("     "))  
     debug.dec(datafromsim900[nbr])
     debug.tx(13)
     nbr++
 waitcnt(clkfreq/2+cnt)
}
'_______________________________________________________________________________


PUB READWRITE
 
     debug.start(31, 30, %0000, 19200)   
     phone.rxflush
           
 nbr:=0    
              
      repeat 139      'IF YOU CHANGE THIS VALUE YOU MUST ALSO CHANGE IT IN THE REPEAT STATEMENT BELOW AND IN THE datafromsim900 VARIABLE
           datafromsim900[NBR]:= phone.rxtime(10)
           NBR++
        
    waitcnt(clkfreq/2+cnt)
    debug.TX(13)  


    NBR:=0
    REPEAT 139  'IF YOU CHANGE THIS VALUE YOU MUST ALSO CHANGE IT IN THE REPEAT STATEMENT ABOVE AND IN THE ARRAY VARIABLE
      case  datafromsim900[NBR]     

        10 :  debug.TX(10)
        13 :  debug.TX(13)
        32 :  debug.str(string(" "))
        34 :  debug.str(string(QUOTE," "))  'this will display the " mark it is an hex constant declared above
                                         'ser.str requires a least one character in its statemt in this case
                                         'its a space . the next line takes out the space in the display (backspace)
               debug.tx(8)               '8 is the backspace instructionc
        38 :  debug.str(string("&"))
        44 :  debug.str(string(","))
        46 :  debug.str(string("."))   
        47 :  debug.str(string("/"))
        58 :  debug.str(string(":"))
        43 :  debug.str(string("+"))
        44 :  debug.str(string(","))
        45 :  debug.str(string("-"))   
        48 :  debug.str(string("0"))     
        49 :  debug.str(string("1"))
        50 :  debug.str(string("2"))    
        51 :  debug.str(string("3"))    
        52 :  debug.str(string("4"))    
        53 :  debug.str(string("5"))
        54 :  debug.str(string("6"))   
        55 :  debug.str(string("7"))  
        56 :  debug.str(string("8")) 
        57 :  debug.str(string("9"))
        64 :  debug.str(string("@"))  
        65 :  debug.str(string("A"))
        66 :  debug.str(string("B"))
        67 :  debug.str(string("C"))
        68 :  debug.str(string("D"))
        69 :  debug.str(string("E"))
        70 :  debug.str(string("F"))
        71 :  debug.str(string("G"))
        72 :  debug.str(string("H"))
        73 :  debug.str(string("I"))
        74 :  debug.str(string("J"))
        75 :  debug.str(string("K"))
        76 :  debug.str(string("L"))
        77 :  debug.str(string("M"))
        78 :  debug.str(string("N"))
        79 :  debug.str(string("O"))
        80 :  debug.str(string("P"))
        81 :  debug.str(string("Q"))
        82 :  debug.str(string("R"))
        83 :  debug.str(string("S"))
        84 :  debug.str(string("T"))
        85 :  debug.str(string("U"))
        86 :  debug.str(string("V"))
        87 :  debug.str(string("W"))
        88 :  debug.str(string("X"))
        89 :  debug.str(string("Y"))
        90 :  debug.str(string("Z"))

'case had to be split in two parts beacuse first one became too long 
      case  datafromsim900[NBR]     

        42 :  debug.str(string("*"))
        97 :  debug.str(string("a"))
        98 :  debug.str(string("b"))
        99 :  debug.str(string("c"))
        100:  debug.str(string("d"))
        101:  debug.str(string("e"))
        102:  debug.str(string("f"))
        103:  debug.str(string("g"))
        104:  debug.str(string("h"))
        105:  debug.str(string("i"))
        106:  debug.str(string("j"))
        107:  debug.str(string("k"))
        108:  debug.str(string("l"))
        109:  debug.str(string("m"))
        110:  debug.str(string("n"))
        111:  debug.str(string("o"))
        112:  debug.str(string("p"))
        113:  debug.str(string("q"))
        114:  debug.str(string("r"))
        115:  debug.str(string("s"))
        116:  debug.str(string("t"))
        117:  debug.str(string("u"))
        118:  debug.str(string("v"))
        119:  debug.str(string("w"))
        120:  debug.str(string("x"))
        121:  debug.str(string("y"))
        122:  debug.str(string("z"))
      WAITCNT(CLKFREQ/100+CNT)  
      NBR++ 


'=======================================

       