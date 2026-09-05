" --- プラグイン管理（vim-plug） ---

" vim-plug の自動インストール（curl が必要）
let s:plug_file = expand('~/.vim/autoload/plug.vim')
let s:bootstrap = 0
if !filereadable(s:plug_file)
  silent execute '!curl -fLo ' . s:plug_file . ' --create-dirs '
    \ . 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  let s:bootstrap = 1
endif

call plug#begin('~/.vim/plugged')

" --- 動作支援系 ---
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

" --- 視覚支援系 ---
Plug 'tomasr/molokai'
Plug 'itchyny/lightline.vim'
Plug 'Yggdroot/indentLine'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" --- 入力支援系 ---
Plug 'kentarosasaki/vim-emacs-bindings'
Plug 'tyru/caw.vim'

" --- LSP ---
Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

" --- EditorConfig ---
Plug 'editorconfig/editorconfig-vim'

call plug#end()

" 初回起動時はここで同期インストールを完了させてから vimrc を読み直す。
" これにより、後続の FileType / BufWinEnter などの autocmd が発火する時点で
" プラグインが揃っており、未導入由来のエラーが出ない。
if s:bootstrap
  PlugInstall --sync
  silent! close
  source $MYVIMRC
  finish
endif

set breakindent

" --- 基本設定 ---

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

" --- trailing whitespace のネイティブ実装 ---

augroup trailing_whitespace
  autocmd!
  autocmd BufWinEnter * match Error /\s\+$/
augroup END

" --- NERDTree ---

nnoremap sn gt
nnoremap sp gT
nnoremap sQ :<C-u>bd<CR>
nnoremap <silent><Leader>e :NERDTreeFocus<CR>
nnoremap <silent><Leader>q :NERDTreeClose<CR>

augroup nerdtree_auto
  autocmd!
  autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1
    \ && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
  autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree')
    \ && b:NERDTree.isTabTree() | quit | endif
  autocmd BufWinEnter * if getcmdwintype() == '' | silent NERDTreeMirror | endif
augroup END

" --- molokai ---

let g:molokai_original = 1
augroup colorschemeSetting
  autocmd!
  autocmd VimEnter * ++nested colorscheme molokai
  autocmd Colorscheme * highlight Normal      ctermbg=none
  autocmd Colorscheme * highlight NonText     ctermbg=none
  autocmd Colorscheme * highlight LineNr      ctermbg=none
  autocmd Colorscheme * highlight Folded      ctermbg=none
  autocmd Colorscheme * highlight EndOfBuffer ctermbg=none
augroup END

" --- indentLine ---

let g:indentLine_faster = 1
nmap <silent><Leader>i :<C-u>IndentLinesToggle<CR>

" --- caw.vim（コメントトグル） ---

nmap <Leader>c <Plug>(caw:hatpos:toggle)
vmap <Leader>c <Plug>(caw:hatpos:toggle)

" --- vim-lsp ---

" 各言語ファイルを開いて :LspInstallServer を実行
" サーバーは ~/.local/share/vim-lsp-settings/servers/ に隔離インストールされる

let g:lsp_diagnostics_echo_cursor  = 1
let g:lsp_diagnostics_float_cursor = 1

function! s:on_lsp_buffer_enabled() abort
  setlocal omnifunc=lsp#complete
  setlocal signcolumn=yes

  nmap <buffer> gd <Plug>(lsp-definition)
  nmap <buffer> gt <Plug>(lsp-type-definition)
  nmap <buffer> gi <Plug>(lsp-implementation)
  nmap <buffer> gr <Plug>(lsp-references)
  nmap <buffer> gy <Plug>(lsp-hover)
  nmap <buffer> g= <Plug>(lsp-document-format)
  nmap <buffer> gl <Plug>(lsp-document-diagnostics)
endfunction

augroup lsp_install
  autocmd!
  autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
  autocmd FileType * call s:notify_lsp_not_installed()
augroup END

let s:lsp_checked_ft = {}

function! s:notify_lsp_not_installed() abort
  let l:ft = &filetype
  if empty(l:ft) || has_key(s:lsp_checked_ft, l:ft) | return | endif
  let s:lsp_checked_ft[l:ft] = 1

  for l:conf in get(lsp_settings#settings(), l:ft, [])
    if !has_key(l:conf, 'command') | continue | endif
    if !isdirectory(lsp_settings#servers_dir() . '/' . l:conf.command)
      echohl WarningMsg
      echomsg '[LSP] ' . l:conf.command . ' is not installed. Run :LspInstallServer'
      echohl None
      return
    endif
  endfor
endfunction

" --- asyncomplete ---

inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR>    pumvisible() ? asyncomplete#close_popup() : "\<CR>"

" --- 言語別設定 ---

augroup fileTypeIndent
  autocmd!
  autocmd BufNewFile,BufRead *.tex setlocal tabstop=4 softtabstop=4 shiftwidth=4
  autocmd BufNewFile,BufRead *.go  setlocal tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
  autocmd BufNewFile,BufRead *.py  setlocal tabstop=4 softtabstop=4 shiftwidth=4
augroup END

augroup fileTypeExtensions
  autocmd!
  autocmd BufRead,BufNewFile,BufReadPre *.ts  set filetype=typescript
  autocmd BufRead,BufNewFile,BufReadPre *.tsx set filetype=typescriptreact
augroup END
