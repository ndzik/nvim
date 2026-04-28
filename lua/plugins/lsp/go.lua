vim.lsp.config("gopls", {
    cmd = { "gopls", "serve" },
    filetypes = { "go", "gomod" },
    root_dir = require("lspconfig.util").root_pattern("go.work", "go.mod", ".git"),
})
