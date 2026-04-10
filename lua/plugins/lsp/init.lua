require("plugins.lsp.common")
require("plugins.lsp.rust")
require("plugins.lsp.haskell")
require("plugins.lsp.python")
require("plugins.lsp.cpp")
require("plugins.lsp.lua")
require("plugins.lsp.latex")
require("plugins.lsp.go")
require("plugins.lsp.ts")
require("plugins.lsp.biome")
require("plugins.lsp.purescript")
require("plugins.lsp.swarm")
require("plugins.lsp.julia")
require("plugins.lsp.typst")

local common = require("plugins.lsp.common")

local augroup = vim.api.nvim_create_augroup("UserLspConfig", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    common.DefaultKeymap()
    common.lsp_attach()

    local opts = { buffer = ev.buf, silent = true }

    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

    -- Capability-gated mappings (correct, avoids no-op keys)
    if client and client.server_capabilities.codeActionProvider then
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    end
  end,
})
