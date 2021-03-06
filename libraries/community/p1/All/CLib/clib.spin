'******************************************************************************
' C Function Library in Spin
' Author: Dave Hein
' Copyright (c) 2010
' See end of file for terms of use.
'******************************************************************************
'******************************************************************************
' Revison History
' v1.0   - 4/2/2010 First official release
' v1.0.1 - 5/3/2010 Fixed a bug in memcpy and memset.  Optimized for small sizes
'******************************************************************************
{{ 
  This object provides some standard C library functions written in Spin.
  There are three main types of functions provided -- string manipulation,
  formatted I/O and memory allocation.  C functions that use a variable
  number of arguments are supported in two ways.  The first way uses
  unique function names for each number of arguments that is used, such
  as printf3 for a printf with three arguments.  The second way uses an
  argument list, such as vprintf.  The argument list consists of an array
  of longs that holds the values of the arguments.

  The start function must be called before using any of the serial I/O or
  memory allocation functions.  It will setup a a serial port that transmits on
  pin 30 and receives on pin 31 at 57600 baud.  It will also establish a stack
  space of 200 longs for the top object.  The malloc heap begins immediately
  after the stack space, and extends to the end of the RAM.

  Serial I/O and stack space parameters can be specified by calling start1
  instead of start.  The first four parameters of start1 are the same as those
  used in a call to the FullDuplexSerial start function.  The fifth parameter,
  stacksize, defines the size in longs of the stack space.

  Additional serial ports can be created by calling the openserial routine.
  In additional to rxpin, txpin, mode and baudrate the receive and transmit
  buffer sizes are also specified.  A fileinfo pointer is returned, which
  is used when calling fputc, fgetc and all of the other f... routines.

  The functions puts, putchar and getchar use the str1, tx1 and rx1 methods
  of a modified FullDuplexSerial object.  This object, cserial, allows for multiple
  serial ports through the use of a structer pointer called a handle.  See
  cserial.spin for more information.

  clib uses a file info structure to access I/O devices, such as the serial port.
  The I/O routines that start with the letter "f" require a pointer to the file info
  struction, wich is normally named pfileinfo.  Currently, only serial I/O and
  string I/O are supported.  Future releases will also support file I/O.
}}

OBJ
  mem : "cmalloc"
  ser : "cserial"
  fstr : "cfloatstr"

CON
  file_info_string = 1
  file_info_serial = 0
  file_info_size   = 8
  file_info_type   = 0
  file_info_data   = 1

DAT
  stdout long 0
  stdin  long 0

'******************************************************************************  
' Initialization Routines
'******************************************************************************  
PUB start
{{
  This routine sets a top object stack size of 200 longs followed by the malloc
  heap space.  It initializes the standard I/O serial port to receive on P31 and
  transmit on P30 at 57,600 baud.  The serial port mode flag is set to use a
  lock for multi-cog operation.  It returns the stdio pointer if successful, or
  NULL if not.
}}
  return start1(31, 30, %10000, 57600, 200)

PUB start1(rxpin, txpin, mode, baudrate, stacksize)
{{
  This routine calls the malloc initialization routine.  The number of longs in
  the top object stack is set by the value of "stacksize".  It also calls the
  openserial function to initialize the standard I/O serial port.  It returns the
  stdio pointer if successful, or NULL if not.
}}
  mem.mallocinit(stacksize)
  stdin := stdout := openserial(rxpin, txpin, mode, baudrate, 64, 256)
  return stdout

PUB openserial(rxpin, txpin, mode, baudrate, rxsize, txsize) | pfileinfo, file_data
{{
  This routine allocates memory for a file info and serial port data structure.
  It calls the start1 function in the cserial object to create a serial port in
  the next available cog.  It returns a pointer to the file info structure if
  successful, or a NULL value if not successful.
}}
  pfileinfo := malloc(file_info_size + ser#header_size + rxsize + txsize)
  ifnot pfileinfo
    return 0
  file_data := pfileinfo + file_info_size 
  long[pfileinfo][file_info_type] := file_info_serial
  long[pfileinfo][file_info_data] := file_data
  ifnot ser.start1(file_data, rxpin, txpin, mode, baudrate, rxsize, txsize)
    free(pfileinfo)
    return 0
  return pfileinfo

'******************************************************************************  
' String Routines
'******************************************************************************  
PUB strcmp(str1, str2)
{{
  This routine compares two strings and returns a value of zero if they are
  equal.  If "str1" is greater than "str2" it will return a positive value, and
  if "str1" is less than "str2" it will return a positive value.
}}
  if (strcomp(str1, str2))
    return 0
  repeat while (byte[str1] and byte[str1] == byte[str2])
    str1++
    str2++
  return byte[str1] - byte[str2]

PUB strncmp(str1, str2, n)
{{
  This routine compares the first "n" characters of two strings.  It returns a
  value of zero if they are equal.  If "str1" is greater than "str2" it will
  return a positive value, and if "str1" is less than "str2" it will return a
  negative value.
}}
  if (n =< 0)
    return 0
  repeat while (--n and byte[str1] and byte[str1] == byte[str2])
    str1++
    str2++
  return byte[str1] - byte[str2]

PUB memcpy(dest, src, n) | bitflag
{{
  This routine copies "n" bytes from the memory location pointed to by "src" to
  the memory location pointed to by "dest".  The copy is performed as either longs,
  words or bytes depending on the least significant bits of the parameters.  A
  bytemove is performed if "n" is less than 180 to avoid the extra computational
  overhead for small mem copies.  The value of "dest" is returned.
}}
  if n < 180
    bytemove(dest, src, n)
    return dest
  bitflag := (dest | src | n) & 3
  ifnot bitflag
    longmove(dest, src, n >> 2)
  elseifnot bitflag & 1
    wordmove(dest, src, n >> 1)
  else
    bytemove(dest, src, n)
  return dest

PUB memset(dest, val, n) | bitflag
{{
  This routine sets the "n" bytes pointed to by "dest" to the value in the
  least significant byte of "val".  It returns the value of "dest".  memset
  uses either bytefill, wordfill or longfill depending on the least significant
  bits of the parameters.  A bytefill is used when "n" is less than 220 to
  avoid the extra computational overhead for small buffers. 
}}
  if n < 220
    bytefill(dest, val, n)
    return dest
  val &= 255
  bitflag := (dest | n) & 3
  ifnot bitflag
    val |= (val << 24) | (val << 16) | (val << 8)
    longfill(dest, val, n >> 2)
  elseifnot bitflag & 1
    val |= (val << 8)
    wordfill(dest, val, n >> 1)
  else
    bytefill(dest, val, n)
  return dest

PUB strcat(dst, src) | dlen, slen
{{
  This routine concatenates the string pointed to by "src" to the string at
  "dst".  It returns the value of "dst".
}} 
  dlen := strsize(dst)
  slen := strsize(src) + 1
  bytemove(dst + dlen, src, slen)
  return dst

PUB strcpy(dst, src) | slen
{{
  This routine copies the string pointed to by "src" to the location pointed
  to by "dst".  It returns the value of "dst".
}}
  slen := strsize(src) + 1
  bytemove(dst, src, slen)
  return dst

PUB strncpy(dst, src, num) | slen
{{
  This routine copies the first num bytes from the src string to the dst string.
  If src contains less than num bytes, then only the bytes contained in the src
  string are copied, and the remaining bytes are set to zero.  Note that if num
  is less than or equal to the string length of src the dst string will not be
  terminated with a NULL.  This routine returns the value of the dst pointer.
}}
  if (num < 1)
    return dst
  slen := strsize(src)
  if (slen > num)
    slen := num
  bytemove(dst, src, slen)
  bytefill(dst + slen, 0, num - slen)
  return dst

PUB isdigit(char)
{{
  This routine return true if the value of "char" represents an ASCII decimal
  digit between 0 and 9.  Otherwise, it returns false.
}}
  return char => "0" and char =< "9"

PUB itoa(number, str, base) | mask, shift, nbits, str0
{{
  This routine converts the 32-bit value in "number" to an ASCII string at the
  location pointed to by "str".  The numeric base is determined by the value
  of "base", and must be either 2, 4, 8, 10 or 16.  Leading zeros are suppressed,
  and the number is treated as unsigned except when the base is 10.  The length
  of the resulting string is returned.
}}
  str0 := str
  case base
    10   : return itoa10(number, str)
    2    : nbits := 1
    4    : nbits := 2
    8    : nbits := 3
    16   : nbits := 4
    other:
      byte[str] := 0
      return 0
  mask := base - 1
  if (nbits == 3)
    shift := 30
  else
    shift := 32 - nbits
  repeat while shift > 0 and ((number >> shift) & mask) == 0
    shift -= nbits
  repeat while (shift => 0)
    byte[str++] := HexDigit[(number >> shift) & mask]
    shift -= nbits
  byte[str++] := 0
  return str - str0 - 1

'******************************************************************************  
' Output Routines
'******************************************************************************  
PUB puts(str)
{{
  This routine sends the contents of the string pointed to by "str" to the
  standard output.
}}
  ser.str1(long[stdout][file_info_data], str)
  
PUB putchar(char)
{{
  This routine sends the character in "char" to the standard output.
}}
  ser.tx1(long[stdout][file_info_data], char)
  
PUB fputc(char, pfileinfo) | file_type, file_data
{{
  This routine sends the character in "char" to the output device defined by
  "pfileinfo".
}}
  file_type := long[pfileinfo][file_info_type]
  file_data := long[pfileinfo][file_info_data]
  if (file_type == file_info_serial)
    ser.tx1(file_data, char)
  elseif (file_type == file_info_string)
    byte[file_data++] := char
    long[pfileinfo][1] := file_data
    
PUB fputs(str, pfileinfo) | file_type, file_data, len
{{
  This routine sens the string pointed to by "str" to the output device defined
  by "pfileinfo".
}}
  file_type := long[pfileinfo][file_info_type]
  file_data := long[pfileinfo][file_info_data]
  if (file_type == file_info_serial)
    ser.str1(file_data, str)
  elseif (file_type == file_info_string)
    len := strsize(str)
    bytemove(file_data, str, len)
    long[pfileinfo][1] := file_data + len

PUB printf0(format)
{{
  This is a version of "printf" with a format string and no additional parameters.
}}
  vfprintf(stdout, format, @format)

PUB printf1(format, arg1)
{{
  This is a version of "printf" with a format string and one additional parameter.
}}
  vfprintf(stdout, format, @arg1)

PUB printf2(format, arg1, arg2)
{{
  This is a version of "printf" with a format string and two additional parameters.
}}
  vfprintf(stdout, format, @arg1)

PUB printf3(format, arg1, arg2, arg3)
{{
  This is a version of "printf" with a format string and three additional parameters.
}}
  vfprintf(stdout, format, @arg1)

PUB printf4(format, arg1, arg2, arg3, arg4)
{{
  This is a version of "printf" with a format string and four additional parameters.
}}
  vfprintf(stdout, format, @arg1)

PUB printf5(format, arg1, arg2, arg3, arg4, arg5)
{{
  This is a version of "printf" with a format string and five additional parameters.
}}
  vfprintf(stdout, format, @arg1)

PUB printf6(format, arg1, arg2, arg3, arg4, arg5, arg6)
{{
  This is a version of "printf" with a format string and six additional parameters.
}}
  vfprintf(stdout, format, @arg1)

PUB vprintf(format, arglist)
{{
  This routine uses the string pointed to by "format" to send a formatted string
  to the standard output.  The parameter "arglist" points to a long array of
  values that are merged with the output string dependent on the contents of the
  format string.
}}
  vfprintf(stdout, format, arglist)
 
PUB sprintf0(str, format)
{{
  This is a version of "sprintf" with a format string and no additional parameters.
}}
  vsprintf(str, format, @format)

PUB sprintf1(str, format, arg1)
{{
  This is a version of "sprintf" with a format string and one additional parameter.
}}
  vsprintf(str, format, @arg1)
 
PUB sprintf2(str, format, arg1, arg2)
{{
  This is a version of "sprintf" with a format string and two additional parameters.
}}
  vsprintf(str, format, @arg1)
 
PUB sprintf3(str, format, arg1, arg2, arg3)
{{
  This is a version of "sprintf" with a format string and three additional parameters.
}}
  vsprintf(str, format, @arg1)
 
PUB sprintf4(str, format, arg1, arg2, arg3, arg4)
{{
  This is a version of "sprintf" with a format string and four additional parameters.
}}
  vsprintf(str, format, @arg1)
 
PUB sprintf5(str, format, arg1, arg2, arg3, arg4, arg5)
{{
  This is a version of "sprintf" with a format string and five additional parameters.
}}
  vsprintf(str, format, @arg1)
 
PUB sprintf6(str, format, arg1, arg2, arg3, arg4, arg5, arg6)
{{
  This is a version of "sprintf" with a format string and six additional parameters.
}}
  vsprintf(str, format, @arg1)

PUB vfprintf(pfileinfo, format, arglist)| str[25]
{{
  This routine prints a formatted string to the output pointed to by "pfileinfo".
  It calls vsprintf to generate the formatted string in the stack string array
  "str", and then sends it to the output stream by calling fputs.  The format is
  pointed to by "format" and the parameters are contained on a long array pointed
  to by "arglist".  Note, care must be taken to ensure that the formatted output
  string will fit within the 100-byte space provided by "str".  Also, the stack
  must be large enough to accomodate "str".
}}
  vsprintf(@str, format, arglist)
  fputs(@str, pfileinfo)
    
PUB vsprintf(str, format, arglist) | arg, width, digits, format0
{{
  This routines generates a formatted output string based on the string pointed
  to by "format".  The parameter "arglist" is a pointer to a long array of values
  that are merged into the output string.  The characters in the format string
  are copied to the output string, exept for special character sequences that
  start is % or \.  The % character is used to merge values from "arglist".  The
  characters following the % are as follows: %[0][width][.digits][l][type].
  If a "0" immediately follows the % it indicates that leading zeros should be
  displayed.  The optional "width" paramter specifieds the minimum width of the
  field.  The optional ".digits" parameter specifies the number of fractional
  digits for floating point, or it may also be used to specify leading zeros and
  the minimum width for integer values.  The "l" parameter indicates long values,
  and it is ignored in this implementation.  The "type" parameter is a single
  character that indicates the type of output that should be generated.  It can
  be one of the following characters:
  
  d - signed decimal number
  i - same as d
  u - unsigned decimal number
  x - hexidecimal number
  o - octal number
  b - binary number
  c - character
  s - string
  e - floating-point number using scientific notation
  f - floating-point number in standard notation
  % - prints the % character

  The \ character is used to print the following special characters:

  n - newline.  The linefeed is generated in this implementation
  t - tab, or ASCII 8
  \ - prints the \ character
  xxx - this inserts the value of a 3-digital octal number between 000 and 377

  Note, care must be taken the the generated output string does not exceed the size
  of the string.  A string size of 100 bytes is normally sufficient.  
}}
  arg := long[arglist]
  arglist += 4
  repeat while (byte[format])
    if (byte[format] == "%")
      format0 := format++
      if (byte[format] == "0")
        width := -1
        digits := getvalue(@format)
      else
        width := getvalue(@format)
        if (byte[format] == ".")
          format++
          digits := getvalue(@format)
        else
          digits := -1
      if (byte[format] == "l")
        format++
      case byte[format]
        "d", "i": str := putdec(str, arg, width, digits)
        "u"     : str := putudec(str, arg, width, digits)
        "o"     : str := putoctal(str, arg, width, digits)
        "b"     : str := putbinary(str, arg, width, digits)
        "x"     : str := puthex(str, arg, width, digits)
        "f"     : str := fstr.putfloatf(str, arg, width, digits)
        "e"     : str := fstr.putfloate(str, arg, width, digits)
        "c"     : byte[str++] := arg
        "%"     : byte[str++] := "%"
        "s"     :
          strcpy(str, arg)
          str += strsize(arg)
        other   :
          byte[str++] := "%"
          format := format0
      format++
      arg := long[arglist]
      arglist += 4
    elseif (byte[format] == 92)
      case byte[++format]
        0       : quit
        "t"     : byte[str++] := 8
        "n"     : byte[str++] := 13
        "0".."3": byte[str++] := getoctalbyte(@format)
        other   : byte[str++] := byte[format]
      format++
    else
      byte[str++] := byte[format++]
  byte[str++] := 0

PRI getoctalbyte(pstr) | str
{{
  This private routine is used to read a 3-digit octal number contained
  in the format string.
}}
  str := long[pstr]
  repeat 3
    if (byte[str] & $f8) == "0"
      result := (result << 3) + (byte[str++] & 7)
    else
      quit
  long[pstr] := str - 1

PRI itoa10(number, str) | str0, divisor, temp
{{
  This private routine is used to convert a signed integer contained in
  "number" to a decimal character string.  It is called by itoa when the
  numeric base parameter has a value of 10.
}}
  str0 := str
  if (number < 0)
    byte[str++] := "-"
    if (number == $80000000)
      byte[str++] := "2"
      number += 2_000_000_000
    number := -number
  elseif (number == 0)
    byte[str++] := "0"
    byte[str] := 0
    return 1
  divisor := 1_000_000_000
  repeat while (divisor > number)
    divisor /= 10
  repeat while (divisor > 0)
    temp := number / divisor
    byte[str++] := temp + "0"
    number -= temp * divisor
    divisor /= 10
  byte[str++] := 0
  return str - str0 - 1

PRI getvalue(pstr) | str
{{
  Thie private routine is used to extract the width and digits
  fields from a format string.  It is called by vsprintf.
}}
  str := long[pstr]
  ifnot isdigit(byte[str])
    return -1
  result := 0
  repeat while isdigit(byte[str])
    result := (result * 10) + byte[str++] - "0"
  long[pstr] := str

DAT
HexDigit byte "0123456789abcdef"

PRI printpadded(str, numstr, count, width, digits)
{{
  This private routine is used to generate a formatted string
  containg at least "width" characters.  The value of count
  must be identical to the length of the string in "str".
  Leading spaces will be generated if width is larger than the
  maximum of count and digits.  Leading zeros will be generated
  if digits is greater than count.
}}
  if digits < count
    digits := count
  repeat while (width-- > digits)
    byte[str++] := " "
  if byte[numstr] == "-"
    byte[str++] := byte[numstr++]
    digits--
  repeat while (digits-- > count)
    byte[str++] := "0"
  strcpy(str, numstr)
  return str + strsize(numstr)

PRI putbinary(str, number, width, digits) | count, numstr[9]
{{
  This private routine converts a number to a string of binary digits.
  printpadded is called to insert leading blanks and zeros.
}}
  count := itoa(number, @numstr, 2)
  return printpadded(str, @numstr, count, width, digits)

PRI putoctal(str, number, width, digits) | count, numstr[3]
{{
  This private routine converts a number to a string of octal digits.
  printpadded is called to insert leading blanks and zeros.
}}
  count := itoa(number, @numstr, 8)
  return printpadded(str, @numstr, count, width, digits)

PRI puthex(str, number, width, digits) | count, numstr[3]
{{
  This private routine converts a number to a string of hexadecimal digits.
  printpadded is called to insert leading blanks and zeros.
}}
  count := itoa(number, @numstr, 16)
  return printpadded(str, @numstr, count, width, digits)
   
PRI putdec(str, number, width, digits)| count, numstr[3]
{{
  This private routine converts a signed number to a string of decimal
  digits.  printpadded is called to insert leading blanks and zeros.
}}
  count := itoa10(number, @numstr)
  return printpadded(str, @numstr, count, width, digits)

PRI putudec(str, number, width, digits) | count, numstr[3], adjust
{{
  This private routine converts an unsigned number to a string of decimal
  digits.  printpadded is called to insert leading blanks and zeros.
}}
  adjust := 0
  repeat while (number < 0)
    number -= 1_000_000_000
    adjust++
  count := itoa10(number, @numstr)
  byte[@numstr] += adjust
  return printpadded(str, @numstr, count, width, digits)

'******************************************************************************  
' Input Routines
'******************************************************************************  
PUB getchar
{{
  This routine returns a single character from the standard input.  It will not
  return until a character has been received.
}}
  return ser.rx1(long[stdin][file_info_data])

PUB gets(str) | char, str0
{{
  This routine returns a string from the standard input.  It will not return until
  is has received a carriage return.  The carriage return is not included in the
  returned string.  Received characters are echoed back out ot the the serial port.
  Backspaces will cause the previous character to be removed from the buffer, and
  a character sequence of backspace, space and backspace will be transmitted to the
  serial port to erase the previous character.  Backspace characters are not inserted
  into the string.
}}
 str0 := str
  repeat
    char := getchar
    if (char == 8)
      if (str > str0)
        putchar(8)
        putchar(" ")
        putchar(8)
        str--
      next
    putchar(char)
    if (char == 13)
      char := 0
    byte[str++] := char
  while char

PUB fgetc(pfileinfo) | char, file_type, file_data
{{
  This routine returns a single character from the input device defined by "pfileinfo".
  It will not return until a character has been received.
}}
  file_type := long[pfileinfo][file_info_type]
  file_data := long[pfileinfo][file_info_data]
  if (file_type == file_info_serial)
    char := ser.rx1(file_data)
  elseif (file_type == file_info_string)
    char := byte[file_data++]
    long[pfileinfo][1] := file_data

PUB fgets(str, size, pfileinfo) | char, file_type, file_data
{{
  This routine returns a string from the input device defined by "pfileinfo".  It will
  return until it has either received a carriage return or "size" number of characters.
}}
  file_type := long[pfileinfo][file_info_type]
  file_data := long[pfileinfo][file_info_data]
  size--
  if (pfileinfo == stdin)
    gets(str)
  elseif (file_type == file_info_serial)
    repeat while (size > 0)
      char := ser.rx1(file_data)
      byte[str++] := char
      size--
      if (char == 13)
        quit
    byte[str] := 0
  elseif (file_type == file_info_string)
    strncpy(file_data, str, size)
    if (size > 0)
      byte[str+size] := 0
    long[pfileinfo][1] += strsize(str)

PUB scanf1(format, parg1)
{{
  This routine is a version of "scanf" with a format string and one parameter.
}}
  vscanf(format, @parg1)

PUB scanf2(format, parg1, parg2)
{{
  This routine is a version of "scanf" with a format string and two parameters.
}}
  vscanf(format, @parg1)

PUB scanf3(format, parg1, parg2, parg3)
{{
  This routine is a version of "scanf" with a format string and three parameters.
}}
  vscanf(format, @parg1)

PUB scanf4(format, parg1, parg2, parg3, parg4)
{{
  This routine is a version of "scanf" with a format string and four parameters.
}}
  vscanf(format, @parg1)

PUB vscanf(format, arglist) | str[25]
{{
  This routine reads a string from the standard input using gets, and it converts
  the data based on the format in the "format" string.  The converted values are
  stored at the locations determined by the list of long pointers in "arglist".
  See vsscanf for the description of the format string.
}}
  gets(@str)
  vsscanf(@str, format, arglist)

PUB sscanf1(str, format, parg1)
{{
  This is a version of sscanf with a format string and one parameter.
}}
  vsscanf(str, format, @parg1)
  
PUB sscanf2(str, format, parg1, parg2)
{{
  This is a version of sscanf with a format string and two parameters.
}}
  vsscanf(str, format, @parg1)
  
PUB sscanf3(str, format, parg1, parg2, parg3)
{{
  This is a version of sscanf with a format string and three parameters.
}}
  vsscanf(str, format, @parg1)
  
PUB sscanf4(str, format, parg1, parg2, parg3, parg4)
{{
  This is a version of sscanf with a format string and four parameters.
}}
  vsscanf(str, format, @parg1)
  
PUB vsscanf(str, format, arglist) | parg
{{
  This routine converts the contents of the string pointed to by "str" into
  numerical values that are stored at the locations derermined by the list of
  long pointers in "arglist".  The format string contains conversion flags,
  which are prefixed with the % character.  The list of conversion flags is
  as follows:

  b - Convert a binary number
  o - Convert an octal number
  d - Convert a signed decimal number
  x - Convert a hexadecimal number
  f - Convert a floating point number
  e - Same as f

  Any other characters will be ignored, and will cause a character to be skipped
  on the input string.  Leading spaces are also ignored when converting a
  number.
}}
  parg := long[arglist]
  arglist += 4
  repeat while byte[format]
    if byte[format++] == "%"
      case byte[format]
        "b" :  long[parg] := getbin(@str)
        "o" :  long[parg] := getoct(@str)
        "d" :  long[parg] := getdec(@str)
        "x"  : long[parg] := gethex(@str)
        "f", "e" : long[parg] := fstr.strtofloat(@str)
        other: str++
      format++
      parg := long[arglist]
      arglist += 4
    else
      str++

PRI getbin(pstr) | str
{{
  This private routine is used by vsscanf to convert a string of binary digits to
  a numerical value.
}}
  str := long[pstr]
  repeat while byte[str] == " "
    str++
  repeat while (byte[str] & $fe) == "0"
    result := (result << 1) + (byte[str++] & 1)
  long[pstr] := str

PRI getoct(pstr) | str
{{
  This private routine is used by vsscanf to convert a string of octal digits to
  a numerical value.
}}
  str := long[pstr]
  repeat while byte[str] == " "
    str++
  repeat while (byte[str] & $f8) == "0"
    result := (result << 3) + (byte[str++] & 7)
  long[pstr] := str

PRI gethex(pstr) | str, char
{{
  This private routine is used by vsscanf to convert a string of hexadecimal digits to
  a numerical value.
}}
  str := long[pstr]
  repeat while byte[str] == " "
    str++
  repeat
    char := byte[str++]
    case char
      "0".."9": result := (result << 4) + char - "0"
      "a".."f": result := (result << 4) + char - "a" + 10
      "A".."F": result := (result << 4) + char - "A" + 10
      other   : quit
  long[pstr] := str - 1


PRI getdec(pstr) | str, signflag
{{
  This private routine is used by vsscanf to convert a string of decimal digits to
  a numerical value.
}}
  signflag := 0
  str := long[pstr]
  repeat while byte[str] == " "
    str++
  if isdigit(byte[str])
    result:= byte[str] - "0"
  elseif byte[str] == "-"
    signflag := 1
  elseif byte[str] <> "+"
    long[pstr] := str
    return
  str++
  repeat while isdigit(byte[str])
    result := (result * 10) + byte[str++] - "0"
  if signflag
    result := -result
  long[pstr] := str

'******************************************************************************  
' Malloc Routines
'******************************************************************************  
PUB malloc(size)
{{
  This routine provides an interface to the malloc routine in cmalloc.spin
}}
  return mem.malloc(size)

PUB free(ptr)
{{
  This routine provides an interface to the free routine in cmalloc.spin
}}
  return mem.free(ptr)

PUB calloc(size)
{{
  This routine provides an interface to the calloc routine in cmalloc.spin
}}
  return mem.calloc(size)

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