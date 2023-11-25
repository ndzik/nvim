local common = require("plugins.lsp.common")
local capabilities = require("plugins.completion")

require("neodev").setup()

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    common.lsp_attach()
end

require('lspconfig').lua_ls.setup({
    cmd = {"lua-language-server"};
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',
                path = vim.split(package.path, ';'),
            },
            diagnostics = {
                globals = {'vim'},
            },
            workspace = {
                library = {
                    [vim.fn.expand('$VIMRUNTIME/lua')] = true,
                    [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true,
                },
            },
        }
    },
    on_attach = custom_lsp_attach,
    capabilities = capabilities,
})
