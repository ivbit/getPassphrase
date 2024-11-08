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
# Creating a SQLite3 database with random words from shuffled 'source.txt' file.
# Words source file must be created by 'makeSources.sh' from original file.
# It has newlines stripped from it and contains a sigle line of characters from
# all words joined together.
# If the script has arguments, 1st arg is used as a minimum value, 2nd arg is
# used as maximum value for the amount of characters in a word (1..=99), 3rd arg
# is the number of words to store in the database, 4th arg is an output
# database directory path, 5th arg is a shuffled input text file path (name).
# All arguments are optional.
#
# Usage:
# ./makeDbShuffle.tcl
# OR
# ./makeDbShuffle.tcl ?min? ?max? ?numWords? ?outputDirectory? ?inputFile?
# Example using invalid input 'z' to use default numeric values and an empty
# string '' to use default value for output directory ('/tmp'):
# ./makeDbShuffle.tcl z z 100000 '' ~/src.txt
# Result is '/tmp/src.db' file with 100000 words.
#
# Description END

# User defined variables START
# Minimum number of characters in the word
set min 4
# Maximum number of characters in the word
set max 11
# Number of words to store in the database
set numWords 3000000
# File paths
set outDir /tmp
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
proc NumC "{usrMin $min} {usrMax $max} {usrNWo $numWords}" {
  global min max numWords
  set defaults [list $min $max]
  scan [string trimleft [string trim $usrMin] {0-+}] %2d min
  scan [string trimleft [string trim $usrMax] {0-+}] %2d max
  scan [string trimleft [string trim $usrNWo] {0-+}] %7d numWords
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
# Procedure definitions END

# BEGINNING OF SCRIPT

# If script has arguments, interpret them as user defined settings
if {$argc > 0} then {
  # Process numbers from user input
  NumC {*}[lrange $argv 0 2]
  # Process file paths from user input
  foreach {varName} {outDir inFile} {usrArg} [lrange $argv 3 4] {
    if {$usrArg ne {}} then {
      set $varName [string trim $usrArg]
    }
  }
}

# Validate input path START
set inFile [FileN $inFile]
if {![file readable $inFile] || ![file isfile $inFile]} then {
  ErrorM "Unable to open input file \"$cRed$inFile$cNor\"!"
}
# Validate input path END

# Validate output path START
set outDir [FileN $outDir]
set outFile [file join $outDir [file rootname [file tail $inFile]]].db
if {[file exists $outFile]} then {
  if {![file owned $outFile]} then {
    ErrorM "\"$cRed$outFile$cNor\": permission denied!"
  }
  if {[file isdirectory $outFile]} then {
    ErrorM "\"$cRed$outFile$cNor\" is a directory!"
  }
  if {![file isfile $outFile]} then {
    ErrorM "\"$cRed$outFile$cNor\": is not a regular file!"
  }
  file delete $outFile
}
if {[catch {file mkdir $outDir}]} then {
  ErrorM "\"$cRed$outDir$cNor\": write permission denied!"
}
if {![file writable $outDir]} then {
  ErrorM "\"$cRed$outDir$cNor\": write permission denied!"
}
# Validate output path END

# How many bytes to read at once (8 bytes == 64 bits == 64 bit integer)
set readSingle 8
# How many integers are needed
set readAll [expr {$readSingle * $numWords}]
# List of amounts of characters to read
set lAmt [GenRandList $max $min $readAll]

# Getting random access positions:
# Maximum limit for the range
set max [file size $inFile]
# Minimum limit for the range
set min 0
# List of random seek positions
set lSeek [GenRandList $max $min $readAll]

# Read text data from input file; binary mode because all ASCII characters
set data [open $inFile rb]
# Set a random access position within a file, read a word into 'sourceList'
foreach {position} $lSeek {amt} $lAmt {
  if {$position + $amt > $max} then {
    set position [expr {$max - $amt}]
  }
  chan seek $data $position
  lappend sourceList [chan read $data $amt]
}
chan close $data

# Write text data to a database file, create a new database
if {[catch {package require sqlite3}]} then {
  ErrorM "Tcl package ${cRed}sqlite3$cNor is not installed!"
}

sqlite3 data $outFile

try {
  data transaction {
    data eval {PRAGMA foreign_keys=OFF}
    data eval {CREATE TABLE words(id INTEGER PRIMARY KEY, word TEXT)}
    foreach word $sourceList {
      data eval {INSERT INTO words(word) VALUES(:word)}
    }
  }
} on error {errMsg} {
  data close
  ErrorM "Database transaction ${cRed}failed$cNor!\n[string totitle $errMsg]!"
} finally {
  data close
}
chan puts stderr "\nFile \"$cBlu$outFile$cNor\" was successfully created.\n"

# END OF SCRIPT

