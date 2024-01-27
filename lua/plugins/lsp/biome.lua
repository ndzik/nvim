local common = require("plugins.lsp.common")
local capabilities = require("plugins.completion")

local custom_lsp_attach = function(client)
    common.lsp_attach()

    vim.api.nvim_command([[autocmd BufWritePre *.{ts,tsx,js,jsx} lua vim.lsp.buf.format({timeout_ms = 2000})]])
end

require("lspconfig").biome.setup({
    on_attach = custom_lsp_attach,
    capabilities = capabilities,
})
