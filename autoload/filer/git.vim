function! filer#git#GitCmd(cmd) " {{{1
	let file_index = filer#functions#CursorIndex()
	let path = g:filer#tree[file_index].path

	" Move to the parent directory of the file
	let real_dir = getcwd()
	let dir = filer#functions#GetCursorDirectory()
	exec "cd " . dir

	" Execute the command in the git directory
	let function_name = toupper(a:cmd[0]) . tolower(a:cmd[1:-1])
	execute "call s:Git" . function_name . "(path)"

	" Go back to the origional directory
	exec "cd " . real_dir

	" Reload filetree in order to update the git icons
	call filer#actions#Reload()
endfunction

" }}}

function! s:GitAdd(path) " {{{1
	silent exec "!git add '" . a:path . "'"
endfunction
" }}}
function! s:GitCommit(path) " {{{1
	let commit_message = input("Commit Message: ")
	exec "!git commit -m '" . commit_message . "'"
endfunction
" }}}
function! s:GitAmmend(path) " {{{1
	let last_commit = split(system("git log --oneline"), "\n")[0]
	let last_message = last_commit[8:-1]
	let commit_message = input("Ammended Commit Message: ", last_message)
	silent exec "!git commit --amend -m '" . commit_message . "'"
endfunction
" }}}
function! s:GitLog(path) " {{{1
	echo system("git log --oneline")
endfunction
" }}}
function! s:GitPush(path) " {{{1
	let g:push = 1
	" Get a list of remotes for the user to pick from
	let remotes = split(system("git remote"), "\n")
	let remote_string = ""
	for i in range(len(remotes))
		let remote_string .= string(i + 1) . " " . remotes[i] . "\n"
	endfor
	" Remove the last newline
	let remote_string = remote_string[0:-2]

	" Ask the user which remote they want to push to
	let remote_index = confirm("Which remote would you like to push to?", remote_string)
	" Exit if the user didn't select a remote
	if remote_index == 0
		echo "No remote selected, didnt push changes"
		return
	endif
	let remote = remotes[remote_index - 1]
	echo "Remote " . remote . " selected"

	" Get a list of branches for the user to pick from
	let branches = split(system("git branch --list"), "\n")
	let branch_string = ""
	for i in range(len(branches))
		let branches[i] = split(branches[i], '\s\+')[-1]
		let branch_string .= string(i + 1) . " " . branches[i] . "\n"
	endfor
	" Remove the last newline
	let branch_string = branch_string[0:-2]

	" Ask the user which branch they want to push to
	let branch_index = confirm("Which branch would you like to push to?", branch_string)
	" Exit if the user didn't select a branch
	if branch_index == 0
		echo "No branch selected, didnt push changes"
		return
	endif
	let branch = branches[branch_index - 1]
	echo "Branch " . branch . " selected"

	" Ask the user if they want to force push
	let should_force = confirm("Would you like to force push?", "N\ny")
	if should_force == 0
		echo "Push cancelled"
		return
	endif
	let force_option = (should_force == 2) ? "-f " : ""

	" Create the command to push based on the user's inputs
	let push_command = printf("git push %s%s %s", force_option, remote, branch)

	" Open a terminal for the user to enter their username and password
	if !&splitbelow
		setlocal splitbelow
		new
		setlocal nosplitbelow
	else
		new
	endif
	" Have to call enew through pressing the keys because it doesnt work otherwise
	silent! call feedkeys(":enew")
	silent! call feedkeys(":call termopen('" . push_command . "')i")
endfunction
" }}}
