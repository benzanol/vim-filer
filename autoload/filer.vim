" ==============================================================================
" Important functions
" ==============================================================================
" Set variables on file load {{{1
let g:filer = {}
let g:filer#icon_type = 'filled' " Can be 'filled', 'outline', 'unicode', or 'text'
let g:filer#indent_marker = '│ ' " The marker to show the change in level between files
let g:filer#buffer_name = '__filer__' " The stored name of the filer buffer
let g:filer#buffer_size = 35 " The width of the filer buffer
let g:filer#buffer_position = 'left' " The side of the screen for the filer to be on

let s:script_path = expand("<sfile>:p")
let s:plugin_path = expand("<sfile>:p:h:h")
" }}}

" FUNCTION: filer#Launch() {{{1
function! filer#Launch()
	" Call other initialization functions
	if !exists("s:filer_open")
		let s:filer_open = 1
		call filer#InitializeVariables()
		call filer#icons#InitializeIcons()
	endif

	call filer#InitializeBuffer()
	call filer#InitializeMappings()

	" Generate the starting tree
	let g:filer#pwd = getcwd()
	let g:filer#tree = filer#tree#GenerateTree(getcwd(), 0) " Stores a list of file/level pairs, representing each files distance from the root directory

	" Draw the filer to the screen
	call filer#display#Print()
endfunction

" }}}
" FUNCTION: filer#InitializeBuffer() {{{1
function! filer#InitializeBuffer()
	let window_number = bufwinnr(g:filer#buffer_name)
	if window_number == -1 " If the sidebar isn't open, create a new split and open it
		silent! exec "vnew " . g:filer#buffer_name

	else " If the sidebar is open, navigate to it
		exec window_number . "wincmd w"
	endif

	" Move buffer to far side of screen
	exec "wincmd " . (g:filer#buffer_position == "left" ? "H" : "L")
	exec "vertical resize" . g:filer#buffer_size

	" Set settings in case they aren't already
	let &buftype = "nofile"
	setlocal nobuflisted
	setlocal hidden
	setlocal nonumber
	setlocal nomodifiable
	setlocal foldmethod=manual
	setlocal nolist
	setlocal nowrap
	setlocal winfixheight
	setlocal winfixwidth
endfunction
" }}}
" FUNCTION: filer#InitializeVariables() {{{1
function! filer#InitializeVariables()
	let g:g:filer#pwd = getcwd()
	let g:filer#opendirs = [] " Stores a list of paths representing directories for which the contents should be displayed in the tree
	let g:filer#show_hidden = 0 " Boolean representing whether hidden files should be shown in the tree
	let g:filer#first_line = 2 " First line of tree after any heading text
	let s:indent_marker = "│ "
endfunction
" }}}
" FUNCTION: filer#InitializeMappings() {{{1
function! filer#InitializeMappings()
	let mappings = {}

	let mappings["<CR>"] = "Edit()"
	let mappings["."] = "ShowHidden(-1)"
	let mappings.v = "ShowInfo()"

	let mappings["<Space>"] = "Open()"
	let mappings.o = "OpenAll()"
	let mappings.O = "CloseAll()"

	let mappings.r  = "Reload()"
	let mappings.k  = "Scroll('up')"
	let mappings.j  = "Scroll('down')"
	let mappings.h  = "DirMove('up')"
	let mappings.l  = "DirMove('down')"
	let mappings.H  = "DirShift('up')"
	let mappings.L  = "DirShift('down')"

	let mappings["~"] = "NavigateTo('~')"
	let mappings.th = "NavigateTo('~')"
	let mappings.tr = "NavigateTo('/')"
	let mappings.u = "NavigateTo('..')"

	let mappings.a  = "AddFile(' ')"
	let mappings.af = "AddFile('f')"
	let mappings.ad = "AddFile('d')"

	let mappings.fx = "SetExecutable(-1)"
	let mappings.fd = "DeleteFile()"
	let mappings.fr = "RenameFile()"
	let mappings.fm = "MoveFile('move')"
	let mappings.fc = "MoveFile('copy')"
	let mappings.fl = "MoveFile('link')"

	let mappings.ga = "GitCmd('add')"
	let mappings.gc = "GitCmd('commit')"
	let mappings.gC = "GitCmd('ammend')"
	let mappings.gl = "GitCmd('log')"

	silent map clear
	for q in keys(mappings)
		exec "nnoremap <buffer> <silent> " . q . " :call filer#actions#" . mappings[q] . "<CR>"
	endfor
endfunction
" }}}
