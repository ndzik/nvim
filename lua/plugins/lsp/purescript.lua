vim.lsp.config("purescriptls", {
    cmd = { "purescript-language-server", "--stdio" },
    filetypes = { "purescript" },
    root_dir = require("lspconfig.util").root_pattern("spago.dhall", "psc-package.json", "bower.json", "package.json", ".git"),
})
