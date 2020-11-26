" FUNCTION: filetree#Initialize() {{{1
function! filetree#Initialize()
	let s:pwd = getcwd()
	let g:opendirs = [] " Stores a list of paths representing directories for which the contents should be displayed in the tree
	let s:show_hidden = 0 " Boolean representing whether hidden files should be shown in the tree
	let s:first_line = 2 " First line of tree after any heading text
	let s:indent_marker = "│ "
	let s:link_icon = "→"

	let g:tree = s:GenerateTree(getcwd(), 0) " Stores a list of file/level pairs, representing each files distance from the root directory

	" Create filetree keybindings
	nnoremap <buffer> <silent> <nowait> . :call filetree#ToggleHidden(-1)<CR>
	nnoremap <buffer> <silent> <nowait> <Space> :call filetree#Activate()<CR>
	nnoremap <buffer> <silent> <nowait> <CR> :call filetree#Open()<CR>
	nnoremap <buffer> <silent> <nowait> c :call filetree#Cd()<CR>
	nnoremap <buffer> <silent> <nowait> r :call filetree#Reload()<CR>
	exec "nnoremap <buffer> <silent> j j0/^\\(" . s:indent_marker . "\\)*.\\zs.<CR>3h"
	exec "nnoremap <buffer> <silent> k k0/^\\(" . s:indent_marker . "\\)*.\\zs.<CR>3h"
	nmap J jjjj
	nmap K kkkk
	nnoremap <buffer> <silent> <nowait> h :call filetree#DirMove("up")<CR>
	nnoremap <buffer> <silent> <nowait> l :call filetree#DirMove("down")<CR>
	nnoremap <buffer> <silent> <nowait> u :call filetree#DirShift("up")<CR>
	nnoremap <buffer> <silent> <nowait> U :call filetree#DirShift("down")<CR>

	" File editting commands ( f + modifier )
	nnoremap <buffer> <silent> <nowait> fd :call filetree#DeleteFile()<CR>
	nnoremap <buffer> <silent> <nowait> fc :call filetree#CopyFile()<CR>
	nnoremap <buffer> <silent> <nowait> fm :call filetree#MoveFile()<CR>
	nnoremap <buffer> <silent> <nowait> fx :call filetree#EditFile("!chmod +x <file>")<CR>
	nnoremap <buffer> <silent> <nowait> fX :call filetree#EditFile("!chmod -x<file>")<CR>

	" File adding commands ( a + modifier )
	nnoremap <buffer> <silent> <nowait> a :call filetree#AddFile(0)<CR>
	nnoremap <buffer> <silent> <nowait> af :call filetree#AddFile(1)<CR>
	nnoremap <buffer> <silent> <nowait> ad :call filetree#AddFile(2)<CR>

	" Git commands ( g + modifier )
	nnoremap <buffer> <silent> <nowait> ga :call filetree#GitFile("add")<CR>
	nnoremap <buffer> <silent> <nowait> gc :call filetree#GitFile("commit")<CR>
	nnoremap <buffer> <silent> <nowait> gC :call filetree#GitFile("ammend")<CR>
	
	" Draw the filetree to the screen
	call sidebar#Print(s:GetText())
endfunction

" FUNCTION: filetree#Reload() {{{1
function! filetree#Reload()
	let g:tree = s:GenerateTree(s:pwd, 0)
	call sidebar#Print(s:GetText())
endfunction


" FUNCTION: filetree#Activate() {{{1
function! filetree#Activate()
	let file = s:GetCursorFile()
	silent! if file == 0
		return
	endif

	let path = file.path

	if s:GetProperty(path, "d")
		call s:ToggleDirectory(s:GetIndex(path))
	endif

	call sidebar#Print(s:GetText())
endfunction

" FUNCTION: filetree#Open() {{{1
function! filetree#Open()
	let file = s:GetCursorFile()
	silent! if file == 0
		return
	endif

	let path = file.path

	if s:GetProperty(path, "d")
		call s:ChangeDirectory(path)
		call sidebar#Print(s:GetText())
	else
		wincmd l
		exec "edit " . resolve(path)
	endif
endfunction

" FUNCTION: filetree#DirShift(direction) {{{1
function! filetree#DirShift(direction)
	let file = s:GetCursorFile()
	silent! let path = file.path
	silent! if file == 0
		let path = s:pwd
	endif

	if a:direction == "up"
		if index(g:opendirs, s:pwd) == -1
			call add(g:opendirs, s:pwd)
		endif

		if len(split(s:pwd, "/")) <= 1
			let new_dir = "/"
		else
			let new_dir_list = split(s:pwd, "/")[0:-2]
			let new_dir = "/" . join(new_dir_list, "/")
		endif

	elseif a:direction == "down"
		if path == s:pwd
			return
		endif

		let new_dir_level = len(split(s:pwd, "/"))
		let new_dir_list = split(path, "/")[0:new_dir_level]
		let new_dir = "/" . join(new_dir_list, "/")
	endif

	call s:ChangeDirectory(new_dir)
	call sidebar#Print(s:GetText())
	call s:CursorToFile(s:GetIndex(path))

endfunction

" FUNCTION: filetree#DirMove(direction) {{{1
function! filetree#DirMove(direction)
	let file = s:GetCursorFile()
	silent! let path = file.path
	silent! if file == 0
		return
	endif
	let index = s:GetIndex(path)

	" If moving up a level (h)
	if a:direction == "up"
		let new_path = s:GetParent(path)
		let g:npath = new_path

		if new_path == s:pwd
			return
			" Remove return statement to go up a directory when in top level
			let new_pwd = s:GetParent(new_path)
			call s:ChangeDirectory(new_pwd)
		endif

		" Close the directory
		let opendir_index = index(g:opendirs, new_path)
		if opendir_index != -1
			call s:ToggleDirectory(s:GetIndex(new_path))
		endif
		
		call sidebar#Print(s:GetText())
		call s:CursorToFile(s:GetIndex(new_path))

	" If moving down a level (l)
	elseif a:direction == "down"
		if s:GetProperty(path, "d")
			" If the directory is closed, open it
			if index(g:opendirs, path) == -1
				call s:ToggleDirectory(s:GetIndex(path))
				call sidebar#Print(s:GetText())
			endif
			
			" If there are any files, go to the first one
			if index != len(g:tree) - 1 && g:tree[index + 1].level > g:tree[index].level
				norm j
			endif
		endif
	endif

endfunction

" FUNCTION: filetree#AddFile(type) {{{1
function! filetree#AddFile(type)
	if a:type == 0
		let type = confirm("What would you like to create? ", "&File\n&Directory")
	else
		let type = a:type
	endif

	let name = input("New file name: ")
	let dir = s:GetCursorDirectory()
	let cmd = (type == 1) ? "touch" : "mkdir"
	
	exec "silent " . substitute("!" . cmd . " '" . dir . "/" . name . "'", "\n", "", "g")
	call filetree#Reload()
endfunction

" FUNCTION: filetree#EditFile(cmd) {{{1
function! filetree#EditFile(cmd)
	let file = s:GetCursorFile()
	silent! if file == 0
		return
	endif
	
	" Run the command specified, with <file> being the file path
	let g:command = substitute(a:cmd, "<file>", "'" . file.path . "'", "g")
	silent exec substitute(a:cmd, "<file>", "'" . file.path . "'", "g")
	
	call filetree#Reload()
endfunction

" FUNCTION: filetree#DeleteFile() {{{1
function! filetree#DeleteFile()
	let file = s:GetCursorFile()
	silent! let path = file.path
	silent! if file == 0
		let path = s:pwd
		let s:pwd = system("dirname '" . system("dirname '" . s:pwd . "'") . "'")
	endif
	let name = split(path, "/")[-1]

	let confirm_message = "Type 'confirm' to delete it, or press <Esc> to cancel: " 

	if s:GetProperty(path, "d")
		let file_count = substitute(system("find '" . name . "' | wc -l"), "\n", "", "g")

		if file_count == 0
			let confirmed = input("Deleting directory '" . name . "'\n" . confirm_message)
		elseif file_count == 1
			let confirmed = input("Deleting directory '" . name . "' and 1 file\n" . confirm_message)
		else
			let confirmed = input("Deleting directory '" . name . "' and " . file_count . " files\n" . confirm_message)
		endif

	else
		let confirmed = input("Deleting file '" . name . "'\n" . confirm_message)
	endif
	
	if confirmed != "confirm"
		return
	endif

	silent exec "!rm -rf '" . path . "'"
	call filetree#Reload()
endfunction

" FUNCTION: filetree#MoveFile() {{{1
function! filetree#DeleteFile()
	let file = s:GetCursorFile()
	silent! let path = file.path
	silent! if file == 0
		let path = s:pwd
	endif
	let name = split(path, "/")[-1]
	
	if confirmed != "confirm"
		return
	endif

	silent exec "!rm -rf '" . path . "'"
	call filetree#Reload()
endfunction

" FUNCTION: filetree#CopyFile() {{{1
function! filetree#DeleteFile()
	let file = s:GetCursorFile()
	silent! let path = file.path
	silent! if file == 0
		let path = s:pwd
	endif
	let name = split(path, "/")[-1]

	let confirm_message = "Type 'confirm' to delete it, or press <Esc> to cancel: " 

	if s:GetProperty(path, "d")
		let file_count = substitute(system("find '" . name . "' | wc -l"), "\n", "", "g")

		if file_count == 0
			let confirmed = input("Deleting directory '" . name . "'\n" . confirm_message)
		elseif file_count == 1
			let confirmed = input("Deleting directory '" . name . "' and 1 file\n" . confirm_message)
		else
			let confirmed = input("Deleting directory '" . name . "' and " . file_count . " files\n" . confirm_message)
		endif

	else
		let confirmed = input("Deleting file '" . name . "'\n" . confirm_message)
	endif
	
	if confirmed != "confirm"
		return
	endif

	silent exec "!rm -rf '" . path . "'"
	call filetree#Reload()
endfunction

" FUNCTION: filetree#GitFile(cmd) {{{1
function! filetree#GitFile(cmd)
	let file = s:GetCursorFile()
	silent! if file == 0
		return
	endif

	" Move to the parent directory of the file
	let real_dir = getcwd()
	let dir = s:GetCursorDirectory()
	exec "cd " . dir

	if a:cmd == "add"
		silent exec "!git add '" . file.path . "'"
	elseif a:cmd == "commit"
		let commit_message = input("Commit Message: ")
		silent exec "!git commit -m '" . commit_message . "'"
	elseif a:cmd == "ammend"
		let last_commit = split(system("git log --oneline"), "\n")[0]
		let last_message = last_commit[8:-1]
		let commit_message = input("Ammended Commit Message: ", last_message)
		silent exec "!git commit --amend -m '" . commit_message . "'"
	endif

	" Go back to the origional directory
	exec "cd " . real_dir
	
	call filetree#Reload()
endfunction

" FUNCTION: filetree#ToggleHidden(value) {{{1
function! filetree#ToggleHidden(value)
	let path = s:GetCursorFile().path
	if a:value == 0
		let s:show_hidden = 0
	elseif a:value == 1
		let s:show_hidden = 1
	else
		let s:show_hidden = !s:show_hidden
	endif

	let g:tree = s:GenerateTree(s:pwd, 0)
	call sidebar#Print(s:GetText())
	call s:CursorToFile(s:GetIndex(path))
endfunction

" FUNCTION: filetree#Cd() {{{1
function! filetree#Cd()
	let dir = s:GetCursorDirectory()
	call s:ChangeDirectory(dir)
	let g:dir = dir
	exec "cd " . dir
	call filetree#Reload()
endfunction

" FUNCTION: filetree#Get(var) {{{1
function! filetree#Get(var)
	exec "return " . a:var
endfunction

" FUNCTION: s:GetText() {{{1
function! s:GetText()
	" Get the longest version of the heading that will fit in the window
	let heading = s:pwd . "/"

	if len(heading) > winwidth(0)
		let heading = substitute(s:pwd, $HOME, "~", "") . "/"

		if len(heading) > winwidth(0)
			let heading = s:GetShortPath(s:pwd) . "/"

			if len(heading) > winwidth(0)
				let heading = split(s:pwd, "/")[-1] . "/"
			endif
		endif
	endif

	" Convert the tree list into a formatted string with line breaks and indents
	let output = [heading]

	for q in g:tree
		let indent = repeat(s:indent_marker, q.level + 1)
		call add(output, indent . q.start . " " . q.name . q.link . q.end . " ")
	endfor

	return output
endfunction

" FUNCTION: s:GenerateTree(dir, level) {{{1
function! s:GenerateTree(dir, level)
	let new_tree = [] " Local variable storing the entire tree for the current level of the function

	" Get the list of files
	let cmd = "ls -Fv --group-directories-first" . (s:show_hidden ? " -A" : "")
	let files = split(system(cmd . " -L '" . a:dir . "' 2> /dev/null"), "\n")
	let link_ending = split(system(cmd . " -H '" . a:dir . "' 2> /dev/null"), "\n")
	
	" Detect if the directory is a git directory
	let real_pwd = getcwd()
	exec "cd " . a:dir

	let git_dir = split(system("git rev-parse --show-toplevel"), "\n")[0]
	if git_dir[0] != "/"
		let git_dir = ""
	endif

	" Get the directory with a slash on the end
	let dir_prefix = (a:dir == "/") ? ("/") : (a:dir . "/")

	" Get a list of open directories that are in the current directory
	let here_opendirs = []
	let dir_split = split(a:dir, "/")
	let dir_level = len(dir_split)
	for q in g:opendirs
		" If there is an open directory in the current directory
		if split(q, "/")[0:-2] == dir_split
			call add(here_opendirs, q)
		endif
	endfor

	" Loop through each file in the specified directory {{{2
	for i in range(len(files))
		let q = files[i]

		" Create a new list for the current tree item
		let new_item = {}
		let new_item.level = a:level
		let new_item.pwd = getcwd()

		" Parse the different indicators for the file
		let is_dir = 0
		let indicator = q[-1:-1]
		if indicator == "/"
			let is_dir = 1
			let new_item.name = q[0:-2]
			let new_item.start = "▸  "
			let new_item.end = "/"

		elseif indicator == "*"
			let new_item.name = q[0:-2]
			let new_item.end = "*"

		else
			let new_item.name = q
			let new_item.end = ""
		endif

		" Set the path to the directory prefix + the file name
		let new_item.path = dir_prefix . new_item.name
		
		" Show if a symbolic link
		let new_item.link = ""
		if link_ending[i][-1:-1] == "@"
			if new_item.end == "/"
				let new_item.start = substitute(new_item.start, "", "", "")
			else
				let new_item.start = "   "
			endif
			let new_item.link = "@ → " . s:GetShortPath(resolve(new_item.path))
		endif

		" If the file doesn't already have an icon, figure out what it should be
		if !has_key(new_item, "start") " If it is a hidden file
			if new_item.name[0] == "."
				let new_item.start = "  ﬒ "
			else " If the file is not hidden
				" Check if file has an extension
				let extension = substitute(new_item.name, ".*\\.", "", "")
				let extension = (extension == new_item.name) ? "" : extension
				let new_item.start = "  " . s:GetIcon(extension) . " "
			endif
		endif

		if git_dir != "" && new_item.start[0:0] == " "
			let git_status = system("git status -s '" . new_item.path . "'")
			if git_status == ""
				let git_icon = "✓"
			elseif git_status[1:1] == " "
				let git_icon = "✚"
			else
				let git_icon = "✗"
			endif
			let new_item.start = git_icon . new_item.start[1:-1]
			let new_item.pwd = git_status
		endif

		" Add the current file to the tree
		call add(new_tree, new_item) " Add the file to the tree variable

		" Check if file is an open directory, and if so generate contents
		if is_dir && index(here_opendirs, new_item.path) != -1
			let new_tree[-1].start = substitute(new_tree[-1].start, "▸", "▾", "")
			let subtree = s:GenerateTree(new_item.path, a:level + 1)
			let new_tree = new_tree + subtree
		endif
		
	endfor " }}}
	
	exec "cd " . real_pwd

	return new_tree
endfunction

" FUNCTION: s:GetIcon(extension) {{{1
function! s:GetIcon(extension)
	let filetypes = []
	call add(filetypes, ["", "", ""])
	call add(filetypes, ["", "", "zip", "tar", "gz", "xz", "bz2"])
	call add(filetypes, ["", "", "txt", "doc", "docx"])
	call add(filetypes, ["", "", "sh", "bash", "zsh", "fish"])
	call add(filetypes, ["", "", "png", "jpg", "jpeg", "gif"])
	call add(filetypes, ["", "", "mp4", "mov", "wmv", "webm"])
	call add(filetypes, ["", "", "mp3", "wav", "flac"])
	call add(filetypes, ["", "", "pdf"])
	call add(filetypes, ["", "", "vim"])

	" Set which type of icon to use (0=empty 1=full)
	let icon_type = 1

	" Go through list of extensions and match appropriate starting icon
	for q in filetypes
		for i in range(2, len(q) - 1)
			if q[i] == a:extension
				return q[icon_type]
			endif
		endfor
	endfor

	return filetypes[0][icon_type]
endfunction

" FUNCTION: s:GetCursorFile() {{{1
function! s:GetCursorFile()
	if line(".") < s:first_line
		return 0
	endif
	
	return g:tree[line(".") - s:first_line]
endfunction

" FUNCTION: s:GetCursorDirectory() {{{1
function! s:GetCursorDirectory()
	let file = s:GetCursorFile()
	silent! if file == 0
		return s:pwd
	endif
	
	let path = s:GetCursorFile().path
	if s:GetProperty(path, "d") == 1
		return path
	else
		return substitute(system("dirname '" . path . "'"), "\n", "", "g")
	endif
endfunction

" FUNCTION: s:GetInsertedTree(subtree, index) {{{1
function! s:GetInsertedTree(tree, subtree, index)
	let tree_len = len(a:tree)
	if a:index < tree_len - 1
		return a:tree[0:(a:index)] + a:subtree + a:tree[(a:index + 1):-1]
	else
		return a:tree + a:subtree
	endif
endfunction

" FUNCTION: s:GetParent(path) {{{1
function! s:GetParent(path)
	return split(system("dirname '" . a:path . "'"), "\n")[0]
endfunction

" FUNCTION: s:GetProperty(path, property) {{{1
function! s:GetProperty(path, property)
	return system("[[ -" . a:property . " '" . a:path . "' ]] && echo 1")
endfunction

" FUNCTION: s:GetShortPath(path) {{{1
function! s:GetShortPath(path)
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

" FUNCTION: s:GetIndex(path) {{{1
function! s:GetIndex(path)
	for i in range(len(g:tree))
		if g:tree[i].path == a:path
			return i
		endif
	endfor
endfunction

" FUNCTION! s:SetOpen(file, to_open) {{{1
function! s:SetOpen(index, to_open)
	let path = g:tree[a:index].path
	let index = index(g:opendirs, path)
	if a:to_open
		let g:tree[a:index].start = substitute(g:tree[a:index].start, "▸", "▾", "")
		if index == -1
			call add(g:opendirs, path)
		endif
			
	else
		let g:tree[a:index].start = substitute(g:tree[a:index].start, "▾", "▸", "")
		if index != -1
			call remove(g:opendirs, index)
		endif
	endif
endfunction

" FUNCTION: s:CursorToFile(index) {{{1
function! s:CursorToFile(index)
	call cursor(a:index + s:first_line, 0)
	
	silent exec "norm! $?" . s:indent_marker . "*"
endfunction

" FUNCTION: s:ToggleDirectory(dir) {{{1
function! s:ToggleDirectory(index)
	let path = g:tree[a:index].path
	if s:GetProperty(path, "f")
		return "Not a directory"
	endif

	let opendir_index = index(g:opendirs, path)
	let level = g:tree[a:index].level

	if opendir_index == -1
		call s:SetOpen(a:index, 1)
		let subtree = s:GenerateTree(path, level + 1)
		let g:tree = s:GetInsertedTree(g:tree, subtree, a:index) 

	else
		call s:SetOpen(a:index, 0)

		let end_index = a:index + 1
		if g:tree[end_index].level <= level
			return
		endif

		while end_index + 1 < len(g:tree) && g:tree[end_index + 1].level > level
			let end_index += 1
		endwhile
		
		if end_index == len(g:tree) - 1
			let g:tree = g:tree[0:(a:index)]
		else
			let g:tree = g:tree[0:(a:index)] + g:tree[end_index + 1:-1]
		endif
	endif
endfunction

" FUNCTION: s:ChangeDirectory(dir) {{{1
function! s:ChangeDirectory(dir)
	let g:dir = a:dir
	if s:GetProperty(a:dir, "f")
		return "Not a directory"
	endif

	let s:pwd = a:dir
	let g:tree = s:GenerateTree(a:dir, 0)
endfunction

