local common = require("plugins.lsp.common")
local _util = require("lspconfig.util")

vim.api.nvim_command([[autocmd BufRead,BufNewFile *.sw setfiletype swarm]])

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    common.lsp_attach()
end

local lspconfig = require('lspconfig')
local configs = require('lspconfig.configs')

if not configs.swarm then
    configs.swarm = {
        default_config = {
            cmd = { 'swarm', 'lsp' },
            filetypes = { 'swarm' },
            single_file_support = true,
            settings = {},
        },
    }
end

require('lspconfig').swarm.setup({
    on_attach = custom_lsp_attach,
})
