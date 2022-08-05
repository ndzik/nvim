local common = require("plugins.lsp.common")
local capabilities = require("plugins.completion")

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    vim.api.nvim_exec([[
    augroup FormatAutogroup
    autocmd!
    autocmd BufWritePost *.hs,*.lhs lua vim.lsp.buf.formatting_sync()
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
