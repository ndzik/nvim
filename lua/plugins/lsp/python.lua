local common = require("plugins.lsp.common")
local capabilities = require("plugins.completion")

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    common.lsp_attach()

    vim.api.nvim_command([[autocmd BufWritePre *.rs lua vim.lsp.buf.format({timeout_ms = 2000})]])
end

require('lspconfig').pyright.setup({
    -- Make it compatible with virutalenv:
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "off",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
            },
            exclude = { "venv" },
            venvPath = ".",
            venv = ".venv",
        },
    },
    on_attach = custom_lsp_attach,
    capabilities = capabilities,
})
