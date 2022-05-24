local common = require("plugins.lsp.common")

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
    cmd = { "haskell-language-server", "--lsp" },
    settings = {
        languageServerHaskell = {
          formattingProvider = "brittany",
          hlintOn = true,
        },
    },
    on_attach = custom_lsp_attach,
})