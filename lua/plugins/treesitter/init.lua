require("nvim-treesitter").setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

local function start_treesitter(args)
  local ok, err = pcall(vim.treesitter.start, args.buf)

  if not ok then
    vim.notify("Could not start Tree-sitter for Agda: " .. tostring(err), vim.log.levels.WARN)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserAgdaTreesitter", { clear = true }),
  pattern = "agda",
  callback = start_treesitter,
})
