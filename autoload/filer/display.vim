" FUNCTION: filer#display#GetText() {{{1
function! filer#display#GetText()
	" Get the longest version of the heading that will fit in the window
	if g:filer#pwd == "/"
		let heading = "/"
	else
		let heading = g:filer#pwd . "/"
	endif

	if len(heading) > winwidth(0)
		let heading = substitute(g:filer#pwd, $HOME, "~", "") . "/"

		if len(heading) > winwidth(0)
			let heading = filer#functions#GetShortPath(g:filer#pwd) . "/"
			if len(heading) > winwidth(0)
				let heading = split(g:filer#pwd, "/")[-1] . "/"
			endif
		endif
	endif

	" Convert the tree list into a formatted string with line breaks and indents
	let output = [heading]

	for q in g:filer#tree
		if g:filer#show_hidden == 0 && filer#functions#IsHidden(q.path)
			continue
		endif

		let indent = repeat(g:filer#indent_marker, q.level + 1)

		call add(output, indent . q.start . " " . q.name . q.link . q.end)
	endfor

	return output
endfunction

" }}}
" FUNCTION: filer#display#Print() {{{1
function! filer#display#Print()
	setlocal modifiable

	" Generate the text
	let text = filer#display#GetText()

	" Save cursor location before redraw
	let cursor_location = [line("."), col(".")]

	" Replace all current text with new text
	silent exec "0," . line("$") . "delete"
	for q in text
		put =q
	endfor
	silent 1delete

	" Move cursor up and down file to load colors
	norm! gg
	exec "norm! " . line("$") . "j"

	" Move cursor to previous location
	call cursor(cursor_location)

	" Enable colors
	call filer#colors#SetColors()

	setlocal nomodifiable
endfunction
" }}}
