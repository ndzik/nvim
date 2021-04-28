vim.g.mapleader = ' '

local fn = vim.fn
local execute = vim.api.nvim_command
local call = vim.call

local install_path = fn.stdpath("data").."/site/autoload/plug.vim"
if fn.empty(fn.glob(install_path)) > 0 then
	execute([[
	curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim \
	--create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	]])
end

-- Pull, register and update all dependencies with `vim-plug`.
call("plug#begin")
require("vimplug")
call("plug#end")

-- Load various plugin configurations made in lua.
require("plugins")

-- Load custom configuration for keymaps and miscellaneous stuff.
require("settings")
require("keymap")
