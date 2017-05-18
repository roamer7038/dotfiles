set number
set title
set expandtab
set laststatus=2
set tabstop=4
set autoindent
set shiftwidth=4
set smartindent
set hidden
set t_Co=256

let s:dein_dir = expand('~/.vim/dein')
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

if !isdirectory(s:dein_repo_dir)
  execute '!git clone git@github.com:Shougo/dein.vim.git' s:dein_repo_dir
endif

execute 'set runtimepath^=' . s:dein_repo_dir

call dein#begin(s:dein_dir)

call dein#add('Shougo/dein.vim')
call dein#add('Shougo/neocomplete.vim')
call dein#add('Shougo/neosnippet.vim')
call dein#add('Shougo/neosnippet-snippets')
call dein#add('francoiscabrol/ranger.vim')
call dein#add('tomasr/molokai')
call dein#add('thinca/vim-visualstar')
call dein#add('vim-syntastic/syntastic')
call dein#add('itchyny/lightline.vim')
call dein#add('tyru/caw.vim')
call dein#add('scrooloose/nerdtree')
call dein#add('Xuyuanp/nerdtree-git-plugin')
call dein#add('airblade/vim-gitgutter')
call dein#add('tyru/open-browser.vim')
call dein#add('Townk/vim-autoclose')
call dein#add('thinca/vim-quickrun')

call dein#add('othree/html5.vim', { 'on_ft': 'html' })
call dein#add('mattn/emmet-vim', { 'on_ft': ['html', 'css'] })
call dein#add('hail2u/vim-css3-syntax', { 'on_ft': 'css' })
call dein#add('jelera/vim-javascript-syntax', { 'on_ft': 'javascript' })
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

set splitright 
set splitbelow
let g:quickrun_config = {'_': {'hook/time/enable': '1', 'split': 'botright 12sp'}}

nmap <Leader>c <Plug>(caw:i:toggle)
vmap <Leader>c <Plug>(caw:i:toggle)
nnoremap <silent><Leader>e :NERDTreeToggle<CR>

