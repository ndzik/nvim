local common = require("plugins.lsp.common")
local capabilities = require("plugins.completion")

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    common.lsp_attach()
    vim.api.nvim_exec([[
    augroup FormatAutogroup
    autocmd!
    autocmd BufWritePre *.hs,*.lhs lua vim.lsp.buf.format({timeout_ms = 2000})
    augroup END
    ]], true)
end

require("lspconfig").hls.setup({
    settings = {
        haskell = {
          hlintOn = true,
        },
    },
    on_attach = custom_lsp_attach,
    capabilities = capabilities,
})
