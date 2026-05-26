vim.api.nvim_command([[autocmd BufRead,BufNewFile *.sw setfiletype swarm]])

vim.lsp.config("swarm", {
    cmd = { "swarm", "lsp" },
    filetypes = { "swarm" },
    root_markers = { "swarm.yaml", ".git" },
})

vim.lsp.enable({ "swarm" })
