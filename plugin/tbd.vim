if !has("nvim-0.5") || exists("g:loaded_tbd")
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=? -complete=file Tbd call tbd#edit(<f-args>)

function! tbd#edit(...)
	let l:file = get(a:, 1, "")
	if (l:file != "")
		execute "edit" l:file
	endif

	lua require("tbd").start()
endfunc

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tbd = 1
