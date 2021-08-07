local completion = require("completion")
local common = require("plugins.lsp.common")

local custom_lsp_attach = function(client)
    completion.on_attach()
    common.DefaultKeymap()

    vim.api.nvim_command([[autocmd BufWritePre *.rs lua vim.lsp.buf.formatting_sync()]])
end

require('lspconfig').rust_analyzer.setup({
  on_attach = custom_lsp_attach
})
