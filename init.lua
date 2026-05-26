vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local loader = require("loader")

local fn = vim.fn
local call = vim.call

loader.isNotInstalled = function()
  local install_path = fn.stdpath("data").."/site/autoload/plug.vim"
  return fn.empty(fn.glob(install_path)) > 0
end

loader.doInstall = function()
  local install_path = fn.stdpath("data") .. "/site/autoload/plug.vim"
  local result = vim.fn.system({
    "curl",
    "-fLo",
    install_path,
    "--create-dirs",
    "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim",
  })

  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to install vim-plug via curl: " .. tostring(result), vim.log.levels.ERROR)
    return
  end

  vim.cmd("source " .. vim.fn.fnameescape(install_path))

  call("plug#begin")
  require("vimplug")
  call("plug#end")

  vim.cmd("PlugInstall --sync")
  vim.cmd("source " .. vim.fn.fnameescape(vim.env.MYVIMRC))
end

loader.default = function()
  call("plug#begin")
  require("vimplug")
  call("plug#end")
  require("plugins")
  require("settings")
  require("speak")
  require("keymap")
end

loader.setup()

local filetype_augroup = vim.api.nvim_create_augroup("UserFiletypes", { clear = true })

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = filetype_augroup,
  pattern = "*.sw",
  command = "setfiletype swarm",
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = filetype_augroup,
  pattern = "*.typ",
  command = "setfiletype typst",
})
