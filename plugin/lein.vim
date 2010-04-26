" Vim Plugin for Leiningen
" Author  : Masashi Iizuka
" License : The MIT License
" URL     : http://github.com/liquidz/lein-vim

" =global options {{{
if !exists('g:lein_command')
    let g:lein_command = 'lein'
endif
if !exists('g:lein_project')
	let g:lein_project = "project.clj"
endif
if !exists('g:lein_find_max')
	let g:lein_find_max = 10
endif
if !exists('g:lein_direction')
	let g:lein_direction = "rightbelow"
endif
if !exists('g:lein_temporary')
	let g:lein_temporary = ".LEIN_TMP"
endif
if !exists('g:clojars_command')
	let g:clojars_command = "scp pom.xml %s clojars@clojars.org:"
endif
if !exists('g:lein_project_not_found')
	let g:lein_project_not_found = g:lein_project . " is not found."
endif
" }}}

" =key mappings {{{
if !exists('g:lein_no_map_default') || !g:lein_no_map_default
	nnoremap <Leader>lt :LeinTest<Enter>
	nnoremap <Leader>lj :LeinJar<Enter>
	nnoremap <Leader>lm :LeinPom<Enter>
	nnoremap <Leader>ld :LeinDeps<Enter>
	nnoremap <Leader>li :LeinInstall<Enter>
	nnoremap <Leader>lu :LeinUberJar<Enter>
	nnoremap <Leader>lc :LeinCompile<Enter>
	nnoremap <Leader>lp :PushToClojars<Enter>
endif
" }}}

" =reverse_find

function! s:reverse_find(filename, path)
	if fnamemodify(a:path, ':p:h') == '/'
		let filelist = glob('/' . a:filename)
		return (filelist == '') ? 0 : filelist
	else
		let filelist = glob(a:path . '/' . a:filename)
		if filelist == ''
			return <SID>reverse_find(a:filename, '../' . a:path)
		else
			return filelist
		endif
	endif
endfunction

" =get_project_dir
function! s:get_project_dir()
	let project_file = <SID>reverse_find(g:lein_project, ".")
	if project_file is 0
		return 0
	else
		return fnamemodify(project_file, ":p:h")
	endif
endfunction

" =open_result_window
function! s:open_result_window(command)
	let bufname = printf("[lein] %s", a:command)

	if !bufexists(bufname)
		execute g:lein_direction 'new'
		setlocal bufhidden=unload
		setlocal nobuflisted
		setlocal buftype=nofile
		setlocal noswapfile
		silent file `=bufname`
		nnoremap <buffer> <silent> q  <C-w>c
	else
		let bufnr = bufnr(bufname)  " FIXME: escape.
		let winnr = bufwinnr(bufnr)
		if winnr == -1
			execute g:quickrun_direction 'split'
			execute bufnr 'buffer'
		else
			execute winnr 'wincmd w'
		endif
	endif
endfunction

" =write_result_buffer
function! s:write_result_buffer(loading_message, command)
	silent % delete _
	call append(0, a:loading_message)
	redraw
	silent % delete _

	call s:system_lein(a:command, 1)
	execute printf(":edit %s", g:lein_temporary)
	"call delete(printf("%s", g:lein_temporary))
	call delete(g:lein_temporary)
endfunction

" =simple_lein_run
function! s:simple_lein_run(command)
	let path = <SID>get_project_dir()
	if path is 0
		echo g:lein_project_not_found
	else
		execute printf("cd %s", path)
		echo <SID>system_lein(a:command, 0)
		execute "cd -"
	endif
endfunction

" =system_lein
function! s:system_lein(command, output_flag)
	let cmd = g:lein_command . " " . a:command
	if a:output_flag
		let cmd = cmd . " > " . g:lein_temporary . " 2>&1"
	endif
	return system(cmd)
endfunction

" =LeinTest
function! LeinTest()
	let path = <SID>get_project_dir()
	if path is 0
		echo g:lein_project_not_found
	else
		execute printf("cd %s", path)
		call s:open_result_window("test")
		call s:write_result_buffer("starting test ...", "test")
		execute "cd -"
	endif
endfunction

" =PushToClojars
function! PushToClojars()
	let path = <SID>get_project_dir()

	if !(path is 0)
		let pom = <SID>reverse_find("pom.xml", path)
		let jar = <SID>reverse_find("*.jar", path)
	
		if pom is 0
			call s:simple_lein_run("pom")
		endif
	
		if jar is 0
			call s:simple_lein_run("jar")
			let jar = <SID>reverse_find("*.jar", path)
		endif
	
		if !(pom is 0 || jar is 0)
			execute printf("cd %s", path)
			execute "!" printf(g:clojars_command, fnamemodify(jar, ":t"))
			execute "cd -"
		endif
	endif
endfunction

command! LeinTest call LeinTest()
command! LeinPom call s:simple_lein_run("pom")
command! LeinJar call s:simple_lein_run("jar")
command! LeinDeps call s:simple_lein_run("deps")
command! LeinInstall call s:simple_lein_run("install")
command! LeinUberJar call s:simple_lein_run("uberjar")
command! LeinClean call s:simple_lein_run("clean")
command! LeinCompile call s:simple_lein_run("compile")
command! PushToClojars call PushToClojars()
