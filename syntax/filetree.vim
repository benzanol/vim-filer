" Match regexes to color groups
syn match FiletreeDirectory "[^→]*\/\s$"
syn match FiletreeExecutable "[^→]*\*\s$"
syn match FiletreePwd "^[/~].*/$"

syn match FiletreeRedirect ".*→ "
syn match FiletreeGitCommitted "✓"
syn match FiletreeGitAdded "✚"
syn match FiletreeGitModified "✗"

silent exec "syn match FiletreeIndent '" . filetree#Get("s:indent_marker") . "'"

" Link color groups to colors
let grey = synIDtrans(hlID("Comment"))
let red = synIDtrans(hlID("Directory"))
let green = synIDtrans(hlID("String"))
let purple = synIDtrans(hlID("Question"))

exec "hi FiletreeIndent ctermfg=" . synIDattr(grey, "fg#", "cterm") . " guifg=" . synIDattr(grey, "fg#", "gui")
exec "hi FiletreeDirectory ctermfg=" . synIDattr(red, "fg#", "cterm") . " guifg=" . synIDattr(red, "fg#", "gui")
exec "hi FiletreeRedirect ctermfg=" . synIDattr(purple, "fg#", "cterm") . " guifg=" . synIDattr(purple, "fg#", "gui")
exec "hi FiletreeExecutable ctermfg=" . synIDattr(green, "fg#", "cterm") . " guifg=" . synIDattr(green, "fg#", "gui")
exec "hi FiletreePwd ctermfg=" . synIDattr(red, "fg#", "cterm") . " guifg=" . synIDattr(red, "fg#", "gui") . " cterm=bold,underline gui=bold,underline"

hi FiletreeGitCommitted ctermfg=82  guifg=#5FFF00 cterm=bold gui=bold
hi FiletreeGitAdded ctermfg=75  guifg=#5FAFFF cterm=bold gui=bold
hi FiletreeGitModified ctermfg=203  guifg=#FF5F5F cterm=bold gui=bold
