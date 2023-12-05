local common = require("plugins.lsp.common")
local capabilities = require("plugins.completion")

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    common.lsp_attach()

    vim.lsp.set_log_level("debug")
    vim.api.nvim_command([[autocmd BufWritePre *.py lua vim.lsp.buf.format({timeout_ms = 2000})]])
end

require('lspconfig').pylsp.setup({
    settings = {
        pylsp = {
            plugins = {
                black = {
                    enabled = true,
                },
                isort = {
                    enabled = true,
                },
                pylsp_mypy = {
                    enabled = true,
                    ignore_missing_imports = true,
                    live_mode = false,
                },
                flake8 = {
                    enabled = false,
                },
                pycodestyle = {
                    enabled = false,
                },
            },
        },
    },
    on_attach = custom_lsp_attach,
    capabilities = capabilities,
})
