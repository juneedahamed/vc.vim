" Vim syntax file
" Borrowed from svnj, initally authored by Mikhail Borisov, github userid borman
" Language: VC 'blame' output
"

if exists("b:vc_blame_syntax")
	finish
endif

syn match svnTimestamp /^\S\+ \S\+/ nextgroup=svnRevision skipwhite
syn match svnRevision /\S\+/ nextgroup=svnAuthor contained skipwhite
syn match svnAuthor /\S\+/ contained skipwhite

" Apply highlighting
let b:vc_blame_syntax = "vc_blame_syntax"

hi def link svnRevision Number
hi def link svnAuthor Operator
hi def link svnTimestamp Comment

