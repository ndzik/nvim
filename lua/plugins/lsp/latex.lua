vim.lsp.config("texlab", {
    cmd = { "texlab" },
    filetypes = { "tex", "bib" },
    root_dir = require("lspconfig.util").root_pattern(".latexmkrc", "Makefile", ".git"),
})
