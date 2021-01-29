function! filer#colors#SetupColors()
	syntax match filerDirectory /.*\/\s*$/
	syntax match filerFile / \S  .*[^/^*^@]\s*$/
	syntax match filerExecutable / \S  .*\*\s*$/
	syntax match filerLink / \S  .*@ \S.*\s*/

	syntax match filerPwd /^\s[/~].*\/\s*$/
	syntax match filerPwd /^\/\s*$/

	execute printf('syntax match filerGitCommitted /%s/', g:filer#icons.g_committed)
	execute printf('syntax match filerGitAdded /%s/', g:filer#icons.g_added)
	execute printf('syntax match filerGitModified /%s/', g:filer#icons.g_modified)

	highlight filerPwd ctermfg=74 guifg=#5FAFD7 cterm=bold gui=bold
	highlight filerFile ctermfg=250 guifg=#BCBCBC
	highlight filerDirectory ctermfg=74 guifg=#5FAFD7
	highlight filerExecutable ctermfg=40 guifg=#00D700
	highlight filerLink ctermfg=171 guifg=#D75FFF

	if exists('g:filer#enable_highlight') && g:filer#enable_highlight
		syntax match filerCurrentFile /\%#.*[^/^*^@]\s*$/
		syntax match filerCurrentDirectory /\%#.*\/\s*$/
		syntax match filerCurrentExecutable /\%#.*\*\s*$/
		syntax match filerCurrentLink /\%#.*@ \S.*\s*$/

		syntax match filerCurrentPwd /\%# [/~].*\/\s*$/
		syntax match filerCurrentPwd /\%# \/\s*$/

		highlight filerCurrentPwd ctermfg=74 guifg=#5FAFD7 cterm=bold,inverse gui=bold,inverse
		highlight filerCurrentFile ctermfg=250 guifg=#BCBCBC cterm=bold,inverse gui=bold,inverse
		highlight filerCurrentDirectory ctermfg=74 guifg=#5FAFD7 cterm=bold,inverse gui=bold,inverse
		highlight filerCurrentExecutable ctermfg=34 guifg=#00AF00 cterm=bold,inverse gui=bold,inverse
		highlight filerCurrentLink ctermfg=134 guifg=#AF54D7 cterm=bold,inverse gui=bold,inverse

		highlight filerCursor ctermfg=74 guifg=#5FAFD7
		match filerCursor /\%#\s/

		autocmd CursorMoved,WinEnter <buffer> call filer#colors#SetCursorColor()
	endif

	highlight filerGitCommitted ctermfg=82 guifg=#5FFF00 cterm=none gui=none
	highlight filerGitAdded ctermfg=74 guifg=#5FAFD7 cterm=none gui=none
	highlight filerGitModified ctermfg=203 guifg=#FF5F5F cterm=none gui=none
endfunction

function! filer#colors#SetupHighlight(args)
endfunction

function! filer#colors#SetCursorColor()
	let type = g:filer#tree[filer#functions#CursorIndex()].end
	if line('.') == 1
		highlight filerCursor ctermfg=74 guifg=#5FAFD7 ctermbg=74 guibg=#5FAFD7 cterm=bold gui=bold
	elseif type == '/'
		highlight filerCursor ctermfg=74 guifg=#5FAFD7 ctermbg=74 guibg=#5FAFD7
	elseif type == '*'
		highlight filerCursor ctermfg=34 guifg=#00AF00 ctermbg=34 guibg=#00AF00
	elseif type == '@'
		highlight filerCursor ctermfg=134 guifg=#AF54D7 ctermbg=134 guibg=#AF54D7
	else
		highlight filerCursor ctermfg=250 guifg=#BCBCBC ctermbg=250 guibg=#BCBCBC
	endif

endfunction
