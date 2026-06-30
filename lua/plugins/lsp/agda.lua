local capabilities = vim.deepcopy(require("plugins.completion"))

-- ALS currently advertises semantic tokens, but does not implement the
-- corresponding request handler. If Neovim requests them anyway, ALS reports:
-- "LSP: no handler for: textDocument/semanticTokens/full".
if capabilities.textDocument then
    capabilities.textDocument.semanticTokens = nil
end

local function disable_semantic_tokens(client)
    client.server_capabilities.semanticTokensProvider = nil
end

vim.lsp.config("agda_ls", {
    cmd = { "als" },
    filetypes = { "agda", "lagda" },
    root_markers = { "*.agda-lib", ".git" },
    capabilities = capabilities,
    on_init = disable_semantic_tokens,
    on_attach = disable_semantic_tokens,
})

vim.lsp.enable({ "agda_ls" })
