" https://github.com/amix/vimrc
" http://vim.spf13.com/
set nocompatible              " be iMproved, required
filetype off                  " required

syntax on
set hidden

"" https://github.com/chriskempson/base16-vim
let base16colorspace=256  " Access colors present in 256 colorspace
so ~/.vim/base16.vim
" status line
set laststatus=2
let g:airline_powerline_fonts=1

" Vundle is short for Vim bundle and is a Vim plugin manager.
"
" Vundle allows you to...
"
" keep track of and configure your plugins right in the .vimrc
" install configured plugins (a.k.a. scripts/bundle)
" update configured plugins
" search by name all available Vim scripts
" clean unused plugins up
" run the above actions in a single keypress with interactive mode
" Vundle automatically...
"
" manages the runtime path of your installed scripts
" regenerates help tags after installing and updating
" git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
"" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'vim-airline/vim-airline' " Lean & mean status/tabline for vim that's light as air.
Plugin 'vim-airline/vim-airline-themes'
"Plugin 'altercation/vim-colors-solarized'
"Plugin 'godlygeek/tabular' " align everything
Plugin 'LnL7/vim-nix'
Plugin 'vim-scripts/DirDiff.vim'
"" This plugin would NOT work if neither +python/+python3 nor EditorConfig core is available.
Plugin 'editorconfig/editorconfig-vim'
Plugin 'vim-pandoc/vim-pandoc'
"Plugin 'vim-pandoc/vim-pandoc-syntax'
"
"Plugin 'ledger/vim-ledger'
"
" Plugin 'ctrlpvim/ctrlp.vim'
" Plugin 'kalafut/vim-taskjuggler'
Plugin 'hashivim/vim-terraform.git'
Plugin 'edkolev/tmuxline.vim'
" Plugin 'guyzmo/notmuch-abook' " requires to be patched for nix
call vundle#end()            " required
filetype plugin indent on    " required
" vim +PluginInstall! +PluginClean!
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
" set background=light
"set background=dark
"set t_Co=256
"colorscheme solarized

"let g:ctrlp_map = '<c-p>'
"let g:ctrlp_cmd = 'CtrlP'

au BufWinLeave * silent! mkview
au BufWinEnter * silent! loadview

au BufWinEnter *.nix set ft=nix
" automatically rebalance windows on vim resize
autocmd VimResized * :wincmd =

let g:ctrlp_working_path_mode = 'ra'
" case insensitve search unless on letter capital
set ignorecase
set smartcase

"let g:airline#extensions#tmuxline#enabled = 0
" #H    Hostname of local host
" #h    Hostname of local host without the domain name
" #F    Current window flag
" #I    Current window index
" #S    Session name
" #W    Current window name
" #(shell-command)  First line of the command's output
"let g:tmuxline_preset = 'tmux'
"let g:tmuxline_preset = 'full'
"let g:tmuxline_preset = 'nightly_fox'
let g:tmuxline_preset = {
        \ 'a': '[#S]',
        \ 'win': '#I:#W#F',
        \ 'cwin': '#I:#W#F',
        \ 'x': '$wg_is_keys_off',
        \ 'y': [ '#(cat ~/.conky.out)', '%H:%M' ],
        \ 'z': '#H',
        \ 'options': {
        \'status-justify': 'left',
        \'status-position': 'top'}
        \}
"      \'a'    : '#S',
"      \'c'    : ['#(whoami)', '#(uptime | cut -d " " -f 1,2,3)'],
"      \'win'  : ['#I', '#W'],
"      \'cwin' : ['#I', '#W', '#F'],
"      \'x'    : '#(date)',
"      \'y'    : ['%R', '%a', '%Y'],
"      \'z'    : '#H'}
