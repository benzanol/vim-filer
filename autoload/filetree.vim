" ==============================================================================
" Important functions
" ==============================================================================
" FUNCTION: filetree#Initialize() {{{1
function! filetree#Initialize()
	call s:InitializeMappings()
	call s:InitializeIcons()

	let s:pwd = getcwd()
	let g:opendirs = [] " Stores a list of paths representing directories for which the contents should be displayed in the tree
	let s:show_hidden = 0 " Boolean representing whether hidden files should be shown in the tree
	let s:first_line = 2 " First line of tree after any heading text
	let s:indent_marker = "│ "
	let s:link_icon = "→"

	let g:tree = s:GenerateTree(getcwd(), 0) " Stores a list of file/level pairs, representing each files distance from the root directory

	" Draw the filetree to the screen
	call s:Print()
endfunction

" }}}
" FUNCTION: s:InitializeMappings() {{{1
function! s:InitializeMappings()
	let s:mappings = {}
	let s:mappings["<CR>"] = "NavigateTo()"
	let s:mappings["."] = "ShowHidden(-1)"
	let s:mappings.v = "ShowInfo()"

	let s:mappings["<Space>"] = "Open()"
	let s:mappings.o = "OpenAll()"
	let s:mappings.O = "CloseAll()"

	let s:mappings.r  = "Reload()"
	let s:mappings.k  = "Scroll('up')"
	let s:mappings.j  = "Scroll('down')"
	let s:mappings.u  = "DirShift('up')"
	let s:mappings.U  = "DirShift('down')"
	let s:mappings.h  = "DirMove('up')"
	let s:mappings.l  = "DirMove('down')"
	
	let s:mappings.a  = "AddFile(' ')"
	let s:mappings.af = "AddFile('f')"
	let s:mappings.ad = "AddFile('d')"

	let s:mappings.fx = "SetExecutable(-1)"
	let s:mappings.fd = "DeleteFile()"
	let s:mappings.fr = "RenameFile()"
	let s:mappings.fm = "MoveFile()"
	let s:mappings.fc = "CopyFile()"

	let s:mappings.ga = "GitFile('add')"
	let s:mappings.gc = "GitFile('commit')"
	let s:mappings.gC = "GitFile('ammend')"

	let g:sidebars.filetree.mappings = s:mappings
endfunction
" }}}
" FUNCTION: s:InitializeIcons() {{{1
function! s:InitializeIcons()
	" let icon_type = 'outline'
	let icon_type = 'filled'

	let s:filetypes = []
	call add(s:filetypes, {"type":"archive", "outline":"", "filled":"", "extensions":["tar", "zip", "gz", "xz", "bz2"]})
	call add(s:filetypes, {"type":"text",    "outline":"", "filled":"", "extensions":["txt", "doc", "docx"]})
	call add(s:filetypes, {"type":"image",   "outline":"", "filled":"", "extensions":["png", "jpg", "jpeg", "gif"]})
	call add(s:filetypes, {"type":"video",   "outline":"", "filled":"", "extensions":["mp4", "mov", "wmv", "webm"]})
	call add(s:filetypes, {"type":"audio",   "outline":"", "filled":"", "extensions":["mp3", "wav", "flac"]})
	call add(s:filetypes, {"type":"code",    "outline":"", "filled":"", "extensions":["sh", "bash", "zsh", "fish"]})
	call add(s:filetypes, {"type":"pdf",     "outline":"", "filled":"", "extensions":["pdf"]})
	call add(s:filetypes, {"type":"vim",     "outline":"", "filled":"", "extensions":["vim"]})

	let s:type_icons = {}
	for q in s:filetypes
		for r in q.extensions
			let s:type_icons[r] = q[icon_type]
		endfor
	endfor

	let s:file_categories = []
	call add(s:file_categories, {"type":"dir",     "outline":"", "filled":""})
	call add(s:file_categories, {"type":"dirlink", "outline":"", "filled":""})
	call add(s:file_categories, {"type":"file",    "outline":"", "filled":""})
	call add(s:file_categories, {"type":"link",    "outline":"", "filled":""})
	call add(s:file_categories, {"type":"hidden",  "outline":"﬒", "filled":"﬒"})

	let s:file_icons = {}
	for q in s:file_categories
		let s:file_icons[q.type] = q[icon_type]
	endfor

	" Git icons
	let s:git_icons = {}
	let s:git_icons.committed = "✓"
	let s:git_icons.added = "✚"
	let s:git_icons.modified = "✗"
endfunction
" }}}

" FUNCTION: s:Print() {{{1
function! s:Print()
	call sidebar#Print(s:GetText())
endfunction

" }}}
" FUNCTION: s:GetText() {{{1
function! s:GetText()
	" Get the longest version of the heading that will fit in the window
	if s:pwd == "/"
		let heading = "/"
	else
		let heading = s:pwd . "/"
	endif

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
		if s:show_hidden == 0 && s:IsHidden(q.path)
			continue
		endif

		let indent = repeat(s:indent_marker, q.level + 1)
		call add(output, indent . q.start . " " . q.name . q.link . q.end . " ")
	endfor

	return output
endfunction

" }}}
" FUNCTION: filetree#Get(expr) {{{1
function! filetree#Get(expr)
	exec "return " . a:expr
endfunction

" }}}

" ==============================================================================
" Keyboard mapping functions
" ==============================================================================
" FUNCTION: filetree#Reload() {{{1
function! filetree#Reload()
	let g:tree = s:GenerateTree(s:pwd, 0)
	call s:Print()
endfunction

" }}}
" FUNCTION: filetree#Scroll(direction) {{{1
function! filetree#Scroll(direction)
	if a:direction == "up"
		norm! k
	else
		norm! j
	endif
endfunction
" }}}
" FUNCTION: filetree#NavigateTo() {{{1
function! filetree#NavigateTo()
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = g:tree[file_index].path
	endif

	if s:GetProperty(path, "d")
		call s:ChangeDirectory(path)
		call s:Print()
	else
		wincmd p
		exec "edit " . resolve(path)
	endif
endfunction

" }}}
" FUNCTION: filetree#Open() {{{1
function! filetree#Open()
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = g:tree[file_index].path
	endif

	if s:GetProperty(path, "d")
		call s:ToggleDirectory(file_index)
	else
		call s:ViewFile(path)
	endif

	call s:Print()
endfunction

" }}}
" FUNCTION: filetree#OpenAll() {{{1
function! filetree#OpenAll()
	let level = 0
	while 1
		let dir_list = []
		let any_closed = 0

		for q in g:tree
			if q.level == level && q.end == "/"
				call add(dir_list, q)
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
			for q in dir_list
				if !q.open
					call add(g:opendirs, q.path)
				endif
			endfor
			
			call filetree#Reload()
			return
		endif
	endwhile
endfunction

" }}}
" FUNCTION: filetree#CloseAll() {{{1
function! filetree#CloseAll()
	let g:opendirs = []
	call filetree#Reload()
endfunction

" }}}
" FUNCTION: filetree#DirShift(direction) {{{1
function! filetree#DirShift(direction)
	let file_index = s:CursorIndex()
	if file_index == -1
		let path = s:pwd
	else
		let path = g:tree[file_index].path
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
	call s:Print()
	call cursor(s:GetLine(path), 1)
endfunction

" }}}
" FUNCTION: filetree#DirMove(direction) {{{1
function! filetree#DirMove(direction)
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = g:tree[file_index].path
	endif

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

		call s:Print()
		call cursor(s:GetLine(new_path), 1)

		" If moving down a level (l)
	elseif a:direction == "down"
		if s:GetProperty(path, "d")
			" If the directory is closed, open it
			if index(g:opendirs, path) == -1
				call s:ToggleDirectory(s:GetIndex(path))
				call s:Print()
			endif

			" If there are any files, go to the first one
			if file_index != len(g:tree) - 1 && g:tree[file_index + 1].level > g:tree[file_index].level
				norm j
			endif
		endif
	endif
endfunction

" }}}
" FUNCTION: filetree#ShowInfo() {{{1
function! filetree#ShowInfo()
	let path = g:tree[s:CursorIndex()].path
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
" FUNCTION: filetree#ShowHidden(value) {{{1
function! filetree#ShowHidden(value)
	let path = g:tree[s:CursorIndex()].path
	if a:value == 0
		let s:show_hidden = 0
	elseif a:value == 1
		let s:show_hidden = 1
	else
		let s:show_hidden = !s:show_hidden
	endif

	call s:Print()
	call cursor(s:GetLine(path), 1)
endfunction

" }}}

" FUNCTION: filetree#AddFile(type) {{{1
function! filetree#AddFile(type)
	if a:type == "f" || a:type == "file"
		let type = 1
	elseif a:type == "d" || a:type == "directory" || a:type == "dir"
		let type = 2
	else
		let type = confirm("What would you like to create? ", "&File\n&Directory")
	endif

	let name = input("New file name: ")
	let dir = s:GetCursorDirectory()
	let cmd = (type == 1) ? "touch" : "mkdir"

	exec "silent " . substitute("!" . cmd . " '" . dir . "/" . name . "'", "\n", "", "g")

	call filetree#Reload()
endfunction

" }}}
" FUNCTION: filetree#SetExecutable(value) {{{1
function! filetree#SetExecutable(value) 
	let file_index = s:CursorIndex()
	if file_index == -1 || g:tree[file_index].end == "/"
		return
	else
		let path = g:tree[file_index].path
	endif
	
	if a:value == 0
		silent exec "!chmod -x '" . path . "'"
		let g:tree[file_index].end = ""
	elseif a:value == 1
		silent exec "!chmod +x '" . path . "'"
		let g:tree[file_index].end = "*"
	else
		if g:tree[file_index].end == "*"
			silent exec "!chmod -x '" . path . "'"
			let g:tree[file_index].end = ""
		else
			silent exec "!chmod +x '" . path . "'"
		let g:tree[file_index].end = "*"
		endif
	endif

	call s:Print()
endfunction

" }}}
" FUNCTION: filetree#DeleteFile() {{{1
function! filetree#DeleteFile()
	let file_index = s:CursorIndex()
	if file == -1
		let path = s:pwd
		let s:pwd = system("dirname '" . system("dirname '" . s:pwd . "'") . "'")
	else
		let path = g:tree[file_index].path
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

" }}}
" FUNCTION: filetree#RenameFile() {{{1
function! filetree#RenameFile()
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = g:tree[file_index].path
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

	call filetree#Reload()
endfunction

" }}}
" FUNCTION: filetree#MoveFile() {{{1
function! filetree#MoveFile()
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = g:tree[file_index].path
	endif

	let new_path = input("New path: ")

	silent exec "!mv '" . path . "' '" . new_path . "'"

	call filetree#Reload()
endfunction

" }}}
" FUNCTION: filetree#CopyFile() {{{1
function! filetree#CopyFile()
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = g:tree[file_index].path
	endif

	let new_path = input("Path of copy: ")

	silent exec "!cp -rf '" . path . "' '" . new_path . "'"

	call filetree#Reload()
endfunction

" }}}
" FUNCTION: filetree#GitFile(cmd) {{{1
function! filetree#GitFile(cmd)
	let file_index = s:CursorIndex()
	if file_index == -1
		return
	else
		let path = g:tree[file_index].path
	endif

	" Move to the parent directory of the file
	let real_dir = getcwd()
	let dir = s:GetCursorDirectory()
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
	endif

	" Go back to the origional directory
	exec "cd " . real_dir

	call filetree#Reload()
endfunction

" }}}

" ==============================================================================
" Reference functions
" ==============================================================================
" FUNCTION: s:GenerateTree(dir, level) {{{1
let g:myvar = {}
function! s:GenerateTree(dir, level)
	let new_tree = [] " Local variable storing the entire tree for the current level of the function

	" Setup steps to perform for the current directory {{{2
	" Get the list of files in the current directory, and with link endings
	let cmd = "ls -AFv --group-directories-first"
	let files = split(system(cmd . " -L '" . a:dir . "' 2> /dev/null"), "\n")
	let link_ending = split(system(cmd . " -H '" . a:dir . "' 2> /dev/null"), "\n")

	" Detect if the current directory is a git directory
	let real_pwd = getcwd()
	exec "cd " . a:dir

	let git_dir = split(system("git rev-parse --show-toplevel"), "\n")[0]
	if git_dir[0] != "/"
		let git_dir = ""
	endif

	" Get a prefix to add to the beginning of all of the files to represent their full path
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

	" }}}
	" Loop through each file in the specified directory
	for i in range(len(files))
		let file = files[i]
		let indicator = file[-1:-1]

		" Create a new list for the current tree item
		let new_item = {}
		let new_item.level = a:level
		let new_item.pwd = getcwd()

		" Get the name of the file
		if indicator == "*" || indicator == "/"
			let new_item.name = file[0:-2]
			let new_item.end = indicator
		else
			let new_item.name = file
			let new_item.end = ""
		endif
		let new_item.path = dir_prefix . new_item.name

		" Detect if file is a link
		let new_item.link = ""
		if link_ending[i][-1:-1] == "@"
			let new_item.link = " → " . s:GetShortPath(resolve(new_item.path))
		endif

		" Detect if the file is an open directory
		let is_open_dir = 0
		if indicator == "/"
			if index(here_opendirs, new_item.path) != -1
				let is_open_dir = 1
			endif
		endif

		" Generate icons for each file {{{2
		" If file is a regular file
		if indicator != "/"
			" Figure out the filetype icon
			if new_item.link == ""
				let file_icon = s:GetFiletypeIcon(new_item.name)
			else
				let file_icon = s:file_icons.link
			endif

			" Figure out git status
			let git_icon = " "
			if git_dir != ""
				let git_status = system("git status -s '" . new_item.path . "'")
				if git_status == ""
					let git_icon = s:git_icons.committed
				elseif git_status[1:1] == " "
					let git_icon = s:git_icons.added
				else
					let git_icon = s:git_icons.modified
				endif
			endif

			" Set the starting string
			let new_item.start = git_icon . " " . file_icon . " "
			" If the file is a directory
		else
			if new_item.link == ""
				let dir_icon = s:file_icons.dir
			else
				let dir_icon = s:file_icons.dirlink
			endif

			if is_open_dir
				let new_item.start = "▾ " . dir_icon . " "
				let new_item.open = 1
			else
				let new_item.start = "▸ " . dir_icon . " "
				let new_item.open = 0
			endif
		endif
		" }}}

		" Add the file to the new tree
		call add(new_tree, new_item)

		" Check if it is an open directory, and if so generate its contents
		if is_open_dir
			let subtree = s:GenerateTree(new_item.path, a:level + 1)
			let new_tree = new_tree + subtree
		endif

	endfor

	exec "cd " . real_pwd

	return new_tree
endfunction

" }}}
" FUNCTION: s:GetFiletypeIcon(file) {{{1
function! s:GetFiletypeIcon(file)
	let file_split = split(a:file, "\\.")
	if len(file_split) <= 1
		return s:file_icons.file
	endif

	let extension = file_split[-1]

	if has_key(s:type_icons, extension)
		return s:type_icons[extension]
	else
		return s:file_icons.file
	endif
endfunction
" }}}
" FUNCTION: s:CursorIndex() {{{1
function! s:CursorIndex()
	let line = line(".") - s:first_line
	if line(".") < 0
		return -1
	endif

	if s:show_hidden == 1
		return line
	endif

	let count = 0
	let index = 0
	while count <= line
		if !s:IsHidden(g:tree[index].path)
			let count += 1
		endif
		let index += 1
	endwhile

	return index - 1
endfunction

" }}}
" FUNCTION: s:GetCursorDirectory() {{{1
function! s:GetCursorDirectory()
	let file_index = s:CursorIndex()
	if file_index == -1
		return s:pwd
	endif

	let path = g:tree[file_index].path
	if s:GetProperty(path, "d") == 1
		return path
	else
		return substitute(system("dirname '" . path . "'"), "\n", "", "g")
	endif
endfunction

" }}}
" FUNCTION: s:GetIndex(path) {{{1
function! s:GetIndex(path)
	let index = 0
	for q in g:tree
		if q.path == a:path
			return index
		endif

		let index += 1
	endfor

	return s:first_line
endfunction

" }}}
" FUNCTION: s:GetLine(path) {{{1
function! s:GetLine(path)
	let index = 0
	for q in g:tree
		if q.path == a:path
			return index + s:first_line
		endif

		if s:show_hidden || !s:IsHidden(q.path)
			let index += 1
		endif
	endfor

	return s:first_line
endfunction

" }}}
" FUNCTION: s:IsHidden(path) {{{1
function! s:IsHidden(path)
	let path_split = split(a:path, "/")
	for q in path_split
		if q[0:0] == "."
			return 1
		endif
	endfor

	return 0
endfunction

" }}}
" FUNCTION: s:GetInsertedTree(subtree, index) {{{1
function! s:GetInsertedTree(tree, subtree, index)
	let tree_len = len(a:tree)
	if a:index < tree_len - 1
		return a:tree[0:(a:index)] + a:subtree + a:tree[(a:index + 1):-1]
	else
		return a:tree + a:subtree
	endif
endfunction

" }}}
" FUNCTION: s:GetParent(path) {{{1
function! s:GetParent(path)
	return split(system("dirname '" . a:path . "'"), "\n")[0]
endfunction

" }}}
" FUNCTION: s:GetProperty(path, property) {{{1
function! s:GetProperty(path, property)
	return system("[[ -" . a:property . " '" . a:path . "' ]] && echo 1")
endfunction

" }}}
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

" }}}
" FUNCTION: s:SetOpen(file, to_open) {{{1
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

" }}}
" FUNCTION: s:ToggleDirectory(index) {{{1
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

" }}}
" FUNCTION: s:ChangeDirectory(dir) {{{1
function! s:ChangeDirectory(dir)
	if s:GetProperty(a:dir, "f")
		return "Not a directory"
	endif

	exec "cd " . a:dir
	let s:pwd = a:dir
	let g:tree = s:GenerateTree(a:dir, 0)
endfunction

" }}}
