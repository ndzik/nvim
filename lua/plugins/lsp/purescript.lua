vim.lsp.config("purescriptls", {
    cmd = { "purescript-language-server", "--stdio" },
    filetypes = { "purescript" },
    root_markers = { "spago.dhall", "psc-package.json", "bower.json", "package.json", ".git" },
})

vim.lsp.enable({ "purescriptls" })
