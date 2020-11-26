" Initialize script variables {{{1
let g:sidebars = {}
let s:plugin_path = expand("<sfile>:p:h:h")
let s:name = "SidebarPlugin"
let s:position = "left"
let s:width = 40
let s:color = "#171A23"

" Launch a certain drawer {{{1
function! sidebar#Open(drawer)
	let buffer_number = bufnr(s:name)
	if buffer_number == -1 " If there is not an existing sidebar, create one
		let g:action = "Create"
		vnew

	else
		let window_number = bufwinnr(s:name)
		if window_number == -1 " If the sidebar isn't open, create a new split and open it
			let g:action = "Open"
			vnew
			exec "buffer" . buffer_number

		else " If the sidebar is open, navigate to it
			let g:action = "Navigate"
			exec window_number . "wincmd w"
		endif
	endif

	" Move buffer to far side of screen
	exec "wincmd " . (s:position == "left" ? "H" : "L")
	exec "vertical resize" . s:width

	" Set settings in case they aren't already
	let &buftype = "nofile"
	exec "file " . s:name
	setlocal nobuflisted
	setlocal nonumber
	setlocal cursorline
	setlocal hidden
	setlocal nomodifiable
	setlocal foldmethod=manual
	setlocal nolist
	setlocal nowrap
	setlocal winfixheight
	setlocal winfixwidth

	" Initialize the drawer if it hasn't been already
	if !has_key(g:sidebars, a:drawer)
		let g:sidebars[a:drawer] = {}
		exec "call " . a:drawer . "#Initialize()"
	endif
	
	" Create the appropriate keybindings for the drawer
	let mappings = g:sidebars[a:drawer].mappings
	for q in keys(mappings)
		let g:newmap = "nnoremap <silent> " . q . " :call " . a:drawer . "#" . mappings[q] . "<CR>"
		exec g:newmap
	endfor

	" Enable syntax highlighting for the drawer
	exec "source " . s:plugin_path . "/syntax/" . a:drawer . ".vim"
endfunction

" Print out a list of lines {{{1
function! sidebar#Print(text)
	setlocal modifiable

	" Save cursor location before redraw
	let cursor_location = [line("."), col(".")]

	" Replace all current text with new text
	silent exec "0," . line("$") . "delete"
	for q in a:text
		put =q
	endfor
	silent 1delete

	" Move cursor up and down file to load colors
	norm! gg
	exec "norm! " . line("$") . "j"
	
	" Move cursor to previous location
	call cursor(cursor_location)

	" Enable syntax highlighting
	exec "hi SidebarBody ctermbg=NONE guibg=" . s:color
	setlocal winhl=Normal:SidebarBody

	setlocal nomodifiable
endfunction
