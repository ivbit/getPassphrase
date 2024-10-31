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
# single line, removing all spaces and newlines.
# I don't like TclLib's 'struct::list shuffle' implementation:
# /usr/share/tcltk/tcllib1.21/struct/list.tcl
# Using 'GNU shuf' instead.
# 
# Usage:
# ./makeSources.sh
#
# Description END

# Shuffle words source file, save as new file
src="./source.txt"
dst="/tmp/sources.txt"

shuf "$src" |>|"$dst" tr -d '\n'

# END OF SCRIPT

