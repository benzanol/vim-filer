" FUNCTION: filetree#actions#Reload() {{{1
function! filetree#actions#Reload()
	let g:filetree#tree = filetree#tree#GenerateTree(g:filetree#pwd, 0)
	call filetree#display#Print()
endfunction

" }}}
" FUNCTION: filetree#actions#Scroll(direction) {{{1
function! filetree#actions#Scroll(direction)
	if a:direction == "up"
		norm! k
	else
		norm! j
	endif
endfunction
" }}}
" FUNCTION: filetree#actions#Edit() {{{1
function! filetree#actions#Edit()
	let file_index = filetree#functions#CursorIndex()
	if file_index == -1
		return
	else
		let path = g:filetree#tree[file_index].path
	endif

	if filetree#functions#GetProperty(path, "d")
		call filetree#tree#ChangeDirectory(path)
		call filetree#display#Print()
	else
		wincmd p
		exec "edit " . resolve(path)
	endif
endfunction

" }}}
" FUNCTION: filetree#actions#Open() {{{1
function! filetree#actions#Open()
	let file_index = filetree#functions#CursorIndex()
	if file_index == -1
		return
	else
		let path = g:filetree#tree[file_index].path
	endif

	if filetree#functions#GetProperty(path, "d")
		if g:filetree#tree[file_index].open
			call filetree#tree#CloseDirectory(file_index)
		else
			call filetree#tree#OpenDirectory(file_index)
		endif
		call filetree#display#Print()
	endif
endfunction

" }}}
" FUNCTION: filetree#actions#OpenAll() {{{1
function! filetree#actions#OpenAll()
	let level = 0
	while 1
		let dir_list = []
		let any_closed = 0

		for i in range(len(g:filetree#tree))
			let q = g:filetree#tree[i]

			if q.level == level && q.end == "/" && (q.name[0:0] != "." || g:filetree#show_hidden)
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
				call filetree#tree#OpenDirectory(reverse)
			endfor

			call filetree#display#Print()
			return
		endif
	endwhile
endfunction

" }}}
" FUNCTION: filetree#actions#CloseAll() {{{1
function! filetree#actions#CloseAll()
	let g:filetree#opendirs = []
	call filetree#actions#Reload()
endfunction

" }}}
" FUNCTION: filetree#actions#DirShift(direction) {{{1
function! filetree#actions#DirShift(direction)
	let file_index = filetree#functions#CursorIndex()
	if file_index == -1
		let path = g:filetree#pwd
	else
		let path = g:filetree#tree[file_index].path
	endif

	if a:direction == "up"
		if index(g:filetree#opendirs, g:filetree#pwd) == -1
			call add(g:filetree#opendirs, g:filetree#pwd)
		endif

		if len(split(g:filetree#pwd, "/")) <= 1
			let new_dir = "/"
		else
			let new_dir_list = split(g:filetree#pwd, "/")[0:-2]
			let new_dir = "/" . join(new_dir_list, "/")
		endif

	elseif a:direction == "down"
		if path == g:filetree#pwd
			return
		endif

		let new_dir_level = len(split(g:filetree#pwd, "/"))
		let new_dir_list = split(path, "/")[0:new_dir_level]
		let new_dir = "/" . join(new_dir_list, "/")
	endif

	call filetree#tree#ChangeDirectory(new_dir)
	call filetree#display#Print()
	call cursor(filetree#functions#GetLine(path), 1)
endfunction

" }}}
" FUNCTION: filetree#actions#DirMove(direction) {{{1
function! filetree#actions#DirMove(direction)
	let file_index = filetree#functions#CursorIndex()
	if file_index == -1
		return
	else
		let path = g:filetree#tree[file_index].path
	endif

	" If moving up a level (h)
	if a:direction == "up"
		let new_path = "/" . join(split(path, "/")[0:-2], "/")

		if new_path == g:filetree#pwd
			return
			" Remove return statement to go up a directory when in top level
			let new_pwd = "/" . join(split(new_path, "/")[0:-2], "/")
			call filetree#tree#ChangeDirectory(new_pwd)
		endif

		" Close the directory
		call filetree#tree#CloseDirectory(filetree#functions#GetIndex(new_path))

		call filetree#display#Print()
		call cursor(filetree#functions#GetLine(new_path), 1)

		" If moving down a level (l)
	elseif a:direction == "down"
		if filetree#functions#GetProperty(path, "d")
			" If the directory is closed, open it
			if index(g:filetree#opendirs, path) == -1
				call filetree#tree#OpenDirectory(filetree#functions#GetIndex(path))
				call filetree#display#Print()
			endif

			" If there are any files, go to the first one
			if file_index != len(g:filetree#tree) - 1 && g:filetree#tree[file_index + 1].level > g:filetree#tree[file_index].level
				norm j
			endif
		endif
	endif
endfunction

" }}}
" FUNCTION: filetree#actions#ShowInfo() {{{1
function! filetree#actions#ShowInfo()
	let path = g:filetree#tree[filetree#functions#CursorIndex()].path
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
" FUNCTION: filetree#actions#ShowHidden(value) {{{1
function! filetree#actions#ShowHidden(value)
	let path = g:filetree#tree[filetree#functions#CursorIndex()].path
	if a:value == 0
		let g:filetree#show_hidden = 0
	elseif a:value == 1
		let g:filetree#show_hidden = 1
	else
		let g:filetree#show_hidden = !g:filetree#show_hidden
	endif

	call filetree#display#Print()
	call cursor(filetree#functions#GetLine(path), 1)
endfunction

" }}}
" FUNCTION: filetree#actions#NavigateTo(dir) {{{1
function! filetree#actions#NavigateTo(dir)
	let g:filetree#opendirs = []
	let old_path = g:filetree#pwd

	if a:dir == ".."
		if g:filetree#pwd == "/"
			return
		endif

		let path = "/" . join(split(g:filetree#pwd, "/")[0:-2], "/")
	else
		let path = expand(a:dir)
	endif

	call filetree#tree#ChangeDirectory(path)
	call filetree#display#Print()

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
		call cursor(g:filetree#first_line, 1)
	else
		call cursor(filetree#functions#GetLine(folder), 1)
	endif
endfunction

" }}}

" FUNCTION: filetree#actions#AddFile(type) {{{1
function! filetree#actions#AddFile(type)
	if a:type == "f" || a:type == "file"
		let type = 1
	elseif a:type == "d" || a:type == "directory" || a:type == "dir"
		let type = 2
	else
		let type = confirm("What would you like to create? ", "File\nDirectory")
	endif

	let name = input("New " . (type == 1 ? "file" : "directory") . " name: ")
	let dir = filetree#functions#GetCursorDirectory()
	let cmd = (type == 1) ? "touch" : "mkdir"

	exec "silent " . substitute("!" . cmd . " '" . dir . "/" . name . "'", "\n", "", "g")

	call filetree#actions#Reload()
endfunction

" }}}
" FUNCTION: filetree#actions#SetExecutable(value) {{{1
function! filetree#actions#SetExecutable(value) 
	let file_index = filetree#functions#CursorIndex()
	if file_index == -1 || g:filetree#tree[file_index].end == "/"
		return
	else
		let path = g:filetree#tree[file_index].path
	endif

	if a:value == 0
		silent exec "!chmod -x '" . path . "'"
		let g:filetree#tree[file_index].end = ""
	elseif a:value == 1
		silent exec "!chmod +x '" . path . "'"
		let g:filetree#tree[file_index].end = "*"
	else
		if g:filetree#tree[file_index].end == "*"
			silent exec "!chmod -x '" . path . "'"
			let g:filetree#tree[file_index].end = ""
		else
			silent exec "!chmod +x '" . path . "'"
			let g:filetree#tree[file_index].end = "*"
		endif
	endif

	call filetree#display#Print()
endfunction

" }}}
" FUNCTION: filetree#actions#DeleteFile() {{{1
function! filetree#actions#DeleteFile()
	let file_index = filetree#functions#CursorIndex()
	if file_index == -1
		let path = g:filetree#pwd
		let g:filetree#pwd = system("dirname '" . system("dirname '" . g:filetree#pwd . "'") . "'")
	else
		let path = g:filetree#tree[file_index].path
	endif
	let name = split(path, "/")[-1]

	if filetree#functions#GetProperty(path, "L")
		let confirmed = input("Deleting link '" . name . "': y/N")
	elseif filetree#functions#GetProperty(path, "d")
		let file_count = substitute(system("find '" . name . "' -type f | wc -l"), "", "", "g")

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
		silent exec "!rm -rf '" . path . "'"

		call remove(g:filetree#tree, filetree#functions#GetIndex(path))
		call filetree#display#Print()
	endif
endfunction

" }}}
" FUNCTION: filetree#actions#RenameFile() {{{1
function! filetree#actions#RenameFile()
	let file_index = filetree#functions#CursorIndex()
	if file_index == -1
		return
	else
		let path = g:filetree#tree[file_index].path
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

	call filetree#actions#Reload()
endfunction

" }}}
" FUNCTION: filetree#actions#MoveFile(action) {{{1
function! filetree#actions#MoveFile(action)
	let file_index = filetree#functions#CursorIndex()
	if file_index == -1
		return
	else
		let path = g:filetree#tree[file_index].path
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
	exec "noremap <buffer> <silent> <nowait> x :call filetree#actions#ConfirmMove('" . path . "', '" . command . "', '" . prompt . "')<CR>"
endfunction

function! filetree#actions#ConfirmMove(path, command, prompt)
	let name = split(a:path, "/")[-1]
	let new_path = input(a:prompt, filetree#functions#GetCursorDirectory() . "/" . name)
	exec "!" . a:command . " '" . a:path . "' '" . new_path . "'"

	silent! unmap <buffer> x
	call filetree#actions#Reload()
endfunction

" }}}
" FUNCTION: filetree#actions#GitCmd(cmd) {{{1
function! filetree#actions#GitCmd(cmd)
	let file_index = filetree#functions#CursorIndex()
	if file_index == -1
		return
	else
		let path = g:filetree#tree[file_index].path
	endif

	" Move to the parent directory of the file
	let real_dir = getcwd()
	let dir = filetree#functions#GetCursorDirectory()
	exec "cd " . dir

	if a:cmd == "add"
		silent exec "!git add '" . path . "'"

	elseif a:cmd == "commit"
		let commit_message = input("Commit Message: ")
		exec "!git commit -m '" . commit_message . "'"

	elseif a:cmd == "ammend"
		let last_commit = split(system("git log --oneline"), "\n")[0]
		let last_message = last_commit[8:-1]
		let commit_message = input("Ammended Commit Message: ", last_message)
		silent exec "!git commit --amend -m '" . commit_message . "'"

	elseif a:cmd == "log"
		let output = system("git log --oneline")
		echo output
	endif

	" Go back to the origional directory
	exec "cd " . real_dir

	call filetree#actions#Reload()
endfunction

" }}}
