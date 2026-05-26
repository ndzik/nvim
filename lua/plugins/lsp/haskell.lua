vim.lsp.config("hls", {
    cmd = { "haskell-language-server-wrapper", "--lsp" },
    filetypes = { "haskell", "lhaskell" },
    root_markers = { "*.cabal", "stack.yaml", "cabal.project", "package.yaml", ".git" },
})

vim.lsp.enable({ "hls" })
