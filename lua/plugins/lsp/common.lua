-- This module describes global lsp configuration options. Most of the stuff
-- here can also be used to individually configure a lsp server, but
-- aggregating them here reduces duplication.

local common = { }

-- DefaultKeymap defines a default keymapping for lsp actions, which can be
-- called in the `lsp_attach` hook. It sets the keybinds only for the buffers,
-- so that the nvims keymap space does not get polluted.
function common.DefaultKeymap(bufnr, client)
    local opts = { buffer = bufnr, silent = true }

    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<leader>k', vim.diagnostic.open_float, opts)
    vim.keymap.set('n', '<c-]>', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<c-i>', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>cR', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>cs', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<leader>cg', vim.lsp.buf.workspace_symbol, opts)

    vim.keymap.set('n', '<leader>di', vim.diagnostic.setloclist, opts)
    vim.keymap.set('n', '<leader>dn', function() vim.diagnostic.jump({ count = 1 }) end, opts)
    vim.keymap.set('n', '<leader>dp', function() vim.diagnostic.jump({ count = -1 }) end, opts)

    if client and client.server_capabilities.codeActionProvider then
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    end
end

function common.lsp_attach()
    vim.diagnostic.config({
        underline = false,
        virtual_text = {
            format = function(diag)
                return string.format("%s...", string.sub(diag.message, 0, 10))
            end
        }
    })
end

return common
