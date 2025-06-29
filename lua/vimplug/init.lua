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
use([['jaredgorski/fogbell.vim']])
use([['tikhomirov/vim-glsl']])
use([['rktjmp/lush.nvim']])
use([['ndzik/mustard']])

-- Plugins related to DSP support.
use([['puremourning/vimspector']])

-- Plugins related to LSP support.
use([['neovim/nvim-lspconfig']])
use([['folke/neodev.nvim']])
use([['stevearc/conform.nvim']])

-- Plugins for completion
use([['hrsh7th/cmp-nvim-lsp']])
use([['hrsh7th/cmp-buffer']])
use([['hrsh7th/cmp-path']])
use([['hrsh7th/cmp-cmdline']])
use([['saadparwaiz1/cmp_luasnip']])
use([['L3MON4D3/LuaSnip']])
use([['hrsh7th/nvim-cmp']])

-- Plugins for Haskell.
use([['junegunn/fzf', {'dir': '~/.fzf', 'do': './install --all'}]])
use([['neovimhaskell/haskell-vim']])

-- PLugins for Purescript.
use([['purescript-contrib/purescript-vim']])

-- Plugins for Typescript.
use([['jparise/vim-graphql']])
use([['pangloss/vim-javascript']])
use([['leafgarland/typescript-vim']])
use([['peitalin/vim-jsx-typescript']])

-- Plugins for Svelte.
use([['evanleck/vim-svelte']])

-- Plugins for Rust.
use([['rust-lang/rust.vim']])

-- Plugins for Go.
use([['sebdah/vim-delve']])

-- Plugins for Git-related stuff.
use([['tpope/vim-fugitive']])
use([['kyazdani42/nvim-web-devicons']])

-- Plugins for Telescope.
use([['nvim-lua/popup.nvim']])
use([['nvim-lua/plenary.nvim']])
use([['nvim-telescope/telescope.nvim']])
use([['nvim-telescope/telescope-fzy-native.nvim']])
use([['nvim-telescope/telescope-file-browser.nvim']])

-- Plugins for Treesitter.
use([['nvim-treesitter/nvim-treesitter', { 'do': ':TSUpdate' }]])
use([['nvim-treesitter/playground']])

-- Plugins for code 10x'ing.
use([['github/copilot.vim']])

-- Plugins for movement
use([['ggandor/leap.nvim']])

-- Plugins for formatting.
use([['tpope/vim-sleuth']])
use([['dhruvasagar/vim-table-mode']])
