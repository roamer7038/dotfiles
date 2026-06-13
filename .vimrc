"----------------------------------------------------------
" プラグイン管理（vim-plug）
"----------------------------------------------------------

" vim-plug の自動インストール（curl が必要）
let s:plug_file = expand('~/.vim/autoload/plug.vim')
if !filereadable(s:plug_file)
  silent execute '!curl -fLo ' . s:plug_file . ' --create-dirs '
    \ . 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

"--- 動作支援系 ---
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

"--- 視覚支援系 ---
Plug 'tomasr/molokai'
Plug 'itchyny/lightline.vim'
Plug 'Yggdroot/indentLine'
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

"--- 入力支援系 ---
Plug 'kentarosasaki/vim-emacs-bindings'
Plug 'tyru/caw.vim'

"--- 言語支援系 ---
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
Plug 'thinca/vim-quickrun'
Plug 'mattn/emmet-vim'
Plug 'fatih/vim-go',           { 'for': 'go' }
Plug 'hashivim/vim-terraform', { 'for': ['terraform', 'hcl'] }
Plug 'cespare/vim-toml',       { 'for': 'toml' }
Plug 'elzr/vim-json',          { 'for': 'json' }
Plug 'kannokanno/previm',      { 'for': 'markdown' }
Plug 'tyru/open-browser.vim',  { 'for': 'markdown' }

"--- EditorConfig ---
Plug 'editorconfig/editorconfig-vim'

call plug#end()

set breakindent

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
" trailing whitespace のネイティブ実装
"----------------------------------------------------------

augroup trailing_whitespace
  autocmd!
  autocmd BufWinEnter * match Error /\s\+$/
augroup END

"----------------------------------------------------------
" NERDTree
"----------------------------------------------------------

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

"----------------------------------------------------------
" molokai
"----------------------------------------------------------

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

"----------------------------------------------------------
" indentLine
"----------------------------------------------------------

let g:indentLine_faster = 1
nmap <silent><Leader>i :<C-u>IndentLinesToggle<CR>

"----------------------------------------------------------
" caw.vim（コメントトグル）
"----------------------------------------------------------

nmap <Leader>c <Plug>(caw:hatpos:toggle)
vmap <Leader>c <Plug>(caw:hatpos:toggle)

"----------------------------------------------------------
" coc.nvim
"----------------------------------------------------------

let g:coc_disable_startup_warning = 1

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <silent><expr> <TAB>
  \ coc#pum#visible() ? coc#pum#next(1):
  \ <SID>check_back_space() ? "\<Tab>" :
  \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<S-TAB>"
inoremap <silent><expr> <c-space> coc#refresh()

nmap <silent> gl :<C-u>CocList<cr>
nmap <silent> gy :<C-u>call CocAction('doHover')<cr>
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gt <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> g= <Plug>(coc-format)

"----------------------------------------------------------
" vim-quickrun
"----------------------------------------------------------

let g:quickrun_config = get(g:, 'quickrun_config', {})
let g:quickrun_config._ = {
  \ 'runner' : 'job',
  \ 'runner/job/updatetime' : 60,
  \ 'outputter' : 'buffer',
  \ 'outputter/buffer/opener': 'new',
  \ 'outputter/buffer/into': 1,
  \ 'outputter/buffer/close_on_empty': 1,
  \ }
nnoremap <leader>r :QuickRun<CR>

"----------------------------------------------------------
" vim-go
"----------------------------------------------------------

let g:go_def_mapping_enabled = 0
let g:go_fmt_autosave        = 1
let g:go_fmt_command         = "goimports"

"----------------------------------------------------------
" vim-json
"----------------------------------------------------------

let g:vim_json_syntax_conceal = 0

"----------------------------------------------------------
" previm（Markdown プレビュー）
"----------------------------------------------------------

let g:previm_wsl_mode = 1

"----------------------------------------------------------
" 言語別設定
"----------------------------------------------------------

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

"----------------------------------------------------------
" coc.nvim 初回セットアップ
"----------------------------------------------------------

" :CocInstall coc-lists coc-prettier coc-eslint coc-markdownlint
"             coc-sh coc-highlight coc-yaml coc-html coc-json
"             coc-css coc-tsserver coc-pyright
"
" npm install -g bash-language-server
" npm install -g dockerfile-language-server-nodejs
"
" Go LSP:  go install golang.org/x/tools/gopls@latest
" C++ LSP: :CocInstall coc-clangd && :CocCommand clangd.install
