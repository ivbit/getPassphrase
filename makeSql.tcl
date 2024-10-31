#! /bin/sh
# launch tclsh \
exec tclsh "$0"

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
# The script uses the source file in text format to create a SQL file,
# which can be used in SQLite 3 to create a database file. Source file
# contains a long list of ASCII words, each on a separate line. Those
# words are used to create passphrases.
# 
# Usage:
# ./makeSql.tcl
# Create database in SQLite 3:
# sqlite3 ./source.db
# .read /tmp/source.sql
# .schema
# .tables
# .mode list
# SELECT count(word) FROM words;
# SELECT word FROM words;
# .system clear
# .q
# Description END

set inFile ./source.txt
set outFile /tmp/source.sql

set year [clock format [clock seconds] -format %Y]
set author {Ivan Bityutskiy}
set email {}
set copyright [list "-- Intellectual property information START
--
-- Copyright (c) $year $author $email
--
-- Permission to use, copy, modify, and distribute this software for any
-- purpose with or without fee is hereby granted, provided that the above
-- copyright notice and this permission notice appear in all copies.
--
-- THE SOFTWARE IS PROVIDED \"AS IS\" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
-- WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
-- ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
-- WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
-- ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
-- OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
--
-- Intellectual property information END
"]

set prefix {
  {PRAGMA foreign_keys=OFF;}
  {BEGIN TRANSACTION;}
  {CREATE TABLE words(id integer primary key, word text);}
}
set suffix [list "COMMIT;\n"]

set bol {INSERT INTO words(word) VALUES('}
set eol {');}

# ASCII text in files - opening files in binary mode to improve performance
set f [open $inFile rb]
set t [open $outFile wb]

chan puts $t [
  join [
    concat $copyright $prefix [
      lmap word [chan read -nonewline $f] {
        string cat $bol $word $eol
      }] $suffix] \n]

chan close $f
chan close $t

chan puts stderr "\nFile \"$outFile\" has been successfully created.\n"

# END OF SCRIPT

