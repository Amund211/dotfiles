" ~/.vimrc
"

" General

set nocompatible

set backspace=indent,eol,start

set history=200		" keep 200 lines of command line history
set ruler		" show the cursor position all the time
set showcmd		" display incomplete commands
set wildmenu		" display completion matches in a status line

set backup		" keep a backup file (restore to previous version)
set undofile	" keep an undo file (undo changes after closing)


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

