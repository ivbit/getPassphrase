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
# Input file is a text file containing words separated by newline characters,
# each word on a separate line. Words consist of alphanumeric ASCII characters.
#
# Output file is a SQLite3 database file, with 1 table 'words' and 2 columns:
# 'id' and 'word'. Each word of input file will become a row entry in 'word'.
#
# Usage:
# Default input file is './source.txt', default output directory is '/tmp'.
# ./makeDb.tcl ?outputDirectory? ?inputFile?
#
# Examples:
# Specify an empty string '' to use default value for output directory
# ./makeDb.tcl '' ../source.txt
#
# '.' is current directory, output: './source.db'
# ./makeDb.tcl .
#
# Input: '~/Documents/src.txt', output: '/tmp/data/scr.db'
# ./makeDb.tcl /tmp/data ~/Documents/src.txt
#
# Description END

# User defined variables START
set outDir /tmp
set inFile source.txt
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
# Procedure definitions END

# If script has arguments, interpret them as user defined settings
if {$argc} then {
  if {[lindex $argv 0] ne {}} then {
    set outDir [lindex $argv 0]
  }
  if {[lindex $argv 1] ne {}} then {
    set inFile [lindex $argv 1]
  }
}

# Validate input path START
set inFile [FileN $inFile]
if {
  !(
    [file exists $inFile] &&
    [file isfile $inFile] &&
    [file readable $inFile]
  )
} then {
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

# Read text data from input file, binary mode because all ASCII characters
set data [open $inFile rb]
set sourceList [chan read -nonewline $data]
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

