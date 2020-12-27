function! filetree#colors#SetColors()
	" Get filetree icons
	let s:i = g:filetree_icons

	" Match regexes to color groups
	"exec "syn match FiletreeDirectory '[^" . s:i.f_redirect . "]*\\/\\s*$'"
	exec "syn match FiletreeDirectory '.*\/\s*$'"
	exec "syn match FiletreeExecutable '\\w[^" . s:i.f_redirect . "]*\\*\s*$'"
	syn match FiletreePwd "^[/~].*/$"
	syn match FiletreePwd "^/$"

	" exec "syn match FiletreeRedirect '.*" . s:i.f_redirect . " '"
	exec "syn match FiletreeGitCommitted '" . s:i.g_committed . "'"
	exec "syn match FiletreeGitAdded '" . s:i.g_added . "'"
	exec "syn match FiletreeGitModified '" . s:i.g_modified . "'"

	silent exec "syn match FiletreeIndent '" . g:filetree#indent_marker . "'"

	" Link color groups to colors
	let grey = { "fg":synIDattr(synIDtrans(hlID("Comment")), "fg#", "cterm"), "bg":synIDattr(synIDtrans(hlID("Comment")), "fg#", "gui") }
	let red = { "fg":synIDattr(synIDtrans(hlID("Directory")), "fg#", "cterm"), "bg":synIDattr(synIDtrans(hlID("Directory")), "fg#", "gui") }
	let green = { "fg":synIDattr(synIDtrans(hlID("String")), "fg#", "cterm"), "bg":synIDattr(synIDtrans(hlID("String")), "fg#", "gui") }
	let g:purple = { "fg":synIDattr(synIDtrans(hlID("Question")), "fg#", "cterm"), "bg":synIDattr(synIDtrans(hlID("Question")), "fg#", "gui") }

	exec "hi FiletreeIndent ctermfg=" . grey.fg . " guifg=" . grey.bg
	exec "hi FiletreeDirectory ctermfg=" . red.fg . " guifg=" . red.bg
	exec "hi FiletreeRedirect ctermfg=" . g:purple.fg . " guifg=" . g:purple.bg
	exec "hi FiletreeExecutable ctermfg=" . green.fg . " guifg=" . green.bg
	exec "hi FiletreePwd ctermfg=" . red.fg . " guifg=" . red.bg . " cterm=bold gui=bold"

	hi FiletreeGitCommitted ctermfg=82  guifg=#5FFF00 cterm=bold gui=bold
	hi FiletreeGitAdded ctermfg=75  guifg=#5FAFFF cterm=bold gui=bold
	hi FiletreeGitModified ctermfg=203  guifg=#FF5F5F cterm=bold gui=bold
endfunction
