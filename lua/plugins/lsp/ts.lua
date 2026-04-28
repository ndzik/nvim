vim.lsp.config("ts_ls", {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact" },
    root_dir = require("lspconfig.util").root_pattern("package.json", "tsconfig.json", ".git"),
})
