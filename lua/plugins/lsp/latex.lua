vim.lsp.config("texlab", {
    cmd = { "texlab" },
    filetypes = { "tex", "bib" },
    root_markers = { ".latexmkrc", "Makefile", ".git" },
})

vim.lsp.enable({ "texlab" })
