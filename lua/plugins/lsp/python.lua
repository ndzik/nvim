local conform = require("plugins.conform")

conform.register("python", {
    "ruff_fix",
    "ruff_organize_imports",
    "ruff_format",
})

vim.lsp.config("pyrefly", {
  cmd = { "pyrefly", "lsp" },
  init_options = {
    pyrefly = { displayTypeErrors = "force-on" },
  },
})

vim.lsp.enable({ "pyrefly" })
