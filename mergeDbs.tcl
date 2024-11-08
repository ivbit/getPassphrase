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
# This example shows how to merge SQLite3 database files together using Tcl.
# For test purposes there are 20 files names from s1.db up to s20.db.
# The database files are located in the same directory as this Tcl script.
# All database files are created using the same schema:
# CREATE TABLE words(id INTEGER PRIMARY KEY, word TEXT);
#
# Description END

# Populate a list with database file names.
for {set i 1} {$i <= 20} {incr i} {
  lappend dbFileList [file normalize s$i.db]
}

if {![file readable [lindex $dbFileList 0]]} then {
  chan puts stderr "\nThere are no database files in current directory!\n"
  exit 1
}

# Path to a file, which will contain the contents from all databases.
set outFile [file normalize huge.db]
# Delete the file if it already exists.
file delete $outFile

package require sqlite3

# Create a new empty file and 'db' object.
# 'db' object's methods will be used to manipulate databases.
sqlite3 db [file normalize huge.db]

# Create a new table and populate it with contents from attached databases.
# In the 'ATTACH' statement 'DATABASE' keyword can be omitted.
# ':dbFile' will be replaced by the contents of $dbFile Tcl variable.
# '$dbFile', ':dbFile', '@dbFile' all are valid variable references inside a
# SQL statement processed by 'db' object. '$' and ':' mean that variable value
# should be interpreted as TEXT if possible, '@' interpret as BLOB, if possible.
# Referenced variables don't need to be quoted inside the SQL statement.
try {
  db eval {PRAGMA foreign_keys=OFF}
  db eval {CREATE TABLE words(id INTEGER PRIMARY KEY, word TEXT)}
  foreach dbFile $dbFileList {
    db eval {ATTACH DATABASE :dbFile AS dbsource}
    db eval {INSERT INTO main.words(word) SELECT word FROM dbsource.words}
    db eval {DETACH DATABASE dbsource}
  }
} on error {errMsg} {
  db close
  chan puts stderr "Database transaction failed!\n[string totitle $errMsg]!"
  exit 1
} finally {
  db close
}

chan puts stderr "\nFile \"$outFile\" was successfully created.\n"

# END OF SCRIPT

# Created file 'huge.db' has 9999999 words in it.
# Database files were created from the interactive POSIX shell:
# for i in $(seq 20);do ./makeSources.sh /tmp/huge/s$i;done
# for i in $(seq 19);do ./makeDbShuffle.tcl 5 12 500000 /tmp/huge/dbs/ /tmp/huge/s$i;done
# ./makeDbShuffle.tcl 5 12 499999 /tmp/huge/dbs/ /tmp/huge/s20

# Reference documentation:
# https://www.sqlite.org/tclsqlite.html
# https://www.sqlite.org/lang_attach.html

