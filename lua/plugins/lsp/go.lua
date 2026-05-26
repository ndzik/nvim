vim.lsp.config("gopls", {
    cmd = { "gopls", "serve" },
    filetypes = { "go", "gomod" },
    root_markers = { "go.work", "go.mod", ".git" },
})

vim.lsp.enable({ "gopls" })
