#!/bin/bash

find `pwd` -name '*.[chS]' -print > cscope.files
find `pwd` -name '*.cpp' -print >> cscope.files
find `pwd` -name '*.cc' -print >> cscope.files
find `pwd` -name *.py -print >> cscope.files
cscope -Rbqk
ctags -R *

# in .vimrc
# if has("cscope")
#  set csprg=/usr/bin/cscope
#  set csto=1
#  set cst
#  set nocsverb
#  " add any database in current directory
#  if filereadable("cscope.out")
#     cs add cscope.out
#  endif
#  set csverb
#  endif
