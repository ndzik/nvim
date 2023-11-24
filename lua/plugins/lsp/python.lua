local common = require("plugins.lsp.common")
local capabilities = require("plugins.completion")

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    common.lsp_attach()

    vim.api.nvim_command([[autocmd BufWritePre *.rs lua vim.lsp.buf.format({timeout_ms = 2000})]])
end

require('lspconfig').pylsp.setup({
    -- Make it compatible with virutalenv:
    settings = {
        pylsp = {
            pyls_black = {
                enabled = true,
                exclude = { "**/venv/**" },
            },
            pyls_isort = {
                enabled = true,
                exclude = { "**/venv/**" },
            },
            pyls_mypy = {
                enabled = true,
                exclude = { "**/venv/**" },
            },
            pyls_flake8 = {
                enabled = true,
                exclude = { "**/venv/**" },
            },
        },
    },
    on_attach = custom_lsp_attach,
    capabilities = capabilities,
})
