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
local capabilities = require("plugins.completion")

for _, server in ipairs({
  "rust_analyzer",
  "hls",
  "pyrefly",
  "clangd",
  "lua_ls",
  "texlab",
  "gopls",
  "ts_ls",
  "biome",
  "purescriptls",
  "swarm",
  "julials",
  "tinymist",
}) do
  vim.lsp.config(server, { capabilities = capabilities })
end

local augroup = vim.api.nvim_create_augroup("UserLspConfig", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    common.DefaultKeymap(ev.buf, client)
    common.lsp_attach()
  end,
})
