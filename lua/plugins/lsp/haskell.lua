vim.lsp.config("hls", {
    cmd = { "haskell-language-server-wrapper", "--lsp" },
    filetypes = { "haskell", "lhaskell" },
    root_dir = require("lspconfig.util").root_pattern("*.cabal", "stack.yaml", "cabal.project", "package.yaml", ".git"),
})
