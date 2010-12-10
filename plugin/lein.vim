" Vim Plugin for Leiningen
" Author  : Masashi Iizuka
" License : The MIT License
" URL     : http://github.com/liquidz/lein-vim

" =global options {{{
if !exists('g:lein_command')
    let g:lein_command = 'lein'
endif
if !exists('g:lein_project')
	let g:lein_project = 'project.clj'
endif
if !exists('g:lein_direction')
	let g:lein_direction = 'rightbelow'
endif
if !exists('g:clojars_command')
	let g:clojars_command = 'scp pom.xml %s clojars@clojars.org:'
endif
if !exists('g:lein_project_not_found')
	let g:lein_project_not_found = g:lein_project . ' is not found.'
endif
" }}}

" =reverse_find
function! s:reverse_find(filename, path)
	if fnamemodify(a:path, ':p:h') == '/'
		let filelist = glob('/' . a:filename)
		return (filelist == '') ? '' : filelist
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
	let project_file = <SID>reverse_find(g:lein_project, '.')
	if project_file != ''
		return fnamemodify(project_file, ":p:h")
	else
		return ''
	endif
endfunction

function! s:trim(str)
	let res = substitute(a:str, '\(^\s\+\)\|\(\s\+$\)', '', 'g')
	"echo 'res = ' . res
	return res
endfunction

function! s:update_clojure_namespace()
	let b:clojure_ns =  <SID>trim(substitute(getline(search('(ns', 'bn')), '\((ns\|)\)', '', 'g'))
endfunction

"(ns hello
")

function! s:get_clojure_namespace()
	echo <SID>trim(substitute(getline(search('(ns', 'bn')), '\((ns\|)\|"\)', '', 'g'))
endfunction

" =open_result_window
function! s:open_result_window(command)
	let bufname = printf('[lein] %s', a:command)

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
	call append(0, '')
	execute printf('silent! read !%s %s', g:lein_command, a:command)
	silent 1 delete _
endfunction

" =simple_lein_run
function! s:simple_lein_run(command)
	let path = <SID>get_project_dir()
	if path != ''
		execute printf('cd %s', path)
		echo <SID>system_lein(a:command)
		execute 'cd -'
		echo 'fin'
	else
		echo g:lein_project_not_found
	endif
endfunction

" =system_lein
function! s:system_lein(command)
	let cmd = g:lein_command . ' ' . a:command
	return system(cmd)
endfunction

" =LeinTest
function! LeinTest()
	let path = <SID>get_project_dir()
	if path != ''
		execute printf('cd %s', path)
		call s:open_result_window('test')
		call s:write_result_buffer('starting test ...', 'test')
		execute 'cd -'
	else
		echo g:lein_project_not_found
	endif
endfunction

" =PushToClojars
function! PushToClojars()
	let path = <SID>get_project_dir()

	if path != ''
		let pom = glob(path . '/pom.xml')
		let jar = glob(path . '/*.jar')

		if pom == ''
			call s:simple_lein_run('pom')
			let pom = glob(path . '/pom.xml')
		endif
	
		if jar == ''
			call s:simple_lein_run('jar')
			let jar = glob(path . '/*.jar')
		endif
	
		if pom != '' && jar != ''
			execute printf('cd %s', path)
			execute '!' printf(g:clojars_command, fnamemodify(jar, ':t'))
			execute 'cd -'
		else
			echo 'pom.xml or JAR is not found.'
		endif
	endif
endfunction

" =key mappings {{{
aug LeinKeymap
	if !exists('g:lein_no_map_default') || !g:lein_no_map_default
		au!
		au FileType clojure nnoremap <Leader>lt :LeinTest<CR>
		au FileType clojure nnoremap <Leader>lj :LeinJar<CR>
		au FileType clojure nnoremap <Leader>lm :LeinPom<CR>
		au FileType clojure nnoremap <Leader>ld :LeinDeps<CR>
		au FileType clojure nnoremap <Leader>li :LeinInstall<CR>
		au FileType clojure nnoremap <Leader>lu :LeinUberJar<CR>
		au FileType clojure nnoremap <Leader>lc :LeinCompile<CR>
		au FileType clojure nnoremap <Leader>lp :PushToClojars<CR>
		au FileType clojure nnoremap <Leader>ll :Lein 
	
"		cnoremap <silent> <Leader>ns expand('b:clojure_ns')<CR>
"		nnoremap <Leader>ns :call echo s:get_clojure_namespace
	endif
aug END
" }}}

" =commands {{{
aug LeinCommand
	au!
	au FileType clojure command! LeinTest call LeinTest()
	au FileType clojure command! LeinPom call s:simple_lein_run('pom')
	au FileType clojure command! LeinJar call s:simple_lein_run('jar')
	au FileType clojure command! LeinDeps call s:simple_lein_run('deps')
	au FileType clojure command! LeinInstall call s:simple_lein_run('install')
	au FileType clojure command! LeinUberJar call s:simple_lein_run('uberjar')
	au FileType clojure command! LeinClean call s:simple_lein_run('clean')
	au FileType clojure command! LeinCompile call s:simple_lein_run('compile')
	au FileType clojure command! PushToClojars call PushToClojars()
	au FileType clojure command! -nargs=+ Lein call s:simple_lein_run(<q-args>)

"	au FileType clojure command! UpdateClojureNS call s:update_clojure_namespace()
aug END

cnoremap <Leader>ns call s:get_clojure_namespace()
command! LeinNS call s:get_clojure_namespace()

" }}}
