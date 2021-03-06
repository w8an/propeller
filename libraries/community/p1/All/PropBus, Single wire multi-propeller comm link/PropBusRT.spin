{{
  Prop Bus, Remote Terminal
  File: PropBusRT.spin
  Version: 3.0
  Copyright (c) 2014 Mike Christle

  See PropBusBC file for complete documentation.
}}

CON

    MAX_BUFFER_COUNT = 10
    #0, RECEIVE_BUFFER, TRANSMIT_BUFFER, TRAN_INCR_BUFFER

VAR

    byte Cog, BDCount
    word Command
    long BDBuffer[MAX_BUFFER_COUNT]

PUB Start(TXPin, RXPin, OEPin, CmdAdrs)
{{
  Starts the RT.

  TXPin:  The port number of the Transmit pin.

  RXPin:  The port number of the Receive pin.

  OEPin:  The port number of the Output Enable pin.
          Set to -1 if not used.

  CmdAdrs:  The local address of a word to receive asyncronous 
            commands. Set to zero if asyncronous commands are 
            needed.
}}
    Stop

    tx_pin := 1 << TXPin
    rx_pin := 1 << RXPin
    if OEPin => 0
        oe_pin := 1 << OEPin

    buffer_ptr := @BDBuffer
    count_ptr := @BDCount
    command_ptr := CmdAdrs

    if bit_rate > 0
        bit_time := clkfreq / bit_rate
    else
        bit_time := 0

    Cog := cognew(@rt_loop, 0) + 1

PUB Stop
{{
  Will stop and reset the RT.
}}

    if Cog > 0
        cogstop(Cog - 1)
    Cog := 0

PUB AddBuffer(Number, Adrs, Count, Send) | T
{{
  Defines the buffers that this chip is sending or recieving.
  This should be called before the BC starts cycling.

  Number: The buffer number. Each buffer in the system must have
          a unique buffer number from 1 to 255. Buffer numbers
          should be consecutive starting at 1. If they are not the
          bus will still work, but you are wasting bandwidth.

  Adrs:   The local address of the start of the buffer.

  Count:  The number of 16 bit words in the buffer. Range 1 to 63.

  Send:   RECEIVE_BUFFER   = This chip receives this buffer.
          TRANSMIT_BUFFER  = This chip own and sends this buffer.
          TRAN_INCR_BUFFER = This chip own and sends this buffer, 
                             and the last word inthe buffer is 
                             incremented every time the buffer is 
                             transmitted.
}}
    if BDCount == MAX_BUFFER_COUNT
        return 1

    T := Adrs | (Count << 16) | (Number << 24)
    if Send <> RECEIVE_BUFFER
        T := T | $8000_0000
    if Send == TRAN_INCR_BUFFER
        T := T | $0080_0000
    BDBuffer[BDCount] := T
    BDCount++
    return 0

PUB SetBitRate(BitRate)
{{
  Sets the bit rate for the bus. Must be called before
  calling Start. All devices on the bus must have the
  same bit rate. Default is 1 MBit.

  BitRate:  Bit Rate in bits per second
}}

  bit_rate := BitRate

DAT
                        org     0
'PROPC
'
'//--------------------------------------------------------------
'// Remote Terminal Loop
'//--------------------------------------------------------------
'void rt_loop()
rt_loop

'{
'    uint t0, t1;
'
'    // Setup bit timing
'    half_bit_time = bit_time >> 1;
                        MOV     half_bit_time, bit_time  
                        SHR     half_bit_time, #1  

'    rcvr_bit_time = (half_bit_time >> 2) + half_bit_time;
                        MOV     rcvr_bit_time, half_bit_time  
                        SHR     rcvr_bit_time, #2  
                        ADD     rcvr_bit_time, half_bit_time  

'
'    // Loop forever
'    while (true)
:L1

'    {
'        // Receive a word
'        receive(0);
                        MOV     receive_timeout, #0  
                        CALL    #receive 

'
'        // If word received without error
'        if (receive_status == 0)
                        CMP     receive_status, #0  WZ
   IF_NZ                JMP     #:L5

'        {
'            // If an asyncronous command then save it
'            if (command_ptr && pb_data &~ 0x007F)
                        CMP     command_ptr, #0  WZ
   IF_Z                 JMP     #:L8
                        MOV     rt_loop__0, pb_data  
                        ANDN    rt_loop__0, #127  WZ
   IF_Z                 JMP     #:L8

'                GWORD[command_ptr] = pb_data;
                        WRWORD  pb_data, command_ptr  

'
'            // If a buffer command then process the buffer
'            else
                        JMP     #:L9 
:L8

'                process();
                        CALL    #process 
:L9

'        }
:L5

'
'        // Wait for bus to be idle for 16 bit times
'        wait_for_idle(bit_time << 4);
                        MOV     wait_for_idle_clocks, bit_time  
                        SHL     wait_for_idle_clocks, #4  
                        CALL    #wait_for_idle 

'    }
                        JMP     #:L1 

'}
rt_loop_RET             RET
'---------------------------------------------------------

'
'//--------------------------------------------------------------
'
'uint buffer_ptr = 0;        // Buffer Table Pointer
'uint count_ptr = 0;         // Buffer Table size
'uint bit_time = 0;          // Bit Time in Clocks
'uint tx_pin = 0;            // TX IO Pin Number
'uint rx_pin = 0;            // RX IO Pin Number
'uint oe_pin = 0;            // OE IO Pin Number
'uint command_ptr = 0;       // Pointer to async command word
'uint bit_rate = 1_000_000;  // Bit rate, bits per second
'
'uint wait_cntr;
'uint pb_data;
'uint half_bit_time;
'uint rcvr_bit_time;
'uint receive_status;
'uint bit_counter;
'uint t0, t1;
'
'//--------------------------------------------------------------
'// Process a command
'// 
'//  Command Format
'//  Bit  7-00  8  Buffer Number
'//  Bit 15-08  8  User Defined Commands
'//
'//  Buffer Descriptor Format
'//  Bit 15-00 16  Buffer Address
'//  Bit 21-16  5  Word Count
'//  Bit 22     1  Unused
'//  Bit 23     1  Send Flag
'//  Bit 31-24  8  Buffer Number
'//
'//--------------------------------------------------------------
'void process()
process

'{
'    uint i, j, p;
'    uint address;
'    uint word_count;
'    uint buffer_entry;
'
'    pb_data <<= 24;    
                        SHL     pb_data, #24  

'    p = buffer_ptr;
                        MOV     process_p, buffer_ptr  

'
'    // For each buffer defined by this device
'    for (i = GBYTE[count_ptr])
                        RDBYTE  process_i, count_ptr  
:L10

'    {
'        // Read a buffer entry
'        buffer_entry = GLONG[p];
                        RDLONG  process_buffer_entry, process_p  

'        p += 4;
                        ADD     process_p, #4  

'
'        // If buffer number matches the command
'        if ((buffer_entry ^ pb_data) & buffer_no_mask == 0)
                        MOV     process__0, process_buffer_entry  
                        XOR     process__0, pb_data  
                        AND     process__0, buffer_no_mask  WZ
   IF_NZ                JMP     #:L13

'        {
'            // Parse out address and word count
'            address = buffer_entry & address_mask;
                        MOV     process_address, process_buffer_entry  
                        AND     process_address, address_mask  

'            word_count = buffer_entry & word_count_mask;
                        MOV     process_word_count, process_buffer_entry  
                        AND     process_word_count, word_count_mask  

'            word_count >>= 16;
                        SHR     process_word_count, #16  

'
'            // If this is a send buffer
'            if (buffer_entry & send_flag_mask)
                        TEST    process_buffer_entry, send_flag_mask  WZ
   IF_Z                 JMP     #:L16

'            {
'                // For each word in buffer
'                for (j = word_count)
                        MOV     process_j, process_word_count  
:L18

'                {
'                    // Insert 8 bit time delay between words
'                    wait_cntr = (bit_time << 3) + cnt;
                        MOV     wait_cntr, bit_time  
                        SHL     wait_cntr, #3  
                        ADD     wait_cntr, cnt  

'                    waitcnt(wait_cntr, 0);
                        WAITCNT wait_cntr, #0  

'
'                    // Get data word and check for tag
'                    pb_data = GWORD[address];
                        RDWORD  pb_data, process_address  

'                    if (buffer_entry & tag_word_mask && j == 1)
                        TEST    process_buffer_entry, tag_word_mask  WZ
   IF_Z                 JMP     #:L21
                        CMP     process_j, #1  WZ
   IF_NZ                JMP     #:L21

'                        GWORD[address] = ++pb_data;
                        ADD     pb_data, #1  
                        WRWORD  pb_data, process_address  
:L21

'                    address += 2;
                        ADD     process_address, #2  

'
'                    // Transmit the data word
'                    transmit();
                        CALL    #transmit 

'                }
                        DJNZ    process_j, #:L18  

'            }
'            // If this is a receive buffer
'            else
                        JMP     #:L11 
:L16

'            {
'                // For each word in buffer
'                for (j = word_count)
                        MOV     process_j, process_word_count  
:L23

'                {
'                    // receive and store the data word
'                    receive(bit_time << 4);
                        MOV     receive_timeout, bit_time  
                        SHL     receive_timeout, #4  
                        CALL    #receive 

'                    if (receive_status != 0) break;
                        CMP     receive_status, #0  WZ
   IF_NZ                JMP     #:L11

'                    GWORD[address] = pb_data;
                        WRWORD  pb_data, process_address  

'                    address += 2;
                        ADD     process_address, #2  

'                }
                        DJNZ    process_j, #:L23  

'            }

'            break;
                        JMP     #:L11 

'        }
:L13

'    }
                        DJNZ    process_i, #:L10  
:L11

'}
process_RET             RET
'---------------------------------------------------------

'
'//--------------------------------------------------------------
'//--------------------------------------------------------------
'void wait_for_idle(uint clocks)
wait_for_idle

'{
'    t0 = cnt;
                        MOV     t0, cnt  

'    do
:L28

'    {
'        if (rx_pin & ina == 0) t0 = cnt;
                        TEST    rx_pin, ina  WZ
   IF_NZ                JMP     #:L31
                        MOV     t0, cnt  
:L31

'        t1 = cnt - t0;
                        MOV     t1, cnt  
                        SUB     t1, t0  

'    }
'    while (t1 < clocks);
                        CMP     t1, wait_for_idle_clocks  WZ, WC
   IF_C                 JMP     #:L28

'}
wait_for_idle_RET       RET
'---------------------------------------------------------

'
'//--------------------------------------------------------------
'uint send_flag_mask  = 0x8000_0000;
'uint tag_word_mask   = 0x0080_0000;
'uint address_mask    = 0x0000_7FFE;
'uint word_count_mask = 0x007F_0000;
'uint buffer_no_mask  = 0x7F00_0000;
'//--------------------------------------------------------------
'
'//--------------------------------------------------------------
'// Transmit a 16 bit word
'//
'//     |     Start     | 15:0  | 14:1  |...|Parity |
'//  ___         _______     ___ ___         ___     ___
'//     #_______#       #___/   #   \___#...#   \___#
'//--------------------------------------------------------------
'void transmit()
transmit

'{
                        SHL     pb_data, #1
                        TESTN   pb_data, #0  WC
    IF_NC               OR      pb_data, #1
                        SHL     pb_data, #15

                        OR      outa, tx_pin
                        OR      dira, tx_pin
                        OR      dira, oe_pin
                        OR      outa, oe_pin

                        MOV     wait_cntr, cnt
                        ANDN    outa, tx_pin
                        ADD     wait_cntr, bit_time
                        WAITCNT wait_cntr, bit_time
                        OR      outa, tx_pin

                        MOV     bit_counter, #17

:TX01                   ROL     pb_data, #1  WC
    IF_C                JMP     #:TX02

                        WAITCNT wait_cntr, half_bit_time
                        ANDN    outa, tx_pin
                        WAITCNT wait_cntr, half_bit_time
                        OR      outa, tx_pin
                        JMP     #:TX03

:TX02                   WAITCNT wait_cntr, half_bit_time
                        OR      outa, tx_pin
                        WAITCNT wait_cntr, half_bit_time
                        ANDN    outa, tx_pin

:TX03                   DJNZ    bit_counter, #:TX01

                        WAITCNT wait_cntr, half_bit_time

                        SHR     pb_data, #1
                        OR      outa, tx_pin
                        ANDN    dira, tx_pin
                        ANDN    outa, oe_pin
'}
transmit_RET            RET
'---------------------------------------------------------

'//--------------------------------------------------------------
'// receive a 16 bit word
'//
'// pb_data:        Contains the data word 
'// receive_status: 0 = Success
'//                 1 = Timeout Error
'//--------------------------------------------------------------
'void receive(uint timeout)
receive

'{
                        MOV     receive_status, #1
                        MOV     pb_data, #0
                        MOV     bit_counter, #17

:RX01                   TEST    rx_pin, ina  WC
   IF_C                 DJNZ    receive_timeout, #:RX01
   IF_C                 JMP     #receive_RET

                        WAITPEQ rx_pin, rx_pin
                        MOV     wait_cntr, cnt
                        ADD     wait_cntr, rcvr_bit_time
                        ADD     wait_cntr, half_bit_time

:RX02                   SHL     pb_data, #1

                        WAITCNT wait_cntr, #0
                        TEST    rx_pin, ina  WZ
    IF_Z                JMP     #:RX04

                        OR      pb_data, #1
:RX03                   TEST    rx_pin, ina  WC
    IF_C                DJNZ    receive_timeout, #:RX03
                        MOV     wait_cntr, cnt
    IF_C                JMP     #receive_RET

                        ADD     wait_cntr, rcvr_bit_time
                        JMP     #:RX05

:RX04                   WAITPEQ rx_pin, rx_pin
                        MOV     wait_cntr, cnt
                        ADD     wait_cntr, rcvr_bit_time

:RX05                   DJNZ    bit_counter, #:RX02
                        WAITCNT wait_cntr, #0

                        TESTN   pb_data, #0  WC
    IF_C                MOV     receive_status, #0
                        SHR     pb_data, #1

'}
receive_RET             RET
'---------------------------------------------------------
'//#include "PropBusReceiveAnyClockRate.pc"
tru                     LONG    1
fls                     LONG    0
math_ones               LONG    -1
math_real_mask          LONG    65535
math_half               LONG    32768
math_90                 LONG    8388608
math_180                LONG    16777216
zero                    LONG    0
buffer_ptr              LONG    0
count_ptr               LONG    0
bit_time                LONG    0
tx_pin                  LONG    0
rx_pin                  LONG    0
oe_pin                  LONG    0
command_ptr             LONG    0
bit_rate                LONG    1000000
send_flag_mask          LONG    -2147483648
tag_word_mask           LONG    8388608
address_mask            LONG    32766
word_count_mask         LONG    8323072
buffer_no_mask          LONG    2130706432
CONST_1                 LONG    1
CONST_2                 LONG    2
CONST_0                 LONG    0
CONST_0x007F            LONG    127
CONST_4                 LONG    4
CONST_24                LONG    24
CONST_16                LONG    16
CONST_3                 LONG    3
math_p1                 RES     1
math_p2                 RES     1
math_r1                 RES     1
math_r2                 RES     1
math_t                  RES     1
math_s                  RES     1
wait_cntr               RES     1
pb_data                 RES     1
half_bit_time           RES     1
rcvr_bit_time           RES     1
receive_status          RES     1
bit_counter             RES     1
t0                      RES     1
t1                      RES     1
wait_for_idle_clocks    RES     1
receive_timeout         RES     1
rt_loop_t0              RES     1
rt_loop_t1              RES     1
rt_loop__0              RES     1
process_i               RES     1
process_j               RES     1
process_p               RES     1
process_address         RES     1
process_word_count      RES     1
process_buffer_entry    RES     1
process__0              RES     1
process__1              RES     1
wait_for_idle__0        RES     1
'---------------------------------------------------------
                        fit      
{{
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}
