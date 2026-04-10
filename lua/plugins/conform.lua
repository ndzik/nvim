-- lua/plugins/conform.lua
local M = {
  formatters_by_ft = {
    svelte = { "prettier" },
    typescript = { "prettier" },
    javascript = { "prettier" },
    html = { "prettier" },
    jsx = { "prettier" },
    tsx = { "prettier" },
  },
}

function M.register(ft, formatter_list)
  M.formatters_by_ft[ft] = formatter_list
end

function M.setup()
  require("conform").setup({
    formatters_by_ft = M.formatters_by_ft,
    format_on_save = {
      timeout_ms = 2000,
      lsp_fallback = false,
    },
  })
end

return M
