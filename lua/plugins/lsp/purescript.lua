local common = require("plugins.lsp.common")
local capabilities = require("plugins.completion")

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    common.lsp_attach()
end

require("lspconfig").purescriptls.setup({
    on_attach = custom_lsp_attach,
    capabilities = capabilities,
})
