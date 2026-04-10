local common = require("plugins.lsp.common")
local capabilities = require("plugins.completion")

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    common.lsp_attach()
    vim.api.nvim_exec([[
    augroup FormatAutogroup
    autocmd!
    autocmd BufWritePre *.jl lua vim.lsp.buf.format({timeout_ms = 2000})
    augroup END
    ]], true)
end

local lsp = require("lspconfig")
lsp.julials.setup({
  on_new_config = function(cfg,_)
    local julia = vim.fn.expand("~/.juliaup/bin/julia")
    cfg.cmd = { julia, "--startup-file=no", "--history-file=no",
      "-e", [[using LanguageServer, SymbolServer;
              runserver()]] }
  end,
  on_attach = custom_lsp_attach,
  capabilities = capabilities,
})
