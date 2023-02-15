local common = require("plugins.lsp.common")
local capabilities = require("plugins.completion")

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    common.lsp_attach()

    vim.api.nvim_command([[autocmd BufWritePre *.go lua vim.lsp.buf.format({timeout_ms = 2000})]])
end

require("lspconfig").gopls.setup({
    settings = {
        gopls = {
            analyses = {
                unusedparams = true,
            },
            staticcheck = true,
        },
    },
    on_attach = custom_lsp_attach,
    capabilities = capabilities,
})
