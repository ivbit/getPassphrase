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
# Creating passphrase with 100 words randomly selected out of SQLite3 database.
# Script can be 'sourced' into the interpreter and used in interactive session.
# Helper procedures: 'chnum' (change number of words), 'cls' (clear the screen),
# 'repeat' (repeat command or script): 'repeat 10 {chan puts [genpw]}'.
# Procedure 'genpw' generates the passphrase.
#
# Usage:
# ./getPassphraseSql.tcl
# OR
# ./getPassphraseSql.tcl ?numberOfWords? ?databaseFile?
# Database extension '.db' can be omitted.
# Using invalid input 'z' to get default number of words:
# ./getPassphraseSql.tcl z /tmp/source
# OR
# Start tclsh and source ./getPassphraseSql.tcl, then call genpw, 'puts [genpw]'
# tclsh
# source ./getPassphraseSql.tcl
# genpw
# for {set i 0} {$i ^ 30} {incr i} {chan puts [genpw]}
# Procedure 'chnum' can be used to change the number of words.
# Procedure 'cls' clears the screen on *nix systems.
# chnum 999
# for {set i 0} {$i ^ 10} {incr i} {chan puts [genpw]}
# cls
# chnum 10
# genpw
# repeat 40 {chan puts [genpw]}
#
# Description END

# User defined variables START
set numWords 100
set inFile huge.db
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

proc FileC {fileName} {
  expr {
      [file exists $fileName] &&
      [file isfile $fileName] &&
      [file readable $fileName]
  }
}

proc NumC {usrNum defaultNum} {
  set usrNum [string trimleft [string trim $usrNum] 0]
  if {
    [string is integer -strict $usrNum] &&
    [string is digit -strict $usrNum] &&
    $usrNum > 0 &&
    $usrNum <= 999
  } then {
    return $usrNum
  } else {
    return $defaultNum
  }
}

# Procedure will read all the data from /dev/urandom in a single step and store
# it in a list. This is a better solution than reading from /dev/urandom every
# single time, opening and closing the file. For example instead of opening and
# closing /dev/urandom 100 times, it will be done only once.
# On some BSD systems '/dev/urandom' must be replaced with '/dev/random'.
proc GenRandList {maxValue {amtBytes 800}} {
  set devUrandom [open /dev/urandom rb]
  # Converting binary data into unsigned integers for future use:
  # Order can be 'little endian', 'big endian', or 'native' for the CPU;
  # m = 64 bit integer in native order; n = 32 bit integer in native order;
  # u = unsigned flag; * = count, all bytes will be stored in one variable
  binary scan [chan read $devUrandom $amtBytes] mu* randList
  chan close $devUrandom
  # Storing random numbers (1..=$maxValue) in a list
  foreach {num} $randList {
    lappend randResult [expr {$num % $maxValue + 1}]
  }
  return $randResult
}

# Procedure will generate the passphrase
proc genpw {{dbObj data}} {
  global max readAll tcl_interactive 
  # Using newline character around passphrase for better readability
  set pStr \n
  foreach {rNum} [GenRandList $max $readAll] {
    append pStr [$dbObj onecolumn {SELECT word FROM words WHERE id = :rNum}] { }
  }
  # Don't do '$dbObj close' in interactive session
  if {!$tcl_interactive} then {
    $dbObj close
  }
  # Trimming the last space character from a string
  set pStr [string trimright $pStr]
  # Using newline character around passphrase for better readability
  append pStr \n
  # Returning the passphrase
  return $pStr
}

# Change the number of words in interactive session
proc chnum {usrNum} {
  global numWords readSingle readAll
  set readAll [expr {$readSingle * [NumC $usrNum $numWords]}]
  return
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
if {$argc} then {
  set numWords [NumC [lindex $argv 0] $numWords]
  if {[lindex $argv 1] ne {}} then {
    set inFile [lindex $argv 1]
  }
}

# Validate input path START
set inFile [FileN $inFile]
if {![FileC $inFile]} then {
  set inFileExt $inFile.db
  if {[FileC $inFileExt]} then {
    set inFile $inFileExt
  } else {
    ErrorM "Unable to open input file \"$cRed$inFile$cNor\"!"
  }
}
# Validate input path END

# Database operations
if {[catch {package require sqlite3}]} then {
  ErrorM "Tcl package ${cRed}sqlite3$cNor is not installed!"
}
sqlite3 data $inFile

# Getting true random numbers from /dev/urandom on *nix systems.
# Maximum limit for the range
try {
  set max [data onecolumn {SELECT count(word) FROM words}]
} on error {errMsg} {
  data close
  ErrorM "Database query ${cRed}failed$cNor!\n[string totitle $errMsg]!"
}
# How many bytes to read at once (8 bytes = 64 bits = 64 bit integer)
set readSingle 8
# How many integers are needed
set readAll [expr {$readSingle * $numWords}]

# Printing the passphrase
chan puts stdout [genpw]

# END OF SCRIPT

