vim.lsp.config("ts_ls", {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact" },
    root_markers = { "package.json", "tsconfig.json", ".git" },
})

vim.lsp.enable({ "ts_ls" })
