" FUNCTION: filer#menu#FileMenu() {{{1
function! filer#menu#FileMenu()
	let file_actions = [
				\ {'prompt':'&Rename', 'command':'RenameFile()'},
				\ {'prompt':'&Delete', 'command':'DeleteFile()'},
				\ {'prompt':'&Move', 'command':'MoveFile("move")'},
				\ {'prompt':'&Copy', 'command':'MoveFile("copy")'},
				\ {'prompt':'&Link', 'command':'MoveFile("link")'},
				\ {'prompt':'&X Make Executable', 'command':'SetExecutable(-1)'},
				\ ]

	let confirm_string = ''
	for q in file_actions
		let confirm_string .= q.prompt . "\n"
	endfor

	" Remove last newline separator
	let confirm_string = confirm_string[0:-2]

	let action = confirm('File action menu', confirm_string)
	if action > 0
		execute 'call filer#actions#' . file_actions[action - 1].command
	endif
endfunction

" }}}
" FUNCTION: filer#menu#AddMenu() {{{1
function! filer#menu#AddMenu()
	let type = confirm("What would you like to create? ", "File\nDirectory")
	call filer#actions#AddFile(type)
endfunction

" }}}
" FUNCTION: filer#menu#GitMenu() {{{1
function! filer#menu#GitMenu()
	let git_actions = [
				\ {'prompt':'&Add', 'command':'add'},
				\ {'prompt':'&Log', 'command':'log'},
				\ {'prompt':'&Commit', 'command':'commit'},
				\ {'prompt':'A&Mmend Commit', 'command':'ammend'},
				\ ]

	let confirm_string = ''
	for q in git_actions
		let confirm_string .= q.prompt . "\n"
	endfor

	" Remove last newline separator
	let confirm_string = confirm_string[0:-2]

	let action = confirm('Git action menu', confirm_string)
	if action > 0
		execute 'call filer#actions#GitCmd("' . git_actions[action - 1].command . '")'
	endif
endfunction

" }}}
