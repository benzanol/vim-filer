" FUNCTION: filer#Open() {{{1
function! filer#Open()
	call filer#InitializeBuffer()

	if !exists('s:called_before')
		call filer#InitializeMappings()
		call filer#icons#InitializeIcons()
		let s:called_before = 1
	endif

	" Generate the starting tree
	let g:filer#pwd = getcwd()
	let g:filer#tree = filer#tree#GenerateTree(getcwd(), 0) " Stores a list of file/level pairs, representing each files distance from the root directory

	" Draw the filer to the screen
	call filer#display#Print()
endfunction
" }}}
" FUNCTION: filer#Close() {{{1
function! filer#Close()
	let window = bufwinnr(g:filer#buffer_name)
	if window > 0
		execute window . 'close!'
	endif
endfunction
" }}}
" FUNCTION: filer#IsOpen() {{{1
function! filer#IsOpen()
	let window = bufwinnr(g:filer#buffer_name)
	if window > 0
		return 1
	else
		return 0
	endif
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
	setlocal signcolumn=no

	" Make cursor always stay at the beginning of the line
	autocmd CursorMoved <buffer> call cursor(line("."), 1)
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
