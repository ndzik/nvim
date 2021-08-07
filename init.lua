vim.g.mapleader = ' '

local loader = require("loader")

local fn = vim.fn
local call = vim.call

loader.isNotInstalled = function()
  local install_path = fn.stdpath("data").."/site/autoload/plug.vim"
  return fn.empty(fn.glob(install_path)) > 0
end

loader.doInstall = function()
  os.execute([[
  curl -fLo "${HOME}/.local/share/nvim/site/autoload/plug.vim" \
  --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  ]])
  call("plug#begin")
  require("vimplug")
  call("plug#end")
  vim.api.nvim_command("PlugInstall")
  require("plugins")
  require("settings")
  require("keymap")
end

loader.default = function()
  call("plug#begin")
  require("vimplug")
  call("plug#end")
  require("plugins")
  require("settings")
  require("keymap")
end

loader.setup()
