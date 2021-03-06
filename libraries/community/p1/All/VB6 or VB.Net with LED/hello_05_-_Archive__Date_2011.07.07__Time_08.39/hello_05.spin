{{  hello_05.spin

    Copyright (c) 2011 Greg Denson,
    See MIT License information at bottom of this document.
    

    CREATED BY:
    Greg Denson, 2011-07-06

    MODIFIED BY:
    Greg Denson, 2011-07-07, removed unnecessary lines of code in the receive section, and added more comments. 

    This version of the 'hello' program was created to work with Visual BASIC 6.0 serial communications.
    It will send out three serial "Hello, World!" lines, along with a little other information, just to let
    the user know that it is connected to VB6, and will then let the user know that it is ready to receive some
    data from VB6.

    The purpose of the program is to serve as a demonstration of serial communications between the Propeller
    chip and Visual Basic 6.0.  The hope is that the beginning user of Propeller who wants to try working with
    VB6 and the Propeller will find this a good starting place on which to build his/her own applications.

    As far is this spin program goes, it could also be easily modified to send and receive data from programs
    in other languages such as Python.  I used a Python-to-Propeller communication demo as a template when I
    started to create this program.  

    The VB6 program that was created to communicate with this spin program is 'read_propeller.vbp'.  
    
    NOTE:  2011-07-05, In order to get each line into VB6 as a separate line, I am sending the combination
           13, 10 (CR LF) with each line below.  Otherwise, the VB6 has some issues with how to organize the
           data it receives into lines of text that match what was sent.  I had also noticed that when I used
           my similar program for Python, that without the CR-LF pair, Python would wait and receive all the lines
           I sent, and then display them all as one big line.  So, it seems that whether I use VB6 or Python, I
           need to pay attention to how I format the lines going out so that they line up well when they are
           received.
    NOTE:  2011-07-06, The line formatting setup that I had for Python still doesn't want to work well with VB6.
           I was unable to get more than 14 characters per line when the data was received in VB6.  So, if you
           change the formatting setup I have below, as well as the setup in VB6, you may have to work out some
           issues with the formatting of text lines. I did finally get it to look the way I wanted, so that is
           the result that is in this spin program and my current VB6 program.  
    NOTE:  2011-07-06, I have now reached version 5( hello_05.spin) of this programl so that it works as described
           in the top paragraphs, above.  Additional work was done on the send routine in VB6 to ensure that this
           spin program did not send back multiple copies of the lines that confirm receipt of the data from VB6.
           This involved ensuring that the send textbox in VB6 is cleared after each send.  A "vbCrLf" carriage return
           and linefeed combination was added to every data item sent.  Before making these changes, I was having
           to manually hit return after entering a 1 or 0 in the send textbox, and was also having to manually
           delete all text in the send textbox each time I clicked the Send button.  So, if you make changes to
           This area of the VB6 program, you may get unexpected results coming back to VB from this spin program.
    NOTE:  2011-07-07m I also discovered today that sending odd numbers (bit zero is on) will turn on the LED.
           Sending any even number will turn the LED off.  I have tested this by sending NULL, which counts as
           an even number and turns off the LED if it is on.  I also tested it from 0 to 255.  Zero also counts
           as even and turns off the LED if is on.  255, being odd will turn it on, and 254, being even will
           turn it off.  I haven't yet tried this outside that range of numbers.        
}}

VAR
  long SERIAL_IN[20]   'Variable to hold the data that comes in from VB6. This could be smaller than 20 if all you
                       'want to do is send in a 1 or 0 to turn the LED on/off. I was allowing for sending text, too.
                       'The value that comes in from VB6, even a 1 or 0, is in text format, so this holds a string.
  long led_on_off      'Holds the status of the LED for the (as sent from VB6).  Read by the Set_LED routine below.
                       'This is now in decimal format, having been converted by the str_to_dec routine, below. 
                      
CON
  _CLKMODE = XTAL1 + PLL16X   'Setting up the clock mode
  _XINFREQ = 5_000_000        'Setting up the frequency

  output_pin = 0              'Using this constant to set the Propeller pin used to turn on/off the LED in this demo.

{{  Setting up the hardware:

    My connections for the Propeller Demo board are shown below. Same pins can be used for other Propeller setups.                                                      

    Parallax 
    Propeller
    Demo Board
             ───┐    LED   
          P0    │───────┐     Be sure the cathode of the LED is connected to ground (GND).  The cathode is the 
                │         │     shorter lead of the LED, and often has a flat spot on the rim of the LED, too.
          GND   │─────────┘
             ───┘         


}}
OBJ
    pst  : "Parallax Serial Terminal"     'This object is used to support the serial communications.
                                          'It should already be in your working directory.  If not, download it
                                          'from www.parallax.com, in the Object Exchange section.

PUB Setup
   pst.start(9600)                         'This line starts the Parallax Serial Terminal, and sets the baud rate
                                           'for the serial communications terminal.  You can change this to the
                                           'desired rate if you want to run faster.
                                             
  'Here we begin the section of the program that sends out data from spin to VB6
   pst.str(string(13, 10, "Serial Terminal is ready",13, 10))  'Send a message that the terminal is running, use CR/LF.
   repeat 3                                                    'For this demo, we're sending the message below 3 times.
      pst.str(string("Hello, World!  This is Greg", 13, 10))   'And here is the simple message we send all 3 times.
      waitcnt(clkfreq*1 + cnt)                                 'This is a short delay between messages to allow you
                                                               'to watch them coming in.  For a real application or
                                                               'project, you would probably want to remove this.

   pst.str(string("That's all folks!", 13, 10))                   'Finally, we let the user know we are through sending.

   pst.str(string(13, 10, "Waiting to hear from you...",13, 10))  'For the demo, we now prompt the user to send some data.
                                                                  'For the demo, I am sending 1 or 0 to turn an LED on or off.
                                                                  
   repeat                                                         'This time, we will continue to loop so that the terminal
                                                                  'will continue to watch for our incoming data.
      pst.strInMax(@SERIAL_IN, 100)                               'This is the line that receives the string data from VB6
                                                                  'and stores it in SERIAL_IN.
      pst.str(@SERIAL_IN)                                         'For the demo, we now send that same data back out to VB6.
      pst.str(string("  (Sent from Greg's Propeller)", 13, 10))   'We follow it with a note that this is coming back from the
                                                                  'Propeller chip.                            
      waitcnt(clkfreq*1 + cnt)                                    'To slow things down a little in testing, I inserted this
                                                                  'wait cycle.  It can be removed for a real project.
      led_on_off := str_to_dec(@SERIAL_IN)                        'Here's where the text '1' or '0' is sent off to the
                                                                  'str_to_dec routine for conversion to a decimal number.
                                                                  'The number is then stored in 'led_on_off'
      Set_LED(output_pin)                                         'Now the Set_LED method is called to actually turn on/off the LED.

      
PUB Set_LED(Pin)                           'This is the routine to turn the LED on or off.  Send the pin number to this routine.
  dira [output_pin]~~                      'Sets the pin to output using ~~
  outa[output_pin] := led_on_off           'Uses the value in led_on_off to send either a 1 or 0 out to pin 0 to turn LED on or off.
     
PUB str_to_dec(str) | index                       'This routine takes in a string representation of a number and converts it to decimal
  result := 0                                     'Initialize the result variable with zero.
  repeat index from 0 to (strsize(str) - 1)       'We are only using one digit, but this routine can convert larger numbers, so it
                                                  'looks at each text character that might need conversion to decimal.
    if byte[str][index] == "."                    'It quits if it finds a decimal point - we're only going to work with integers here.
      quit
    result *= 10                                  'This routine is basically starting from the left side of your string 'number' and 
    result += byte[str][index] - "0"              'converting each character to a number, and then each time it finds an additional
                                                  'character to convert as it moves from right to left, it multiplies the previous
                                                  'result by 10, and adds the new digit to that result. I'm accustomed to seeing shift left
                                                  'commands in Assembly Language dealing with binary numbers, so this routine is
                                                  'pretty much like shifting left in decimal (after the character to number conversion,
                                                  'of course.)

{{ MIT License:
Copyright (c) 2011 Greg Denson 

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following
conditions: 

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                                 

}}      