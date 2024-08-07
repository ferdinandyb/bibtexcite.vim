# BIBTEXCITE.VIM

A simple vim integration for [fzf-bibtex](https://github.com/msprev/fzf-bibtex)
and [bibtool](https://ctan.org/pkg/bibtool) for easy handling of bib(la)tex
citations.

## Features

The plugin is being developed to work well with
[Zotero](https://www.zotero.org/) as the citation manager, using the [Better
Biblatex](https://retorque.re/zotero-better-bibtex/) plugin to synchronize
a monolithic `.bib` file, but it should work with other workflows as well (also see tips below).

- insert citations in pandoc markdown, latex or
human-readable format using fzf
- fetch citation info in a popup window or echo it for further processing
- open pdf stored in citation with your favorite pdf reader
- insert citation directly from Zotero (slower than fzf method)


**Fetch info**
![fetch](fetch.png)

**Insert citation**
![insert](insert.png)

## INSTALLATION

For fetching citation info [bibtool](https://ctan.org/pkg/bibtool) is enough,
otherwise you need [fzf-bibtex](https://github.com/msprev/fzf-bibtex). Make
sure all the binaries (`bibtool`, `bibtex-ls,` `bibtex-cite,` `bibtex-markdown`
and `fzf)` are on your path.

Use your favorite plugin manager.

 - [vim-plug](https://github.com/junegunn/vim-plug)

  1. Add this to you .vimrc:
  ```
  Plug 'junegunn/fzf'
  Plug 'junegunn/fzf.vim'
  Plug 'ferdinandyb/bibtexcite.vim'
  ```

  2. Run `:PlugInstall`

Requires at least vim 8.2.0 (I don't know the minimal nvim version, and you'll
probably have a better experience on vim 9).

## USAGE

* `g:bibtexcite_bibfile`

  Type: |String| or |List| of Strings

  Can be either a string or a list of strings. Values will be used as paths to
  .bib files to be used. Buffer specific .bib files can also be set via
  `b:bibtexcite_bibfile`. This could be useful, although see |bibtexcite-tips| for using
  a monolithical .bib file and then gathering all the actually used entries
  into a new .bib.


* `:BibtexciteInsert {outputtype}`

  Open an fzf search window for citations and insert them in the
  appropriate format. Multiple citations can be selected. It takes an optional
  {outputtype} argument from the following:

      - pandoc: @citekey1; citekey2
      - latex: \cite{citekey1, citekey2}
      - markdown: insert a human-readable entry
                authors (year) 'title' *journal* pages

  Default output type is pandoc for markdown files, latex for tex files and
  markdown for everything else.


* `:BibtexciteShowcite[!] {citetype}`

  Fetch the citation info based on the citation key the cursor is on. The
  {citetype} is optional, which can either be "pandoc" or "latex". If the <cWORD>
  under the cursor is not a valid key for the citation type it will echo a message
  saying so. LaTeX citation keys are currently not matched if the cite command
  spans multiple lines. Using the command with the bang will try to use <cWORD> as
  key without any sanity checks.

  Default citetype is latex for tex files, and pandoc for everything else. For
  latex see also the |g:bibtexcite_latex_citecommands| setting.

* `:BibtexciteEchocite[!] {citetype}`

  Prints the bib entry, see tips for possible use case.

  See |BibtexciteShowcite| for bang and defaults.

* `:BibtexciteOpenfile[!] {citetype}`

  If the citation has a file key in it, it will attempt to open the file with
  whatever is configured in |g:bibtexcite_openfilecommand|.

  See |BibtexciteShowcite| for bang and defaults.

* `:BibtexciteZoteroInsert {citetype}`

  This command requires a running Zotero instance with the [Better Bibtex](https://retorque.re/zotero-better-bibtex/)
  plugin. It will open the Zotero citation selector for picking a citation. The `citetype`
  is the same as for `BibtexciteInsert`, except that the markdown format will use whatever
  citation export format is configured in Zotero. Using Zotero directly is considerably
  slower, than using the fzf method, but maybe useful for the more flexible markdown citation
  style.

  See |BibtexciteInsert| for defaults.

## Configuration

* `g:bibtexcite_latex_citecommands`
  Type: |List| of String
  Default: `['cite', 'bibentry']`

  Also works with buffer specific b:. Defines which latex commands are
  interpreted as a citation. The default will work with `\cite{key1, key2}` and
  `\bibentry{key1, key2}`.

* `g:bibtexcite_openfilecommand`
  Type: |String| or |List| of String
  Default: `"xdg-open"`

  Also works with buffer specific b:. Set the command to which file paths are
  passed when calling |BibtexciteOpenfile|. Defaults to `xdg-open`. If you want
  to pass additional command line arguments to your command, create a list with
  the parameters, e.g. `["command", "--argument", "argval"]`. The file paths
  will be passed after these.

* `g:bibtexcite_openfilesetting`

  Type: |Integer|
  Default: `3`

  Set how to behave when multiple files are present in the bibtex entry. Can also set buffer specific ones.
  - 1: Pass only first file as argument to `openfilecommand`.
  - 2: Pass all files as arguments.
  - 3: Open fzf selector asking for what files to open. If there's only one file, open without prompting. (default)

* `g:bibtexcite_floating_window_border`

  Type: |List|
  Default: `['|', '-', '+', '+', '+', '+']`

  When set to `[]`, window borders are disabled. The elements in the list set
  the horizontal, top, top-left, top-right, bottom-right and bottom-left
  border characters, respectively.

  If the terminal supports Unicode, you might try setting the value to
  ` ['│', '─', '╭', '╮', '╯', '╰']`, to make it look nicer.

  Taken from ALE.

* `g:bibtexcite_close_preview_on_insert`


  Type: |Number|
  Default: `0`

  When this option is set to `1`, bibtexcite's |preview-window| will be automatically
  closed upon entering Insert Mode.

  Taken from ALE.



## TIPS

Using one monolithical .bibfile managed by Zotero or Mendeley is the fastest way
to work, but you might need to include a .bib file for sharing later. In that
case, if you are working with latex the following will extract the entries from
the .aux file and place the in new.bib.

```sh
bibtool -x main.aux -o new.bib
```

If you are working with pandoc markdown the following will do the same:

```sh
grep -rPo "@\K[a-zA-Z0-9\-&_]+" *.md | xargs \
    -I{} bibtool -r biblatex -X {} monolithical.bib > new.bib
```

Using fzf to export some records from the bibfile to a new one:

 ```sh
 bibtex-ls ~/org/zotero.bib | fzf --multi | sed -nr 's/.+\b@([a-zA-Z0-9\-\&_])/\1/p' | ansi2txt | xargs  -I{} bibtool -r biblatex -X {} ~/org/zotero.bib
 ```

------------------------------------------------------------------------------
You can bind vim's default help key (K) to get the help if it exists, otherwise
show the citation info by putting this in your vimrc:

```vim
" Use K to show documentation in preview window.
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (len(bibtexcite#getcitekey("pandoc")) > 1)
    call bibtexcite#showcite("pandoc")
  elseif (len(bibtexcite#getcitekey("latex")) > 1)
    call bibtexcite#showcite("latex")
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction
```

This also falls back to Coc.nvim-s show documentation, so if you are not using
it remove the correspoding elseif.

This version of the function will first try to open the corresponding pdf and if
there is none, then show the pop-up with the citation info.
```vim
function! myfunctions#show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  elseif (len(bibtexcite#getfilepath("pandoc")) > 1)
    call bibtexcite#openfile("pandoc")
  elseif (len(bibtexcite#getfilepath("latex")) > 1)
    call bibtexcite#openfile("latex")
  elseif (len(bibtexcite#getcitekey("pandoc")) > 1)
    call bibtexcite#showcite("pandoc")
  elseif (len(bibtexcite#getcitekey("latex")) > 1)
    call bibtexcite#showcite("latex")
  elseif (coc#rpc#ready())
    call CocActionAsync('doHover')
  else
    execute '!' . &keywordprg . " " . expand('<cword>')
  endif
endfunction
```


------------------------------------------------------------------------------

If you want to use the abstract in a citation entry, you can either do something
like this over a citekey:
```vim
:put =bibtexcite#getcite('pandoc')
```

or using [vim-backscratch](https://github.com/hauleth/vim-backscratch) `:Scratch
BibtexciteEchocite` to put it on a scratch buffer.

Placing it in one of the registers (e.g. + for system clipboard) can done with

```vim
:let @+ = bibtexcite#getcite('pandoc')
```


---------------------------------------------------------------------------

Possible mappings:
```vim
autocmd FileType markdown  nnoremap <buffer> <silent> <leader>nc :BibtexciteInsert<CR>
autocmd FileType markdown  inoremap <buffer> <silent> @@ <Esc>:BibtexciteInsert<CR>
```

## Acknowledgments

The code for the popups was sourced from
[ALE](https://github.com/dense-analysis/ale), the code for the fzf chooser was
pretty much taken from the fzf-bibtex README.

## LICENSE

MIT

`autoload/bibtexcite/floating_preview.vim` is licensed separately in the file.
