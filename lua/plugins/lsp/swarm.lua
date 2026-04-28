local _util = require("lspconfig.util")

vim.api.nvim_command([[autocmd BufRead,BufNewFile *.sw setfiletype swarm]])

vim.lsp.config("swarm", {
    cmd = { "swarm", "lsp" },
    filetypes = { "swarm" },
    root_dir = _util.root_pattern("swarm.yaml", ".git"),
})
