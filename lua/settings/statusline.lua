function SimpleStatus()
  local branch = vim.fn.FugitiveHead()

  if branch and #branch > 0 then
    branch = '  '..branch
  end

  return branch..' %f%m%=%l:%c'
end

vim.api.nvim_command([[set statusline=%!luaeval('SimpleStatus()')]])
