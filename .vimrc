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

set splitright 
set splitbelow

let s:dein_dir = expand('~/.vim/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if !isdirectory(s:dein_repo_dir)
  execute '!git clone https://github.com:Shougo/dein.vim' s:dein_repo_dir
endif

execute 'set runtimepath^=' . s:dein_repo_dir

call dein#begin(s:dein_dir)

call dein#add('Shougo/dein.vim')
call dein#add('Shougo/vimproc.vim', {'build' : 'make'})

call dein#add('kentarosasaki/vim-emacs-bindings')

call dein#add('thinca/vim-quickrun')
call dein#add('tyru/caw.vim')

call dein#add('Shougo/neocomplete.vim')
call dein#add('Shougo/neosnippet.vim')
call dein#add('Shougo/neosnippet-snippets')

call dein#add('tomasr/molokai')
call dein#add('itchyny/lightline.vim')
call dein#add('Yggdroot/indentLine')
call dein#add('airblade/vim-gitgutter')

call dein#add('ctrlpvim/ctrlp.vim')
call dein#add('tacahiroy/ctrlp-funky')

call dein#add('vim-syntastic/syntastic')

call dein#add('francoiscabrol/ranger.vim')
call dein#add('scrooloose/nerdtree')
call dein#add('Xuyuanp/nerdtree-git-plugin')

call dein#add('vim-scripts/fcitx.vim')
call dein#add('fuenor/im_control.vim')
call dein#add('tpope/vim-surround')
call dein#add('terryma/vim-multiple-cursors')

call dein#add('mattn/emmet-vim')
call dein#add('gko/vim-coloresque')

call dein#add('othree/html5.vim')
call dein#add('hail2u/vim-css3-syntax')
call dein#add('pangloss/vim-javascript', { 'on_ft': ['javascript', 'javascript.jsx'] })
call dein#add('maxmellon/vim-jsx-pretty', { 'on_ft': ['javascript.jsx'] })

call dein#add('othree/yajs.vim', { 'on_ft': ['javascript', 'javascript.jsx'] })
call dein#add('othree/es.next.syntax.vim', { 'on_ft': ['javascript', 'javascript.jsx'] })
call dein#add('othree/javascript-libraries-syntax.vim', { 'on_ft': ['javascript', 'javascript.jsx'] })

call dein#add('leshill/vim-json', { 'on_ft': ['javascript', 'javascript.jsx', 'json']})

call dein#add('prettier/vim-prettier', {'build' : 'yarn install'})

call dein#add('fatih/vim-go', { 'on_ft': ['go'] })
call dein#add('nsf/gocode', {'rtp': 'vim/'}) 
call dein#add('plasticboy/vim-markdown', { 'on_ft': 'markdown' })
call dein#add('kannokanno/previm', { 'on_ft': 'markdown' })
call dein#add('tyru/open-browser.vim', { 'on_ft': 'markdown' })

call dein#end()

if dein#check_install()
  call dein#install()
endif

colorscheme molokai
syntax on
highlight Normal ctermbg=none
filetype plugin indent on

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
" CtrlPの設定
"----------------------------------------------------------
let g:ctrlp_match_window = 'order:ttb,min:20,max:20,results:100'
let g:ctrlp_show_hidden = 1
let g:ctrlp_types = ['buf', 'fil']
let g:ctrlp_extensions = ['funky'] 

" CtrlPCommandLineの有効化
command! CtrlPCommandLine call ctrlp#init(ctrlp#commandline#id())

" CtrlPFunkyの有効化
let g:ctrlp_funky_matchtype = 'path' 

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
" Syntasticの設定
"----------------------------------------------------------
" Normalモード時にCtrl+Cでシンタックスチェック
nnoremap <C-C> :w<CR>:SyntasticCheck<CR>
" 構文エラー行に「>>」を表示
let g:syntastic_enable_signs = 1
" 他のVimプラグインと競合するのを防ぐ
let g:syntastic_always_populate_loc_list = 1
" 構文エラーリストを非表示
let g:syntastic_auto_loc_list = 0
" ファイルを開いた時に構文エラーチェックを実行しない
let g:syntastic_check_on_open = 0
" 「:wq」で終了する時も構文エラーチェックしない
let g:syntastic_check_on_wq = 0

" Javascript用. 構文エラーチェックにESLintを使用
let g:syntastic_javascript_checkers=['eslint']
" Javascript以外は構文エラーチェックをしない
let g:syntastic_mode_map = { 'mode': 'passive',
                           \ 'active_filetypes': ['javascript'],
                           \ 'passive_filetypes': [] }

"----------------------------------------------------------
"その他プラグイン設定
"----------------------------------------------------------

let g:vim_markdown_folding_disabled=1
let g:jsx_ext_required = 1

let g:prettier#config#semi = 'false'
let g:prettier#config#bracket_spacing = 'true'

nmap <Leader>c <Plug>(caw:hatpos:toggle)
vmap <Leader>c <Plug>(caw:hatpos:toggle)

nnoremap <silent><Leader>e :NERDTreeToggle<CR>

let IM_CtrlMode = 6
inoremap <silent> <C-l> <C-r>=IMState('FixMode')<CR>

