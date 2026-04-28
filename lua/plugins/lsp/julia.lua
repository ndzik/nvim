vim.lsp.config("julials", {
    cmd = { "julia", "--startup-file=no", "--history-file=no",
      "-e", [[using LanguageServer, SymbolServer;
              runserver()]] },
    filetypes = { "julia" },
    root_dir = require("lspconfig.util").root_pattern("Project.toml", ".git"),
})
