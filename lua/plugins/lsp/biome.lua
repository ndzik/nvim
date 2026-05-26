vim.lsp.config("biome", {
    cmd = { "biome", "lsp" },
    filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact" },
    root_markers = { "package.json", "tsconfig.json", ".git" },
})

vim.lsp.enable({ "biome" })
