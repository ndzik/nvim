local common = require("plugins.lsp.common")

local custom_lsp_attach = function(client)
    common.DefaultKeymap()

    vim.api.nvim_command([[autocmd BufWritePre *.{cpp,h,hpp} lua vim.lsp.buf.formatting_sync()]])
end

require("lspconfig").ccls.setup({
    on_attach = custom_lsp_attach,
    filetypes = {"c", "cpp", "objc", "objcpp", "cuda"},
})
