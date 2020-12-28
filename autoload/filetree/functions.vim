" FUNCTION: filetree#functions#CursorIndex() {{{1
function! filetree#functions#CursorIndex()
	let line = line(".") - g:filetree#first_line
	if line(".") < 0
		return -1
	endif

	if g:filetree#show_hidden == 1
		return line
	endif

	let count = 0
	let index = 0
	while count <= line
		if !filetree#functions#IsHidden(g:filetree#tree[index].path)
			let count += 1
		endif
		let index += 1
	endwhile

	return index - 1
endfunction

" }}}
" FUNCTION: filetree#functions#GetCursorDirectory() {{{1
function! filetree#functions#GetCursorDirectory()
	let file_index = filetree#functions#CursorIndex()
	if file_index == -1
		return g:filetree#pwd
	endif

	let path = g:filetree#tree[file_index].path
	if filetree#functions#GetProperty(path, "d") == 1 && g:filetree#tree[file_index].open
		return path
	else
		return substitute(system("dirname '" . path . "'"), "\n", "", "g")
	endif
endfunction

" }}}
" FUNCTION: filetree#functions#GetIndex(path) {{{1
function! filetree#functions#GetIndex(path)
	let index = 0
	for q in g:filetree#tree
		if q.path == a:path
			return index
		endif

		let index += 1
	endfor

	return g:filetree#first_line
endfunction

" }}}
" FUNCTION: filetree#functions#GetLine(path) {{{1
function! filetree#functions#GetLine(path)
	let index = 0
	for q in g:filetree#tree
		if q.path == a:path
			return index + g:filetree#first_line
		endif

		if g:filetree#show_hidden || !filetree#functions#IsHidden(q.path)
			let index += 1
		endif
	endfor

	return g:filetree#first_line
endfunction

" }}}
" FUNCTION: filetree#functions#IsHidden(path) {{{1
function! filetree#functions#IsHidden(path)
	let path_split = split(a:path, "/")
	let split_len = len(path_split) - len(split(g:filetree#pwd, "/"))
	let g:sl = split_len
	let g:sp = path_split[-split_len:-1]
	for q in path_split[-split_len:-1]
		if q[0:0] == "."
			return 1
		endif
	endfor

	return 0
endfunction

" }}}
" FUNCTION: filetree#functions#GetProperty(path, property) {{{1
function! filetree#functions#GetProperty(path, property)
	return system("[[ -" . a:property . " '" . a:path . "' ]] && echo 1")
endfunction

" }}}
" FUNCTION: filetree#functions#GetShortPath(path) {{{1
function! filetree#functions#GetShortPath(path)
	" Replace the beginning with ~ if it is in the home directory
	if stridx(a:path, $HOME) == 0
		let long_path = substitute(a:path, $HOME, "~", "")
	else
		let long_path = a:path
	endif

	let split = split(long_path, "/")

	" Return the origional path if it is in the root directory
	if len(split) <= 1
		return a:path
	endif

	" Convert the split into a short path
	let new_path = ""
	for i in range(len(split) - 1)
		let new_path .= split[i][0:0] . "/"
	endfor
	let new_path .= split[-1]

	if new_path[0:0] != "~"
		let new_path = "/" . new_path
	endif

	return new_path
endfunction

" }}}
