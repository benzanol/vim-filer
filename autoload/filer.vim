" ==============================================================================
" Important functions
" ==============================================================================
" Set variables on file load {{{1
let g:filer = {}
let g:filer#icon_type = 'filled' " Can be 'filled', 'outline', 'unicode', or 'text'
let g:filer#buffer_name = '__filer__' " The stored name of the filer buffer
let g:filer#buffer_size = 35 " The width of the filer buffer
let g:filer#buffer_position = 'left' " The side of the screen for the filer to be on
let g:filer#indent_amount = 2 " The number of spaces to indent each subdirectory by

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
	let g:filer#indent_amount = 2 " The number of spaces to indent each subdirectory by
endfunction
" }}}
" FUNCTION: filer#InitializeMappings() {{{1
function! filer#InitializeMappings()
	nnoremap <nowait> <buffer> <silent> <CR> :call filer#actions#Edit()<CR>
	nnoremap <nowait> <buffer> <silent> . :call filer#actions#ShowHidden(-1)<CR>
	nnoremap <nowait> <buffer> <silent> i :call filer#actions#ShowInfo()<CR>

	nnoremap <nowait> <buffer> <silent> <Space> :call filer#actions#Open()<CR>
	nnoremap <nowait> <buffer> <silent> o :call filer#actions#OpenAll()<CR>
	nnoremap <nowait> <buffer> <silent> O :call filer#actions#CloseAll()<CR>

	nnoremap <nowait> <buffer> <silent> r  :call filer#actions#Reload()<CR>
	nnoremap <nowait> <buffer> <silent> k  :call filer#actions#Scroll('up')<CR>
	nnoremap <nowait> <buffer> <silent> j  :call filer#actions#Scroll('down')<CR>
	nnoremap <nowait> <buffer> <silent> h  :call filer#actions#DirMove('up')<CR>
	nnoremap <nowait> <buffer> <silent> l  :call filer#actions#DirMove('down')<CR>
	nnoremap <nowait> <buffer> <silent> H  :call filer#actions#DirShift('up')<CR>
	nnoremap <nowait> <buffer> <silent> L  :call filer#actions#DirShift('down')<CR>

	nnoremap <nowait> <buffer> <silent> ~ :call filer#actions#NavigateTo('~')<CR>
	nnoremap <nowait> <buffer> <silent> u :call filer#actions#NavigateTo('..')<CR>
	
	nnoremap <nowait> <buffer> <silent> f :call filer#menu#FileMenu()<CR>
	nnoremap <nowait> <buffer> <silent> a :call filer#menu#AddMenu()<CR>
	nnoremap <nowait> <buffer> <silent> v :call filer#menu#GitMenu()<CR>
endfunction
" }}}
