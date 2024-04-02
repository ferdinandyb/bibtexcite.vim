" Copyright (c) 2022 Bence Ferdinandy
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

let s:cpo_save = &cpo
set cpo&vim

function! bibtexcite#pandoc_sink(lines)
    let r=system("bibtex-cite --mode=pandoc", a:lines)
    execute ':normal! a' . r
endfunction

function! bibtexcite#latex_sink(lines)
    let r=system("bibtex-cite --mode=latex", a:lines)
    execute ':normal! a' . r
endfunction

function! bibtexcite#markdown_sink(lines)
    let l:bibtexcite_bibfile = bibtexcite#get_bibfile()
    let r=system("bibtex-markdown " . l:bibtexcite_bibfile . " ", a:lines )
    execute ':normal! a' . r
endfunction

function! bibtexcite#get_bibfile()
    let l:bibtexcite_bibfile_user = deepcopy(get(b:, 'bibtexcite_bibfile',g:bibtexcite_bibfile))
    if type(l:bibtexcite_bibfile_user) == v:t_list
        let l:bibtexcite_bibfile = join(map(l:bibtexcite_bibfile_user, 'fnameescape(v:val)'))
    else
        let l:bibtexcite_bibfile = fnameescape(l:bibtexcite_bibfile_user)
    endif
    return l:bibtexcite_bibfile
endfunction

function! bibtexcite#fzf(citetype = "pandoc", bang = 0)
    let l:bibtexcite_bibfile = bibtexcite#get_bibfile()
    if trim(a:citetype) ==? "pandoc" || trim(a:citetype) ==? "" || trim(a:citetype) ==? "p"
        let sink = 'bibtexcite#pandoc_sink'
        let prompt = '"Cite pandoc>"'
    elseif trim(a:citetype) ==? "latex" || trim(a:citetype) ==? "l"
        let sink = 'bibtexcite#latex_sink'
        let prompt = '"Cite latex>"'
    elseif trim(a:citetype) ==? "markdown" || trim(a:citetype) ==? "m"
        let sink = 'bibtexcite#markdown_sink'
        let prompt = '"Cite markdown>"'
    else
        throw "Bad citation type, possible values are: p[andoc], l[atex], m[arkdown]."
    endif

    call fzf#run(fzf#wrap({
        \ 'source': 'bibtex-ls ' . l:bibtexcite_bibfile,
        \ 'sink*': function(sink),
        \ 'up': '40%',
        \ 'options': '--ansi --layout=reverse-list --multi --prompt '. prompt},
        \ a:bang))
endfunction

function! bibtexcite#getcitekey(citetype = "pandoc", bang = 0)
    if a:bang
        let word = expand("<cWORD>")
        return word
    endif
    if trim(a:citetype )==? "pandoc" || trim(a:citetype) ==? "" || trim(a:citetype) ==? "p"
        let word = expand("<cWORD>")
        let regex = '@\<\([a-zA-Z0-9\-&_]\+\)\>;\?'
        if word =~ regex
            let word = substitute(word, regex, '\1', '')
            let word = substitute(word, ';','','')
            let word = substitute(word, ',','','')
            let word = substitute(word, '\.','','')
            return word
        else
            return 0
        endif
    elseif trim(a:citetype) ==? "latex" ||  trim(a:citetype) ==? "l"
        let line=getline('.')
        if line =~ '\\cite{[a-zA-Z0-9\-&_, ]\+}'
            let word = expand("<cWORD>")
            let regex = '@\<\([a-zA-Z0-9\-&_]\+\)\>,\?'
            let word = substitute(word, regex, '\1', '')
            let word = substitute(word, '\\cite{','','')
            let word = substitute(word, ',','','')
            let word = substitute(word, '}','','')
            return word
        else
            return 0
        endif
    else
        throw "Bad citation type, possible values are: p[andoc], l[atex]."
        return 0
    endif
endfunction

function! bibtexcite#getcite(citetype = "pandoc", bang = 0, extra_flags = "")
    let citekey = bibtexcite#getcitekey(a:citetype, a:bang)
    if len(citekey) == 1
        return 0
    endif
    let l:bibtexcite_bibfile = bibtexcite#get_bibfile()
    let l:command = "bibtool -r biblatex -X " . citekey . " " . l:bibtexcite_bibfile
    if len(a:extra_flags) > 0
        let l:command = l:command . " " . a:extra_flags
    endif
    let bib = system(l:command)
    if len(bib) == 0
        echo "no citation found"
        return 0
    endif
    if has('nvim')
        return join(split(bib,"\t"), "  ")
    endif
    return bib
endfunction

function! bibtexcite#showcite(citetype = "pandoc", bang = 0)
    let bib = bibtexcite#getcite(a:citetype, a:bang)
    if len(bib) > 1
        call bibtexcite#floating_preview#Show(split(bib,'\n'))
    endif
endfunction

function! bibtexcite#echocite(citetype = "pandoc", bang = 0)
    let bib = bibtexcite#getcite(a:citetype, a:bang)
    if len(bib) == 1
        echo ""
    else
        echo bib
    endif
endfunction

function! bibtexcite#getfilepath(citetype = "pandoc", bang = 0)
    let bib = bibtexcite#getcite(a:citetype, a:bang, "-- print.line.length=99999 -- keep.field{file}")
    let l:filepath = matchlist(bib, '[fF]ile\s\+=\s\+{\(.\{-}\)}')
    if len(l:filepath) > 1
        return l:filepath[1]
    else
        return ""
endfunction

function! bibtexcite#jobstart(filelist)
    let l:openfilecommand = get(b:, 'bibtexcite_openfilecommand',g:bibtexcite_openfilecommand)
    if type(l:openfilecommand) == v:t_list
        let l:job = l:openfilecommand
    else
        let l:job = [l:openfilecommand]
    endif
    let l:job = l:job + a:filelist
    if has('nvim')
        let l:jobobj = jobstart(l:job)
    else
        let l:jobobj = job_start(l:job)
    endif
endfunction

function! bibtexcite#openfile(citetype = "pandoc", bang = 0)
    let l:filepath = bibtexcite#getfilepath(a:citetype, a:bang)
    let l:openfilesetting = get(g:, 'bibtexcite_openfilesetting', 3)
    if len(l:filepath) > 1
        let l:filelist = split(l:filepath, ";")

        " if there's just one file, open it
        if len(l:filelist) == 1
            call bibtexcite#jobstart(l:filelist)
            return
        endif

        " decide what to do if have multiple files
        if l:openfilesetting == 1
            call bibtexcite#jobstart(l:filelist[0:0])
        elseif l:openfilesetting == 2
            call bibtexcite#jobstart(l:filelist)
        else
            call fzf#run(fzf#wrap({
                \ 'source': l:filelist,
                \ 'sink*': function('bibtexcite#jobstart'),
                \ 'options': '--multi --prompt "Choose files to open"'},
                \ a:bang))
        endif
    else
        echoerr "no file"
    endif

endfunction


function! bibtexcite#zoterocite(citetype = "pandoc", bang = 0)
  " pick a format based on the filetype (customize at will)
  " https://retorque.re/zotero-better-bibtex/citing/cayw/index.html#vim
  if a:citetype ==? "markdown"
      let format = "formatted-citation"
  else
      let format = a:citetype
  endif

  let api_call = 'http://127.0.0.1:23119/better-bibtex/cayw?format='.format
  let ref = system('curl -s '.shellescape(api_call))
  execute ':normal! a' . ref

endfunction

function! bibtexcite#complete_citetype_output(ArgLead, CmdLine, CursorPos)
    let l:retval = ['pandoc', 'latex', 'markdown']
    let l:match = '^' . a:ArgLead
    return filter(l:retval, 'v:val =~ l:match')
endfunction

function! bibtexcite#complete_citetype_parsing(ArgLead, CmdLine, CursorPos)
    let l:retval = ['pandoc', 'latex']
    let l:match = '^' . a:ArgLead
    return filter(l:retval, 'v:val =~ l:match')
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save
