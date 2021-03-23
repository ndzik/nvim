-- This module describes global lsp configuration options. Most of the stuff
-- here can also be used to individually configure a lsp server, but
-- aggregating them here reduces duplication.

local common = { }

local utils = require("utils")

utils.opt('o', "omnifunc", "v:lua.vim.lsp.omnifunc")

vim.g.completion_enable_auto_hover = 0
vim.g.completion_enable_auto_popup = 0

-- DefaultKeymap defines a default keymapping for lsp actions, which can be
-- called in the `lsp_attach` hook. It sets the keybinds only for the buffers,
-- so that the nvims keymap space does not get polluted.
function common.DefaultKeymap()
    local opts = { noremap = true, silent = true }
    utils.mapbuf('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    utils.mapbuf('n', '<c-]>', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    utils.mapbuf('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    utils.mapbuf('n', '<leader>cr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    utils.mapbuf('n', '<leader>cR', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    utils.mapbuf('n', '<leader>cs', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    utils.mapbuf('n', '<leader>cg', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)

    utils.mapbuf('i', '<c-space>', '<Plug>(completion_trigger)', { noremap = false, silent = true })
end

return common
