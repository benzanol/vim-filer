" FUNCTION: filetree#display#GetText()
function! filetree#display#GetText()
	" Get the longest version of the heading that will fit in the window
	if g:filetree#pwd == "/"
		let heading = "/"
	else
		let heading = g:filetree#pwd . "/"
	endif

	if len(heading) > winwidth(0)
		let heading = substitute(g:filetree#pwd, $HOME, "~", "") . "/"

		if len(heading) > winwidth(0)
			let heading = filetree#functions#GetShortPath(g:filetree#pwd) . "/"
			if len(heading) > winwidth(0)
				let heading = split(g:filetree#pwd, "/")[-1] . "/"
			endif
		endif
	endif

	" Convert the tree list into a formatted string with line breaks and indents
	let output = [heading]

	for q in g:filetree#tree
		if g:filetree#show_hidden == 0 && filetree#functions#IsHidden(q.path)
			continue
		endif

		let indent = repeat(g:filetree#indent_marker, q.level + 1)

		call add(output, indent . q.start . " " . q.name . q.link . q.end)
	endfor

	return output
endfunction

" FUNCTION: filetree#display#Print()
function! filetree#display#Print()
	setlocal modifiable

	" Generate the text
	let text = filetree#display#GetText()

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
	call filetree#colors#SetColors()

	setlocal nomodifiable
endfunction
