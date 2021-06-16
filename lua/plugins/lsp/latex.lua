local completion = require("completion")
local common = require("plugins.lsp.common")

local custom_lsp_attach = function(client)
    completion.on_attach()
    common.DefaultKeymap()
end

require("lspconfig").texlab.setup({
    on_attach = custom_lsp_attach
})
