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

-- Plugins for colorschemes.
use([['nikolvs/vim-sunbather']])
use([['lokaltog/vim-monotone']])
use([['andreasvc/vim-256noir']])

-- Plugins related to DSP support.
use([['puremourning/vimspector']])

-- Plugins related to LSP support.
use([['neovim/nvim-lspconfig']])
use([['nvim-lua/completion-nvim']])

-- Plugins for Haskell.
use([['ndzik/telescope_hoogle', { 'branch': 'add_browser_config' }]])

-- PLugins for Purescript.
use([['purescript-contrib/purescript-vim']])

-- Plugins for Typescript.
use([['jparise/vim-graphql']])
use([['pangloss/vim-javascript']])
use([['leafgarland/typescript-vim']])
use([['peitalin/vim-jsx-typescript']])
-- TODO: Periodically check whether or not a better language server
-- implementation for JS/TS is available, which already integrates with a
-- formatting provider.
use([['mhartington/formatter.nvim']])

-- Plugins for Rust.
use([['rust-lang/rust.vim']])

-- Plugins for Go.
use([['sebdah/vim-delve']])

-- Plugins for Git-related stuff.
use([['tpope/vim-fugitive']])
use([['theprimeagen/git-worktree.nvim']])

-- Plugins for Telescope.
use([['nvim-lua/popup.nvim']])
use([['nvim-lua/plenary.nvim']])
use([['nvim-telescope/telescope.nvim']])
use([['nvim-telescope/telescope-fzy-native.nvim']])

-- Plugins for Treesitter.
use([['nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }]])
use([['nvim-treesitter/playground']])
