" ~/.vimrc
"

" General

set nocompatible

set backspace=indent,eol,start

set history=200		" keep 200 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set wildmenu		" display completion matches in a status line

if !isdirectory($HOME."/.vim")
    call mkdir($HOME."/.vim", "", 0770)
endif

if !isdirectory($HOME."/.vim/.undo")
    call mkdir($HOME."/.vim/.undo", "", 0700)
endif
set undodir=~/.vim/.undo//
set undofile	" keep an undo file (undo changes after closing)

if !isdirectory($HOME."/.vim/.backup")
    call mkdir($HOME."/.vim/.backup", "", 0700)
endif
set backup		" keep a backup file (restore to previous version)
set backupdir=~/.vim/.backup//

if !isdirectory($HOME."/.vim/.swap")
    call mkdir($HOME."/.vim/.swap", "", 0700)
endif
set directory=~/.vim/.swap//

set ttimeoutlen=0	" wait up to 0ms after Esc for special key

filetype plugin indent on

" Use smartcase - search case insensitive when the searchterm contains no
" uppercase characters, case sensitive otherwise
" Add \C or \c to force case sensitive or -insensitive search
set ignorecase
set smartcase


" Aesthetics

" Allow using the mouse to position the cursor etc.
set mouse=a

" 5 lines of scrolloff
set scrolloff=5

" Show @@@ in the last line if it is truncated.
set display=truncate

set hlsearch
set incsearch

syntax on

" Enable hybrid line numbers
set relativenumber number

" Switch to absolute linenumbers when in insertmode
augroup numbertoggle
  autocmd!
  autocmd BufEnter,FocusGained,InsertLeave * set relativenumber
  autocmd Bufleave,FocusLost,InsertEnter * set norelativenumber
augroup END

augroup vimrcEx
  au!
  autocmd FileType text setlocal textwidth=78
augroup END

" The ! means the package won't be loaded right away but when plugins are
" loaded during initialization.
packadd! matchit

" Highlight long lines
augroup longlines
  autocmd!
  autocmd FileType python highlight LongLine ctermbg=red ctermfg=white
  autocmd FileType python match LongLine /\%89v.*/
augroup END

" Highlight trailing whitespace
" https://vim.fandom.com/wiki/Highlight_unwanted_spaces
augroup trailing_whitespace
  autocmd!
  autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
  " Show trailing whitespace and spaces before a tab:
  autocmd InsertLeave * match ExtraWhitespace /\s\+$\| \+\ze\t/
  " autocmd InsertLeave * match ExtraWhitespace /\s\+$/
augroup END
highlight ExtraWhitespace ctermbg=lightblue ctermfg=white

" Use 4 spaces for tabs in typescript
augroup typescript
  autocmd!
  autocmd FileType typescript,typescriptcommon,typescriptreact set expandtab shiftwidth=4 tabstop=4
augroup END


" Misc

augroup vimStartup
  au!

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid, when inside an event handler
  " (happens when dropping a file on gvim) and for a commit message (it's
  " likely a different one than last time).
  autocmd BufReadPost *
    \ if line("'\"") >= 1 && line("'\"") <= line("$") && &ft !~# 'commit'
    \ |   exe "normal! g`\""
    \ | endif

augroup END

" Commands

command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
		\ | wincmd p | diffthis


" Mappings

" Break undo so you can undo <C-U>
inoremap <C-U> <C-G>u<C-U>
