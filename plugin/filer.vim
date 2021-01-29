" ==============================================================================
" Important functions
" ==============================================================================
" Initialize default variables
let g:filer = {}
let g:filer#icon_type = 'filled' " Can be 'filled', 'outline', 'unicode', or 'text'
let g:filer#buffer_name = '__filer__' " The stored name of the filer buffer
let g:filer#buffer_size = 35 " The width of the filer buffer
let g:filer#buffer_position = 'left' " The side of the screen for the filer to be on
let g:filer#indent_amount = 2 " The number of spaces to indent each subdirectory by
let g:filer#pwd = getcwd()
let g:filer#opendirs = [] " Stores a list of paths representing directories for which the contents should be displayed in the tree
let g:filer#show_hidden = 0 " Boolean representing whether hidden files should be shown in the tree
let g:filer#first_line = 2 " First line of tree after any heading text
let g:filer#indent_amount = 2 " The number of spaces to indent each subdirectory by
let g:filer#enable_highlight = 0 " Whether or not to invert the colors of the current line to make it appear selected

" Initialize commands
command! FilerOpen call filer#Open()
command! FilerClose call filer#Close()
command! FilerToggle if filer#IsOpen() | call filer#Close() | else | call filer#Open() | endif
