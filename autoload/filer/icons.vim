" FUNCTION: filer#icons#GetFiletypeIcon(file) {{{1
function! filer#icons#GetFiletypeIcon(file)
	let file_split = split(a:file, "\\.")
	if len(file_split) <= 1 || g:filer#icon_type == "text"
		return g:filer#icons.f_file
	endif

	let extension = file_split[-1]

	if has_key(g:filer#icons, "e_" . extension)
		return g:filer#icons["e_" . extension]
	else
		return g:filer#icons.f_file
	endif
endfunction

" }}}
" FUNCTION: filer#icons#InitializeIcons() {{{1
function! filer#icons#InitializeIcons()
	let g:filer#icons = {}

	let filetypes = []
	call add(filetypes, {"type":"archive", "unicode":"🖹", "outline":"", "filled":"", "extensions":["tar", "zip", "gz", "xz", "bz2"]})
	call add(filetypes, {"type":"text",    "unicode":"🖹", "outline":"", "filled":"", "extensions":["txt", "doc", "docx"]})
	call add(filetypes, {"type":"image",   "unicode":"🖻", "outline":"", "filled":"", "extensions":["png", "jpg", "jpeg", "gif"]})
	call add(filetypes, {"type":"video",   "unicode":"⏵", "outline":"", "filled":"", "extensions":["mp4", "mov", "wmv", "webm"]})
	call add(filetypes, {"type":"audio",   "unicode":"𝅘𝅥𝅮", "outline":"", "filled":"", "extensions":["mp3", "wav", "flac"]})
	call add(filetypes, {"type":"code",    "unicode":"🖹", "outline":"", "filled":"", "extensions":["exe", "AppImage", "java", "py", "c", "js", "sh", "bash", "zsh", "fish"]})
	call add(filetypes, {"type":"pdf",     "unicode":"🖹", "outline":"", "filled":"", "extensions":["pdf"]})
	call add(filetypes, {"type":"vim",     "unicode":"🖹", "outline":"", "filled":"", "extensions":["vim"]})

	if g:filer#icon_type == "filled" || g:filer#icon_type == "outline" || g:filer#icon_type == "unicode"
		for q in filetypes
			for r in q.extensions
				let g:filer#icons["e_" . r] = q[g:filer#icon_type]
			endfor
		endfor
	endif

	let file_categories = []
	call add(file_categories, {"type":"dir",      "text":"d", "unicode":"🖿", "outline":"", "filled":""})
	call add(file_categories, {"type":"dirlink",  "text":"@", "unicode":"@", "outline":"", "filled":""})
	call add(file_categories, {"type":"file",     "text":"f", "unicode":"🖹", "outline":"", "filled":""})
	call add(file_categories, {"type":"link",     "text":"@", "unicode":"@", "outline":"", "filled":""})
	call add(file_categories, {"type":"hidden",   "text":"f", "unicode":"🖹", "outline":"﬒", "filled":"﬒"})
	call add(file_categories, {"type":"closed",   "text":">", "unicode":"▸", "outline":"▸", "filled":"▸"})
	call add(file_categories, {"type":"open",     "text":"v", "unicode":"▾", "outline":"▾", "filled":"▾"})
	call add(file_categories, {"type":"redirect", "text":">", "unicode":"➝", "outline":">", "filled":">"})

	for q in file_categories
		let g:filer#icons["f_" . q.type] = q[g:filer#icon_type]
	endfor

	" Git icons
	let git_options = []
	call add(git_options, {"type":"committed", "text":"*", "unicode":"✓", "outline":"✓", "filled":"✓"})
	call add(git_options, {"type":"added",     "text":"+", "unicode":"+", "outline":"✚", "filled":"✚"})
	call add(git_options, {"type":"modified",  "text":"x", "unicode":"×", "outline":"✗", "filled":"✗"})

	for q in git_options
		let g:filer#icons["g_" . q.type] = q[g:filer#icon_type]
	endfor

	let g:filer_icons = g:filer#icons
endfunction

" }}}
