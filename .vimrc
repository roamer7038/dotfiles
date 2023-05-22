"----------------------------------------------------------
" プラグイン管理（Vim8以降に依存する）
"----------------------------------------------------------

if v:version >= 800 && executable('make') && executable('npm')
  let s:dein_dir = expand('~/.vim/dein')
  let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif

  execute 'set runtimepath^=' . s:dein_repo_dir

  if dein#load_state(s:dein_dir)
    call dein#begin(s:dein_dir)

    call dein#load_toml('~/.vim/dein.toml')

    call dein#end()
    call dein#save_state()
  endif

  if dein#check_install()
    call dein#install()
  endif

  set breakindent
else
  colorscheme slate
endif

"----------------------------------------------------------
" 基本設定
"----------------------------------------------------------

set encoding=utf-8
scriptencoding utf-8

set fileencoding=utf-8
set fileencodings=utf-8,iso-2022-jp,ucs-boms,utf-8,euc-jp,sjis,cp932
set fileformats=unix,dos,mac
set ambiwidth=double 

set tabstop=2 
set expandtab
set autoindent 
set smartindent
set shiftwidth=2

set showmatch
set hlsearch
set incsearch
nmap <Esc><Esc> :nohlsearch<CR><Esc>

set number
set ruler
set title
set hidden
set backupcopy=yes
set clipboard=unnamedplus
set cursorline
set wildmenu
set laststatus=2
set t_Co=256
set history=5000
set scrolloff=5
set nofoldenable

set splitright 
set splitbelow

filetype plugin indent on
syntax on
highlight Normal ctermbg=none

"----------------------------------------------------------
" 言語別設定
"----------------------------------------------------------

augroup fileTypeIndent
  autocmd!
  autocmd BufNewFile,BufRead *.sh setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd BufNewFile,BufRead *.rb setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd BufNewFile,BufRead *.go setlocal tabstop=4 softtabstop=4 shiftwidth=4
  autocmd BufNewFile,BufRead *.py setlocal tabstop=4 softtabstop=4 shiftwidth=4
  autocmd BufNewFile,BufRead *.js setlocal tabstop=4 softtabstop=4 shiftwidth=4
  autocmd BufNewFile,BufRead *.ts setlocal tabstop=4 softtabstop=4 shiftwidth=4
  autocmd BufNewFile,BufRead *.json setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd BufNewFile,BufRead *.tex setlocal tabstop=4 softtabstop=4 shiftwidth=4
  autocmd BufNewFile,BufRead *.html setlocal tabstop=4 softtabstop=4 shiftwidth=4
  autocmd BufNewFile,BufRead *.css setlocal tabstop=4 softtabstop=4 shiftwidth=4
augroup END

augroup fileTypeExtensions
  autocmd BufRead,BufNewFile,BufReadPre *.ts set filetype=typescript
  autocmd BufRead,BufNewFile,BufReadPre *.tsx set filetype=typescriptreact
augroup END

augroup closeTags
  autocmd!
  autocmd Filetype xml inoremap <buffer> </ </<C-x><C-o>
  autocmd Filetype html inoremap <buffer> </ </<C-x><C-o>
augroup END

au BufNewFile,BufRead *.toml setf toml

