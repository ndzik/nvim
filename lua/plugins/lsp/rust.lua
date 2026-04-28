vim.lsp.config("rust_analyzer", {
    cmd = { "rust-analyzer" },
    filetypes = { "rust" },
    root_dir = require("lspconfig.util").root_pattern("Cargo.toml", ".git"),
})
