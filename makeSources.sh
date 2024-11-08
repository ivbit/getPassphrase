#! /bin/sh

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
# Original words source file contains a huge list of words, each word is
# located on a separate line. This script joins all words together into a
# single line, removing all newlines. User can supply optional arguments to
# this script. 1st arg is an output file, 2nd arg is an input file.
# I don't like TclLib's 'struct::list shuffle' implementation:
# /usr/share/tcltk/tcllib1.21/struct/list.tcl
# Using 'GNU shuf' instead.
# 
# Usage:
# ./makeSources.sh
# OR
# ./makeSources.sh ?outputFile? ?inputFile?
#
# Output file path '/tmp/new.txt':
# ./makeSources.sh /tmp/new.txt
#
# Empty string as 1st arg causes the script to use default output file:
# ./makeSources.sh '' ~/Documents/src.txt
#
# Description END

# Shuffle words source file, save as new file
outputFile="${1:-/tmp/sources.txt}"
inputFile="${2:-./source.txt}"

test -r "$inputFile" ||
{
  >&2 printf '\nUnable to read "\033[31m%s\033[0m" file!\n\n' "$inputFile"
  exit 1
}

shuf "$inputFile"|>|"$outputFile" tr -d '\n'

>&2 printf '\nFile "\033[32m%s\033[0m" was successfully created.\n\n' "$outputFile"

# END OF SCRIPT

