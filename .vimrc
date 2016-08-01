" https://github.com/amix/vimrc
" http://vim.spf13.com/
set nocompatible              " be iMproved, required
filetype off                  " required

syntax on

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
" let Vundle manage Vundle, required
Plugin 'VundleVim/Vundle.vim'
Plugin 'vim-airline/vim-airline' " Lean & mean status/tabline for vim that's light as air.
Plugin 'vim-airline/vim-airline-themes'
Plugin 'altercation/vim-colors-solarized'
Plugin 'godlygeek/tabular' " align everything
Plugin 'LnL7/vim-nix'

call vundle#end()            " required
filetype plugin indent on    " required
"
" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
"
" see :h vundle for more details or wiki for FAQ
" Put your non-Plugin stuff after this line
set background=dark
colorscheme solarized

" status line
set laststatus=2
let g:airline_powerline_fonts=1

au BufWinLeave * mkview
au BufWinEnter * silent! loadview

au BufWinEnter *.nix set ft=nix
