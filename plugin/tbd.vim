if !has("nvim-0.5") || exists("g:loaded_tbd")
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! Tbd lua require("tbd").start()

let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_tbd = 1
