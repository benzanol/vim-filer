" FUNCTION: filer#tree#GenerateTree(dir, level) {{{1
function! filer#tree#GenerateTree(dir, level)
	let new_tree = [] " Local variable storing the entire tree for the current level of the function

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
	for q in g:filer#opendirs
		" If there is an open directory in the current directory
		if split(q, "/")[0:-2] == dir_split
			call add(here_opendirs, q)
		endif
	endfor

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
			let new_item.link = "@ " . g:filer#icons.f_redirect . " " . filer#functions#GetShortPath(resolve(new_item.path))
		endif

		" Detect if the file is an open directory
		let is_open_dir = 0
		if indicator == "/"
			if index(here_opendirs, new_item.path) != -1
				let is_open_dir = 1
			endif
		endif

		" Generate icons for each file
		if indicator != "/" " If the file is a regular file
			" Figure out the filetype icon
			if new_item.link == ""
				let file_icon = filer#icons#GetFiletypeIcon(new_item.name)
			else
				let file_icon = g:filer#icons.f_link
			endif

			" Figure out the file's git status
			let git_icon = " "
			if git_dir != ""
				let git_status = system("git status -s '" . new_item.path . "'")
				if git_status == ""
					let git_icon = g:filer#icons.g_committed
				elseif git_status[1:1] == " "
					let git_icon = g:filer#icons.g_added
				else
					let git_icon = g:filer#icons.g_modified
				endif
			endif

			" Set the starting string
			let new_item.start = git_icon . " " . file_icon . " "

		else " If the file is a directory
			if new_item.link == ""
				let dir_icon = g:filer#icons.f_dir
			else
				let dir_icon = g:filer#icons.f_dirlink
			endif

			if is_open_dir
				let new_item.start = g:filer#icons.f_open . " " . dir_icon . " "
				let new_item.open = 1
			else
				let new_item.start = g:filer#icons.f_closed . " " . dir_icon . " "
				let new_item.open = 0
			endif
		endif

		" Add the file to the new tree
		call add(new_tree, new_item)

		" Check if it is an open directory, and if so generate its contents
		if is_open_dir
			let subtree = filer#tree#GenerateTree(new_item.path, a:level + 1)
			let new_tree = new_tree + subtree
		endif

	endfor

	exec "cd " . real_pwd

	return new_tree
endfunction

" }}}
" FUNCTION: filer#tree#ChangeDirectory(dir) {{{1
function! filer#tree#ChangeDirectory(dir)
	if filer#functions#GetProperty(a:dir, "f")
		return "Not a directory"
	endif

	exec "cd " . a:dir
	let g:filer#pwd = a:dir
	let g:filer#tree = filer#tree#GenerateTree(a:dir, 0)
endfunction

" }}}
" FUNCTION: filer#tree#OpenDirectory(index) {{{1
function! filer#tree#OpenDirectory(index)
	let path = g:filer#tree[a:index].path

	" Cancel the function if it isn't a directory, or if it's already open
	let opendir_index = index(g:filer#opendirs, path)
	if filer#functions#GetProperty(path, "f") || opendir_index != -1
		return
	endif

	" Mark the file as open and add it to the list of open directories
	let g:filer#tree[a:index].open = 1
	call add(g:filer#opendirs, path)

	" Change the icon to show that the directory is open
	let g:filer#tree[a:index].start = substitute(g:filer#tree[a:index].start, g:filer#icons.f_closed, g:filer#icons.f_open, "")

	" Add the contents of the directory to the tree
	let subtree = filer#tree#GenerateTree(path, g:filer#tree[a:index].level + 1)
	let tree_len = len(g:filer#tree)
	if a:index < tree_len - 1
		let g:filer#tree = g:filer#tree[0:(a:index)] + subtree + g:filer#tree[(a:index + 1):-1]
	else
		let g:filer#tree = g:filer#tree + subtree
	endif
endfunction

" }}}
" FUNCTION: filer#tree#CloseDirectory(index) {{{1
function! filer#tree#CloseDirectory(index)
	let path = g:filer#tree[a:index].path

	" Cancel the function if it isn't a directory, or if it's already open
	let opendir_index = index(g:filer#opendirs, path)
	if filer#functions#GetProperty(path, "f") || opendir_index == -1
		return
	endif

	" Mark the file as closed, and remove it from the list of open directories
	let g:filer#tree[a:index].open = 0
	call remove(g:filer#opendirs, opendir_index)

	" Change the icon to show that the directory is closed
	let g:filer#tree[a:index].start = substitute(g:filer#tree[a:index].start, g:filer#icons.f_open, g:filer#icons.f_closed, "")

	" Remove the contents of the directory from the tree
	let level = g:filer#tree[a:index].level
	let end_index = a:index + 1
	if g:filer#tree[end_index].level <= level
		return
	endif

	while end_index + 1 < len(g:filer#tree) && g:filer#tree[end_index + 1].level > level
		let end_index += 1
	endwhile

	if end_index == len(g:filer#tree) - 1
		let g:filer#tree = g:filer#tree[0:(a:index)]
	else
		let g:filer#tree = g:filer#tree[0:(a:index)] + g:filer#tree[end_index + 1:-1]
	endif
endfunction

" }}}
