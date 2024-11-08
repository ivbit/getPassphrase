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
# https://en.wikipedia.org/wiki/Passphrase
# Creating passphrase with 100 words randomly selected out of words source file.
# Words source file must be created by 'makeSources.sh' from original file.
# It has newlines stripped from it and contains a sigle line of characters
# from all words joined together in a single line.
# If the script has 1 or 2 arguments, 1st argument is used as a minimum value,
# and 2nd argument is used as maximum value for the length of words. (1..=99).
# 3rd argument is the path to a shuffled words source file. Args are optional.
# Script can be 'sourced' into the interpreter and used in interactive session.
# Helper procedures: 'cls' (clear the screen), 'repeat' (repeat script):
# 'repeat 10 {chan puts [genpw]}'.
# Procedure 'genpw' generates the passphrase.
#
# Usage:
# ./getPassphraseWs.tcl
# OR
# ./getPassphraseWs.tcl ?minWordLength? ?maxWordLength? ?sourceFile?
# Using invalid input 'z' to use default numeric values
# ./getPassphraseWs.tcl z z /tmp/source
# OR
# Start tclsh and source ./getPassphraseWs.tcl, then call genpw, 'puts [genpw]'
# tclsh
# source ./getPassphraseWs.tcl
# genpw
# for {set i 0} {$i ^ 30} {incr i} {chan puts [genpw]}
# Procedure 'cls' clears the screen on *nix systems.
# for {set i 0} {$i ^ 10} {incr i} {chan puts [genpw]}
# cls
# genpw
# repeat 40 {chan puts [genpw]}
#
# Description END

# User defined variables START
# Minimum number of characters in the word
set min 4
# Maximum number of characters in the word
set max 11
# Words source file
set inFile /tmp/sources.txt
# User defined variables END

# Colors for text messages
set cRed \u001b\[31m
set cBlu \u001b\[34m
set cNor \u001b\[0m

# Procedure definitions START
proc ErrorM {msg} {
  chan puts stderr \n$msg\n
  exit 1
}

proc FileN {fileName} {
  if {[package vsatisfies [info tclversion] 9-]} then {
    set fileName [file tildeexpand $fileName]
  }
  file normalize $fileName
}

# Check the numbers from arguments provided by a user
proc NumC "{usrMin $min} {usrMax $max}" {
  global min max
  set defaults [list $min $max]
  scan [string trimleft [string trim $usrMin] {0-+}] %2d min
  scan [string trimleft [string trim $usrMax] {0-+}] %2d max
  if {$min > $max} then {
    set min [lindex $defaults 0]
    set max [lindex $defaults 1]
  }
  return
}

# Getting true random numbers from /dev/urandom on *nix systems.
# Procedure will read all the data from /dev/urandom in a single step and store
# it in a list. This is a better solution than reading from /dev/urandom every
# single time, opening and closing the file. For example instead of opening and
# closing /dev/urandom 100 times, it will be done only once.
# On some BSD systems '/dev/urandom' must be replaced with '/dev/random'.
proc GenRandList {maxValue {minValue 0} {amtBytes 800}} {
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

# Procedure will generate the passphrase
proc genpw {} {
  global max inFile lSeek lAmt
  # Opening words source file in binary mode
  set fc [open $inFile rb]
  # Using newline character around passphrase for better readability
  set pwStr \n
  # Setting a random access position within a file, reading a word into 'pwStr'
  foreach pos $lSeek amt $lAmt {
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

# Clear screen on *nix systems
proc cls {} {
  chan puts -nonewline stderr "\u001b\[3J\u001b\[1;1H\u001b\[0J"
}

# Repeat command or script
proc repeat {count body} {
  set count [scan $count %d]
  if {
    $count eq {} ||
    $count < 1 ||
    $count > 999
  } then {
    set count 10
  }
  for {set iter 0} {$iter ^ $count} {incr iter} {
    set retCode [catch {uplevel 1 $body} result ropts]
    switch $retCode {
      0 {}
      3 {return}
      4 {}
      default {
        dict incr ropts -level
        return -options $ropts $result
      }
    }
  }
  return
}
# Procedure definitions END

# BEGINNING OF SCRIPT

# If script has arguments, interpret them as user defined settings
if {$argc > 0} then {
  # Process numbers from user input
  NumC {*}[lrange $argv 0 1]
  # Process file path from user input
  if {[lindex $argv 2] ne {}} then {
    set inFile [string trim [lindex $argv 2]]
  }
}

# Validate input path START
set inFile [FileN $inFile]
if {![file readable $inFile] || ![file isfile $inFile]} then {
  ErrorM "Unable to open input file \"$cRed$inFile$cNor\"!"
}
# Validate input path END

# How many bytes to read at once (8 bytes == 64 bits == 64 bit integer)
set readSingle 8
# How many integers are needed
set readAll [expr {$readSingle * 100}]
# List of amounts of characters to read
set lAmt [GenRandList $max $min $readAll]

# Getting random access positions:
# Maximum limit for the range
set max [file size $inFile]
# Minimum limit for the range
set min 0
# List of random seek positions
set lSeek [GenRandList $max $min $readAll]

# Printing the passphrase
chan puts stdout [genpw]

# END OF SCRIPT

