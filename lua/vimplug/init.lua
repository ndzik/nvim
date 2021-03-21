local cmd = vim.cmd

local function use(plugin)
    cmd("Plug " .. plugin)
end

use([['benmills/vimux']])
use([['tpope/vim-surround']])
use([['shougo/vimproc.vim']])
use([['scrooloose/nerdtree']])
use([['shougo/vimshell.vim']])
use([['ryanoasis/vim-devicons']])
use([['mg979/vim-visual-multi']])
use([['vim-scripts/taglist.vim']])
use([['vim-scripts/sessionman.vim']])
use([['christoomey/vim-tmux-navigator']])
use([['ntpeters/vim-better-whitespace']])
use([['tmux-plugins/vim-tmux-focus-events']])

-- Plugins related to LSP support.
use([['neovim/nvim-lspconfig']])
use([['nvim-lua/completion-nvim']])

-- Plugins for the statusbar.
use([['vim-airline/vim-airline']])
use([['vim-airline/vim-airline-themes']])

-- Plugins for Haskell.
-- TODO: Get rid of this hoogle implementation and write a `Telescope` plugin
-- instead.
use([['junegunn/fzf', {'dir': '~/.fzf', 'do': './install --all'}]])
use([['monkoose/fzf-hoogle.vim']])
use([['neovimhaskell/haskell-vim']])
use([['ndmitchell/ghcid', { 'rtp': 'plugins/nvim' }]])

-- Plugins for Typescript.
use([['jparise/vim-graphql']])
use([['pangloss/vim-javascript']])
use([['leafgarland/typescript-vim']])
use([['peitalin/vim-jsx-typescript']])

-- Plugins for Rust.
use([['rust-lang/rust.vim']])

-- Plugins for Go.
use([['sebdah/vim-delve']])

-- Plugins for Git-related stuff.
use([['tpope/vim-fugitive']])
use([['airblade/vim-gitgutter']])

-- Plugins for Telescope.
use([['nvim-lua/popup.nvim']])
use([['nvim-lua/plenary.nvim']])
use([['nvim-telescope/telescope.nvim']])
use([['nvim-telescope/telescope-fzy-native.nvim']])

-- Plugins for Treesitter.
use([['nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }]])
use([['nvim-treesitter/playground']])
