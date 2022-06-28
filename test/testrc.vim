set nocompatible
call plug#begin('~/.vim/plugged')

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'ferdinandyb/bibtexcite.vim'

call plug#end()

let g:bibtexcite_bibfile = ["test.bib", "test 2.bib"]
" let g:bibtexcite_bibfile = "test 2.bib"
let g:bibtexcite_floating_window_border = ['│', '─', '╭', '╮', '╯', '╰']
let g:bibtexcite_openfilecommand = 'zathura'
let g:bibtexcite_openfilesetting = 2
