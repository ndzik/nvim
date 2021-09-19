local completion = require("completion")
local common = require("plugins.lsp.common")

local custom_lsp_attach = function(client)
    completion.on_attach()
    common.DefaultKeymap()

    vim.api.nvim_exec([[
    augroup FormatAutogroup
    autocmd!
    autocmd BufWritePost *.ts,*.tsx FormatWrite
    augroup END
    ]], true)
end

require("lspconfig").tsserver.setup({
    on_attach = custom_lsp_attach
})

local prettier_callback = function()
    return {
        exe = "prettier",
        args = { "--stdin-filepath", vim.api.nvim_buf_get_name(0) },
        stdin = true,
    }
end

require("formatter").setup({
    logging = true,
    filetype = {
        typescriptreact = { prettier_callback },
        typescript = { prettier_callback },
        json = { prettier_callback },
    },
})
