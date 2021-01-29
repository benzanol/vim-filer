function! filer#colors#SetColors()
	" Get filer icons
	syntax match filerDirectory /.*\/\s*$/
	syntax match filerExecutable /.*\*\s*$/
	syntax match filerLink /.*@ \S.*\s*/
	
	execute printf('syntax match filerGitCommitted /%s/ nextgroup=filerFile,filerExecutable,filerLink', g:filer#icons.g_committed)
	execute printf('syntax match filerGitAdded /%s/ nextgroup=filerFile,filerExecutable,filerLink', g:filer#icons.g_added)
	execute printf('syntax match filerGitModified /%s/ nextgroup=filerFile,filerExecutable,filerLink', g:filer#icons.g_modified)
	
	syntax match filerPwd /^\s[/~].*\/\s*$/
	syntax match filerPwd /^\/\s*$/
	
	syntax match filerCurrentFile /.*\%#.*[^/^*^@]\s*$/
	syntax match filerCurrentDirectory /.*\%#.*\/\s*$/
	syntax match filerCurrentExecutable /.*\%#.*\*\s*$/
	syntax match filerCurrentLink /.*\%#.*@ \S.*\s*$/
	
	highlight filerDirectory ctermfg=74 guifg=#5FAFD7
	highlight filerPwd ctermfg=74 guifg=#5FAFD7 cterm=bold gui=bold
	highlight filerExecutable ctermfg=82 guifg=#5FFF00
	highlight filerLink ctermfg=177 guifg=#D787FF
	highlight filerGitCommitted ctermfg=82 guifg=#5FFF00
	highlight filerGitAdded ctermfg=74 guifg=#5FAFD7
	highlight filerGitModified ctermfg=203 guifg=#FF5F5F
	
	highlight filerCurrentFile ctermfg=250 guifg=#BCBCBC cterm=bold,inverse gui=bold,inverse
	highlight filerCurrentDirectory ctermfg=74 guifg=#5FAFD7 cterm=bold,inverse gui=bold,inverse
	highlight filerCurrentExecutable ctermfg=40 guifg=#00D700 cterm=bold,inverse gui=bold,inverse
	highlight filerCurrentLink ctermfg=141 guifg=#AF87FF cterm=bold,inverse gui=bold,inverse
endfunction
