#! /bin/sh
# launch \
exec tclsh "$0" ${1+"$@"}

# Intellectual property information START
#
# Copyright (c) 2024 Ivan Bityutskiy
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Intellectual property information END

# Description START
#
# Creating passphrase with 100 words randomly selected out of words source file.
# https://en.wikipedia.org/wiki/Passphrase
# Words source file must be created by 'makeSources.sh' from original file.
# It has spaces and newlines stripped from it and contains a sigle line of
# characters from all words joined together.
# If the script has 1 or 2 arguments, 1st argument is used as a minimum value,
# and 2nd argument is used as maximum value for the length of words. (1..=99)
#
# Usage:
# ./getPassphraseWs.tcl
# OR
# ./getPassphraseWs.tcl min_word_length max_word_length
# Description END

# Getting true random numbers from /dev/urandom on *nix systems.
# Procedure will read all the data from /dev/urandom in a single step and store
# it in a list. This is a better solution than reading from /dev/urandom every
# single time, opening and closing the file. For example instead of opening and
# closing /dev/urandom 100 times, it will be done only once.
proc genRandList {maxValue {minValue 0} {amtBytes 800}} {
  set devUrandom [open /dev/urandom rb]
  # Converting binary data into unsigned integers for future use:
  # Order can be 'little endian', 'big endian', or 'native' for the CPU;
  # m = 64 bit integer in native order; n = 32 bit integer in native order;
  # u = unsigned flag; * = count, all bytes will be stored in one variable
  binary scan [chan read $devUrandom $amtBytes] mu* randList
  chan close $devUrandom
  # Storing random numbers in a list
  foreach {num} $randList {
    lappend randResult [expr {$num % ($maxValue - $minValue + 1) + $minValue}]
  }
  return $randResult
}

# Words source file
set wrds /tmp/sources.txt
# If the words source file doesn't exist, or isn't readable, exit
if {![file exists $wrds] || ![file readable $wrds]} then {
  chan puts stderr "\nUnable to read \"$wrds\" file!\n"
  exit 1
}

# Getting random lengths of words:
# Maximum limit for the range
set max 11
# Minimum limit for the range
set min 4
# If script has argumens, use them as word length values
if {$argc > 0} then {
  scan [lindex $argv 0] %2d min
  scan [lindex $argv 1] %2d max
  if {$min <= 0 || $max <= 0 || $min > $max} then {
    set max 11
    set min 4
  }
}
# How many bytes to read at once (8 bytes == 64 bits == 64 bit integer)
set readSingle 8
# How many integers are needed
set readAll [expr {$readSingle * 100}]
# List of amounts of characters to read
set lAmt [genRandList $max $min $readAll]

# Getting random access positions:
# Maximum limit for the range
set max [file size $wrds]
# Minimum limit for the range
set min 0
# List of random seek positions
set lSeek [genRandList $max $min $readAll]

# Procedure will generate the passphrase
proc genPw {} {
  # Procedure call '$::max' more than 15 times, linking with 'global' to improve
  # performance. Linking is expensive for less then 15 calls to a variable.
  global max
  # Opening words source file in binary mode
  set fc [open $::wrds rb]
  # Using newline character around passphrase for better readability
  set pwStr \n
  # Setting a random access position within a file, reading a word into 'pwStr'
  foreach pos $::lSeek amt $::lAmt {
    if {$pos + $amt > $max} then {
      set pos [expr {$max - $amt}]
    }
    chan seek $fc $pos
    append pwStr [chan read $fc $amt] { }
  }
  # Closing words source file
  chan close $fc
  # Trimming the last space character from a string
  set pwStr [string trimright $pwStr]
  # Using newline character around passphrase for better readability
  append pwStr \n
  # Returning the passphrase
  return $pwStr
}

# Printing the passphrase
chan puts stdout [genPw]

# END OF SCRIPT

