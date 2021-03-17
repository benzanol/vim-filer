" FUNCTION: filer#actions#Reload() {{{1
function! filer#actions#Reload()
	let g:filer#tree = filer#tree#GenerateTree(g:filer#pwd, 0)
	call filer#display#Print()
endfunction

" }}}
" FUNCTION: filer#actions#Scroll(direction) {{{1
function! filer#actions#Scroll(direction)
	if a:direction == "up"
		norm! k
	else
		norm! j
	endif
endfunction
" }}}
" FUNCTION: filer#actions#Edit() {{{1
function! filer#actions#Edit()
	let file_index = filer#functions#CursorIndex()
	if file_index == -1
		return
	else
		let path = g:filer#tree[file_index].path
	endif

	if filer#functions#GetProperty(path, "d")
		call filer#tree#ChangeDirectory(path)
		call filer#display#Print()
	else
		" Detect if it is a special file
		let icon = filer#icons#GetFiletypeIcon(split(path, '\/')[-1])
		if  icon == g:filer#icons.f_file || icon == g:filer#icons.e_exe
			wincmd p
			exec "edit " . resolve(path)
		else
			silent! exec "!xdg-open '" . resolve(path) . "'"
		endif
	endif
endfunction

" }}}
" FUNCTION: filer#actions#Open() {{{1
function! filer#actions#Open()
	let file_index = filer#functions#CursorIndex()
	if file_index == -1
		return
	else
		let path = g:filer#tree[file_index].path
	endif

	if filer#functions#GetProperty(path, "d")
		if g:filer#tree[file_index].open
			call filer#tree#CloseDirectory(file_index)
		else
			call filer#tree#OpenDirectory(file_index)
		endif
		call filer#display#Print()
	endif
endfunction

" }}}
" FUNCTION: filer#actions#OpenAll() {{{1
function! filer#actions#OpenAll()
	let level = 0
	while 1
		let dir_list = []
		let any_closed = 0

		for i in range(len(g:filer#tree))
			let q = g:filer#tree[i]

			if q.level == level && q.end == "/" && (q.name[0:0] != "." || g:filer#show_hidden)
				call add(dir_list, i)
				if q.open == 0
					let any_closed = 1
				endif
			endif
		endfor

		if len(dir_list) == 0
			return
		elseif any_closed == 0
			let level += 1
			continue
		else
			for i in range(len(dir_list))
				let reverse = dir_list[len(dir_list) - 1 - i]
				call filer#tree#OpenDirectory(reverse)
			endfor

			call filer#display#Print()
			return
		endif
	endwhile
endfunction

" }}}
" FUNCTION: filer#actions#CloseAll() {{{1
function! filer#actions#CloseAll()
	let g:filer#opendirs = []
	call filer#actions#Reload()
endfunction

" }}}
" FUNCTION: filer#actions#DirShift(direction) {{{1
function! filer#actions#DirShift(direction)
	let file_index = filer#functions#CursorIndex()
	if file_index == -1
		let path = g:filer#pwd
	else
		let path = g:filer#tree[file_index].path
	endif

	if a:direction == "up"
		if index(g:filer#opendirs, g:filer#pwd) == -1
			call add(g:filer#opendirs, g:filer#pwd)
		endif

		if len(split(g:filer#pwd, "/")) <= 1
			let new_dir = "/"
		else
			let new_dir_list = split(g:filer#pwd, "/")[0:-2]
			let new_dir = "/" . join(new_dir_list, "/")
		endif

	elseif a:direction == "down"
		if path == g:filer#pwd
			return
		endif

		let new_dir_level = len(split(g:filer#pwd, "/"))
		let new_dir_list = split(path, "/")[0:new_dir_level]
		let new_dir = "/" . join(new_dir_list, "/")
	endif

	call filer#tree#ChangeDirectory(new_dir)
	call filer#display#Print()
	call cursor(filer#functions#GetLine(path), 1)
endfunction

" }}}
" FUNCTION: filer#actions#DirMove(direction) {{{1
function! filer#actions#DirMove(direction)
	let file_index = filer#functions#CursorIndex()
	if file_index == -1
		return
	else
		let path = g:filer#tree[file_index].path
	endif

	" If moving up a level (h)
	if a:direction == "up"
		let new_path = "/" . join(split(path, "/")[0:-2], "/")

		if new_path == g:filer#pwd
			return
			" Remove return statement to go up a directory when in top level
			let new_pwd = "/" . join(split(new_path, "/")[0:-2], "/")
			call filer#tree#ChangeDirectory(new_pwd)
		endif

		" Close the directory
		call filer#tree#CloseDirectory(filer#functions#GetIndex(new_path))

		call filer#display#Print()
		call cursor(filer#functions#GetLine(new_path), 1)

		" If moving down a level (l)
	elseif a:direction == "down"
		if filer#functions#GetProperty(path, "d")
			" If the directory is closed, open it
			if index(g:filer#opendirs, path) == -1
				call filer#tree#OpenDirectory(filer#functions#GetIndex(path))
				call filer#display#Print()
			endif

			" If there are any files, go to the first one
			if file_index != len(g:filer#tree) - 1 && g:filer#tree[file_index + 1].level > g:filer#tree[file_index].level
				norm j
			endif
		endif
	endif
endfunction

" }}}
" FUNCTION: filer#actions#ShowInfo() {{{1
function! filer#actions#ShowInfo()
	let path = g:filer#tree[filer#functions#CursorIndex()].path
	let real_path = resolve(path)

	" Create a string with the path at the top to display
	let info = path . "\n"

	" Detect if it is a link and show the redirect path
	let redirect = system("readlink '" . path . "' 2> /dev/null")
	if redirect != ""
		let info .= "Redirects to: " . redirect
	endif

	" Get the file type, and if it is a normal file get its size
	let type = system("stat -c %F '" . path . "' 2> /dev/null")
	let info .= "File Type: " . substitute(type, "^.", "\\u&", "g")

	" Get the file size, or the size of the contents of a directory
	let size = split(system("du -sh '" . real_path . "' 2> /dev/null"), "	")[0]
	if type[0:2] == "dir" || type[0:2] == "sym"
		let info .= "Size of Contents: " . size . "\n"
	else
		let info .= "File Size: " . size . "\n"
	endif

	" Get other miscellaneous info
	let info .= "Created: " . system("stat -c %w '" . path . "' 2> /dev/null")
	let info .= "Owner: " . system("stat -c %U '" . path . "' 2> /dev/null")
	let info .= "Permissions: " . system("stat -c %A '" . path . "' 2> /dev/null")
	echo info
endfunction

" }}}
" FUNCTION: filer#actions#ShowHidden(value) {{{1
function! filer#actions#ShowHidden(value)
	let path = g:filer#tree[filer#functions#CursorIndex()].path
	if a:value == 0
		let g:filer#show_hidden = 0
	elseif a:value == 1
		let g:filer#show_hidden = 1
	else
		let g:filer#show_hidden = !g:filer#show_hidden
	endif

	call filer#display#Print()
	call cursor(filer#functions#GetLine(path), 1)
endfunction

" }}}
" FUNCTION: filer#actions#NavigateTo(dir) {{{1
function! filer#actions#NavigateTo(dir)
	let g:filer#opendirs = []
	let old_path = g:filer#pwd

	if a:dir == ".."
		if g:filer#pwd == "/"
			return
		endif

		let path = "/" . join(split(g:filer#pwd, "/")[0:-2], "/")
	else
		let path = expand(a:dir)
	endif

	call filer#tree#ChangeDirectory(path)
	call filer#display#Print()

	" Detect if the old path is in the current path, and if so got to its folder
	let old_split = split(old_path, "/")
	let new_split = split(path, "/")
	let level = len(new_split) - 1

	let folder = ""
	if level == -1
		let folder = "/" . old_split[0]
	elseif len(old_split) - 1 > level && old_split[0:level] == new_split
		let folder = "/" . join(old_split[0:level + 1], "/")
	endif

	if folder == ""
		call cursor(g:filer#first_line, 1)
	else
		call cursor(filer#functions#GetLine(folder), 1)
	endif
endfunction

" }}}

" FUNCTION: filer#actions#AddFile(type) {{{1
function! filer#actions#AddFile(type)
	let name = input("New " . (a:type == 1 ? "file" : "directory") . " name: ")
	let dir = filer#functions#GetCursorDirectory()
	let cmd = (a:type == 1) ? "touch" : "mkdir"

	exec "silent " . substitute("!" . cmd . " '" . dir . "/" . name . "'", "\n", "", "g")

	call filer#actions#Reload()
endfunction

" }}}
" FUNCTION: filer#actions#SetExecutable(value) {{{1
function! filer#actions#SetExecutable(value) 
	let file_index = filer#functions#CursorIndex()
	if file_index == -1 || g:filer#tree[file_index].end == "/"
		return
	else
		let path = g:filer#tree[file_index].path
	endif

	if a:value == 0
		silent exec "!chmod -x '" . path . "'"
		let g:filer#tree[file_index].end = ""
	elseif a:value == 1
		silent exec "!chmod +x '" . path . "'"
		let g:filer#tree[file_index].end = "*"
	else
		if g:filer#tree[file_index].end == "*"
			silent exec "!chmod -x '" . path . "'"
			let g:filer#tree[file_index].end = ""
		else
			silent exec "!chmod +x '" . path . "'"
			let g:filer#tree[file_index].end = "*"
		endif
	endif

	call filer#display#Print()
endfunction

" }}}
" FUNCTION: filer#actions#DeleteFile() {{{1
function! filer#actions#DeleteFile()
	let file_index = filer#functions#CursorIndex()
	if file_index == -1
		let path = g:filer#pwd
		let g:filer#pwd = system("dirname '" . system("dirname '" . g:filer#pwd . "'") . "'")
	else
		let path = g:filer#tree[file_index].path
		let path_index = filer#functions#GetIndex(path)
	endif
	let name = split(path, "/")[-1]

	if filer#functions#GetProperty(path, "L")
		let confirmed = input("Deleting link '" . name . "': y/N")
	elseif filer#functions#GetProperty(path, "d")
		let file_count = substitute(system("find '" . path . "' -type f | wc -l"), "", "", "g")

		if file_count == 0
			let confirmed = confirm("Deleting empty directory '" . name . "'", "Y\nN")
		elseif file_count == 1
			let confirmed = confirm("Deleting directory '" . name . "' and 1 file", "Y\nN")
		else
			let confirmed = confirm("Deleting directory '" . name . "' and " . file_count . " files", "Y\nN")
		endif

	else
		let confirmed = confirm("Deleting file '" . name . "'", "Y\nN")
	endif

	if confirmed == 1
		if filer#functions#GetProperty(path, "d")
			call filer#tree#CloseDirectory(path_index)
		endif

		call remove(g:filer#tree, path_index)

		silent exec "!rm -rf '" . path . "'"

		call filer#display#Print()
	endif
endfunction

" }}}
" FUNCTION: filer#actions#RenameFile() {{{1
function! filer#actions#RenameFile()
	let file_index = filer#functions#CursorIndex()
	if file_index == -1
		return
	else
		let path = g:filer#tree[file_index].path
	endif

	let dir_path = join(split(path, "/")[0:-2], "/")
	if dir_path == ""
		let dir_path = "/"
	else
		let dir_path = "/" . dir_path . "/"
	endif

	let new_name = input("New name: ")

	if stridx(new_name, "/") != -1
		echo "New name cannot contain a slash"
	endif

	silent exec "!mv '" . path . "' '" . dir_path . new_name . "'"

	call filer#actions#Reload()
endfunction

" }}}
" FUNCTION: filer#actions#MoveFile(action) {{{1
function! filer#actions#MoveFile(action)
	let file_index = filer#functions#CursorIndex()
	if file_index == -1
		return
	else
		let path = g:filer#tree[file_index].path
	endif

	if a:action == "copy"
		let statement = "Navigate to the folder where you want to create the copy"
		let prompt = "Path of copy: "
		let command = "cp -r"
	elseif a:action == "link"
		let statement = "Navigate to the folder where you want to create the link"
		let prompt = "Path of link: "
		let command = "ln -s"
	else
		let statement = "Navigate to the folder where you want to move the file"
		let prompt = "New path: "
		let command = "mv"
	endif

	echo statement . ", and press x to select it"
	exec "noremap <buffer> <silent> <nowait> x :call filer#actions#ConfirmMove('" . path . "', '" . command . "', '" . prompt . "')<CR>"
endfunction

function! filer#actions#ConfirmMove(path, command, prompt)
	let name = split(a:path, "/")[-1]
	let new_path = input(a:prompt, filer#functions#GetCursorDirectory() . "/" . name)
	exec "!" . a:command . " '" . a:path . "' '" . new_path . "'"

	silent! unmap <buffer> x
	call filer#actions#Reload()
endfunction

" }}}
