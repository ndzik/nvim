vim.lsp.config("biome", {
    cmd = { "biome", "lsp" },
    filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact" },
    root_dir = require("lspconfig.util").root_pattern("package.json", "tsconfig.json", ".git"),
})
