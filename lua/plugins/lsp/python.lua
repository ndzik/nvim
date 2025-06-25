local common = require("plugins.lsp.common")
local conform = require("plugins.conform")

local custom_lsp_attach = function(client)
    common.DefaultKeymap()
    common.lsp_attach()
    vim.lsp.set_log_level("debug")
end

conform.register("python", {
    "ruff_fix",
    "ruff_organize_imports",
    "ruff_format",
})

require('lspconfig').basedpyright.setup({
    on_attach = custom_lsp_attach,
    settings = {
      basedpyright = {
        mason = false,
        settings = {
          pyright = {
            -- Using Ruff's import organizer
            disableOrganizeImports = true,
          },
          python = {
            analysis = {
              -- Ignore all files for analysis to exclusively use Ruff for linting
              ignore = { "*" },
            },
          },
        },
      },
      ruff = {
        mason = false,
        init_options = {},
      },
  }
})

