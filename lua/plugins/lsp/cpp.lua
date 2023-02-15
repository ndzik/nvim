local common = require("plugins.lsp.common")
local capabilities = require("plugins.completion")

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    common.lsp_attach()

    vim.api.nvim_command([[autocmd BufWritePre *.{cpp,h,hpp} lua vim.lsp.buf.format({timeout_ms = 2000})]])
end

require("lspconfig").ccls.setup({
    on_attach = custom_lsp_attach,
    filetypes = {"c", "cpp", "objc", "objcpp", "cuda"},
    capabilities = capabilities,
})
