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
if !exists('g:lein_show_message')
	let g:lein_show_message = 1
endif
" }}}

"" =reverse_find
"function! s:reverse_find(filename, path)
"	if fnamemodify(a:path, ':p:h') == '/'
"		let filelist = glob('/' . a:filename)
"		return (filelist == '') ? '' : filelist
"	else
"		let filelist = glob(a:path . '/' . a:filename)
"		if filelist == ''
"			return <SID>reverse_find(a:filename, '../' . a:path)
"		else
"			return filelist
"		endif
"	endif
"endfunction
"
"" =get_project_dir
"function! s:get_project_dir()
"	let project_file = <SID>reverse_find(g:lein_project, '.')
"	if project_file != ''
"		return fnamemodify(project_file, ":p:h")
"	else
"		return ''
"	endif
"endfunction

" =trim
function! s:trim(str)
	return substitute(a:str, '\(^\s\+\)\|\(\s\+$\)', '', 'g')
	"return res
endfunction

" =myecho
function! s:myecho(str)
	if g:lein_show_message == 1
		echo a:str
	endif
endfunction

" =get_clojure_namespace
function! s:get_clojure_namespace()
	return <SID>trim(substitute(getline(search('(ns ', 'bn')), '\((ns\|)\|"\)', '', 'g'))
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

" =toggle_compile_when_saved
function! s:toggle_compile_when_saved()
	if !exists('b:lein_compile_when_saved') || b:lein_compile_when_saved == 0
		let b:lein_compile_when_saved = 1
		call s:myecho('[ON] compile when saved')
	else
		let b:lein_compile_when_saved = 0
		call s:myecho('[OFF] compile when saved')
	endif
endfunction

" =print_clojure_namespace
function! s:print_clojure_namespace()
	call s:myecho(<SID>get_clojure_namespace())
endfunction

" =compile_this
function! s:compile_this()
	let ns = <SID>get_clojure_namespace()
	call s:system_lein('compile ' . ns)
endfunction

" =compile_when_save
function! s:compile_when_save()
	if exists('b:lein_compile_when_saved') && b:lein_compile_when_saved == 1
		call s:compile_this()
	endif
endfunction

" =system_lein
function! s:system_lein(command)
	let cmd = g:lein_command . ' ' . a:command
	call s:myecho("start " . a:command)
	let result = system(cmd)
	call s:myecho("finish " . a:command)
	return result
endfunction

" =LeinTest
function! LeinTest()
	call s:open_result_window('test')
	call s:write_result_buffer('starting test ...', 'test')
endfunction

function! LeinRun()

endfunction

function! LeinRun()
	let ns = <SID>get_clojure_namespace()
	let cmd = 'run -m ' . ns
	call s:open_result_window(cmd)
	call s:write_result_buffer('running ' . ns . ' ...', cmd)
endfunction

" =PushToClojars
function! PushToClojars()
	let path = <SID>get_project_dir()

	if path != ''
		let pom = glob(path . '/pom.xml')
		let jar = glob(path . '/*.jar')

		if pom == ''
			call s:system_lein('pom')
			let pom = glob(path . '/pom.xml')
		endif
	
		if jar == ''
			call s:system_lein('jar')
			let jar = glob(path . '/*.jar')
		endif
	
		if pom != '' && jar != ''
			execute printf('cd %s', path)
			execute '!' printf(g:clojars_command, fnamemodify(jar, ':t'))
			execute 'cd -'
		else
			call s:myecho('pom.xml or JAR is not found.')
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
		au FileType clojure nnoremap <Leader>lr :LeinRun<CR>
		au FIleType clojure nnoremap <Leader>lC :LeinCompileThis<CR>
		au FileType clojure nnoremap <Leader>ll :Lein 

		au FileType clojure inoremap <Leader>ns <C-R>=printf("%s", <SID>get_clojure_namespace())<CR>
		au FileType clojure cnoremap <Leader>ns <C-R>=printf("%s", <SID>get_clojure_namespace())<CR>
	endif
aug END
" }}}

" =commands {{{
aug LeinCommand
	au!
	au FileType clojure command! LeinTest call LeinTest()
	au FileType clojure command! LeinPom call s:system_lein('pom')
	au FileType clojure command! LeinJar call s:system_lein('jar')
	au FileType clojure command! LeinDeps call s:system_lein('deps')
	au FileType clojure command! LeinInstall call s:system_lein('install')
	au FileType clojure command! LeinUberJar call s:system_lein('uberjar')
	au FileType clojure command! LeinClean call s:system_lein('clean')
	au FileType clojure command! LeinCompile call s:system_lein('compile')
	au FileType clojure command! LeinCompileThis call s:compile_this()
	au FileType clojure command! LeinRun call LeinRun()

	au FileType clojure command! LeinNS call s:print_clojure_namespace()
	au FileType clojure command! LeinToggleAutoCompile call s:toggle_compile_when_saved()

	au FileType clojure command! PushToClojars call PushToClojars()
	au FileType clojure command! -nargs=+ Lein call s:system_lein(<q-args>)

	au BufWritePost *.clj call s:compile_when_save()
aug END
" }}}

