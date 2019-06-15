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

set splitright 
set splitbelow

let s:dein_dir = expand('~/.vim/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if !isdirectory(s:dein_repo_dir)
  execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
endif

execute 'set runtimepath^=' . s:dein_repo_dir

call dein#begin(s:dein_dir)

call dein#add('Shougo/dein.vim')
call dein#add('Shougo/vimproc.vim', { 'build': 'make' })

call dein#add('kentarosasaki/vim-emacs-bindings')

call dein#add('thinca/vim-quickrun')
call dein#add('tyru/caw.vim')

call dein#add('Shougo/neocomplete.vim')
call dein#add('Shougo/neosnippet.vim')
call dein#add('Shougo/neosnippet-snippets')
call dein#add('w0rp/ale')

call dein#add('tomasr/molokai')
call dein#add('itchyny/lightline.vim')
call dein#add('Yggdroot/indentLine')
call dein#add('airblade/vim-gitgutter')

call dein#add('francoiscabrol/ranger.vim')
call dein#add('scrooloose/nerdtree')
call dein#add('Xuyuanp/nerdtree-git-plugin')

call dein#add('vim-scripts/fcitx.vim')
call dein#add('fuenor/im_control.vim')
call dein#add('tpope/vim-surround')
call dein#add('terryma/vim-multiple-cursors')

call dein#add('mattn/emmet-vim')
call dein#add('gko/vim-coloresque')

call dein#add('skanehira/translate.vim', { 'build': 'go get github.com/skanehira/gtran'})

call dein#add('othree/html5.vim')
call dein#add('hail2u/vim-css3-syntax')
call dein#add('pangloss/vim-javascript', { 'on_ft': ['javascript', 'javascript.jsx'] })
call dein#add('maxmellon/vim-jsx-pretty', { 'on_ft': ['javascript', 'javascript.jsx'] })

call dein#add('othree/yajs.vim', { 'on_ft': ['javascript', 'javascript.jsx'] })
call dein#add('othree/es.next.syntax.vim', { 'on_ft': ['javascript', 'javascript.jsx'] })
call dein#add('othree/javascript-libraries-syntax.vim', { 'on_ft': ['javascript', 'javascript.jsx'] })

call dein#add('prettier/vim-prettier', { 'build': 'yarn install' })
call dein#add('ternjs/tern_for_vim', { 'build': 'yarn install', 'on_ft': ['javascript', 'javascript.jsx'] })

call dein#add('leshill/vim-json', { 'on_ft': ['javascript', 'javascript.jsx', 'json'] })
call dein#add('heavenshell/vim-jsdoc', { 'on_ft': ['javascript', 'javascript.jsx', 'typescript'] })

call dein#add('fatih/vim-go', { 'on_ft': ['go'] })
call dein#add('nsf/gocode', { 'rtp': 'vim/' }) 
call dein#add('plasticboy/vim-markdown', { 'on_ft': 'markdown' })
call dein#add('kannokanno/previm', { 'on_ft': 'markdown' })
call dein#add('tyru/open-browser.vim', { 'on_ft': 'markdown' })

call dein#add('lervag/vimtex', { 'on_ft': ['tex', 'plaintex'] })

call dein#end()

if dein#check_install()
  call dein#install()
endif

colorscheme molokai
filetype plugin indent on
syntax on
highlight Normal ctermbg=none

augroup fileTypeIndent
  autocmd!
  autocmd BufNewFile,BufRead *.sh setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd BufNewFile,BufRead *.py setlocal tabstop=4 softtabstop=4 shiftwidth=4
  autocmd BufNewFile,BufRead *.rb setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd BufNewFile,BufRead *.js setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd BufNewFile,BufRead *.json setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd BufNewFile,BufRead *.tex setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd BufNewFile,BufRead *.html setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd BufNewFile,BufRead *.css setlocal tabstop=2 softtabstop=2 shiftwidth=2
augroup END

"----------------------------------------------------------
" neocomplete・neosnippetの設定
"----------------------------------------------------------
if dein#is_sourced('neocomplete.vim')
    " Vim起動時にneocompleteを有効にする
    let g:neocomplete#enable_at_startup = 1
    " smartcase有効化. 大文字が入力されるまで大文字小文字の区別を無視する
    let g:neocomplete#enable_smart_case = 1
    " 3文字以上の単語に対して補完を有効にする
    let g:neocomplete#min_keyword_length = 3
    " 区切り文字まで補完する
    let g:neocomplete#enable_auto_delimiter = 1
    " 1文字目の入力から補完のポップアップを表示
    let g:neocomplete#auto_completion_start_length = 1
    " バックスペースで補完のポップアップを閉じる
    inoremap <expr><BS> neocomplete#smart_close_popup()."<C-h>"

    " エンターキーで補完候補の確定. スニペットの展開もエンターキーで確定
    imap <expr><CR> neosnippet#expandable() ? "<Plug>(neosnippet_expand_or_jump)" : pumvisible() ? "<C-y>" : "<CR>"
    " タブキーで補完候補の選択. スニペット内のジャンプもタブキーでジャンプ
    imap <expr><TAB> pumvisible() ? "<C-n>" : neosnippet#jumpable() ? "<Plug>(neosnippet_expand_or_jump)" : "<TAB>"
endif

"----------------------------------------------------------
" Quickrun設定
"----------------------------------------------------------
let g:quickrun_config = {'_': {'hook/time/enable': '4', 'split': 'botright 8sp'}}
let g:quickrun_config = get(g:, 'quickrun_config', {})
let g:quickrun_config._ = {
      \ 'runner'    : 'vimproc',
      \ 'runner/vimproc/updatetime' : 60,
      \ 'outputter' : 'error',
      \ 'outputter/error/success' : 'buffer',
      \ 'outputter/error/error'   : 'quickfix',
      \ 'outputter/buffer/split'  : ':rightbelow 8sp',
      \ 'outputter/buffer/close_on_empty' : 1,
      \ }

au FileType qf nnoremap <silent><buffer>q :quit<CR>

"----------------------------------------------------------
" ALE設定
"----------------------------------------------------------

let g:ale_enabled = 1
let g:ale_fixers = {}
let g:ale_fixers['javascript'] = ['prettier-eslint']

" ファイルを開いたときにLintを実行する
let g:ale_lint_on_enter = 1
" let g:ale_lint_on_text_changed = 1

" 保存時にPrettierを実行する
let g:ale_fix_on_save = 1
let g:ale_javascript_prettier_use_local_config = 1

" ロケーションリストにエラーを表示する
let g:ale_set_loclist = 1
" QuickFixにエラーを表示する
let g:ale_set_quickfix = 0
let g:ale_open_list = 0

nmap <silent> <Space>p <Plug>(ale_previous_wrap)
nmap <silent> <Space>n <Plug>(ale_next_wrap)

"----------------------------------------------------------
"その他プラグイン設定
"----------------------------------------------------------

" Ternの設定
" 補完にパラメータを追加する
let g:tern_show_signature_in_pum = 1
" 補完の詳細情報を別ウィンドウで表示するかどうか（動くとは言ってない）
let g:tern_show_loc_after_rename = 0
let tern#is_show_argument_hints_enabled = 0
" 補完情報の更新頻度（'no', 'on_hold', 'on_move' and 'updatetime'）
let g:tern_show_argument_hints = 'no'

" コメントアウトの設定
nmap <Leader>c <Plug>(caw:hatpos:toggle)
vmap <Leader>c <Plug>(caw:hatpos:toggle)

" NERDTreeの設定
let NERDTreeShowHidden = 1
nnoremap <silent><Leader>e :NERDTreeToggle<CR>

" Translateの設定
noremap <silent><Leader>t :Translate<CR>

let g:vim_markdown_folding_disabled=1
let g:jsx_ext_required = 1
let IM_CtrlMode = 6
inoremap <silent> <C-l> <C-r>=IMState('FixMode')<CR>

