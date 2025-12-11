local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.lsp.config["clangd"] = {
  capabilities = capabilities,
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--completion-style=detailed",
    "--header-insertion=never",
  },
}

vim.lsp.config["pyright"] = {
  capabilities = capabilities,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoImportCompletions = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
}

vim.lsp.config["asm_lsp"] = {
  capabilities = capabilities,
  cmd = { "asm-lsp" },
  filetypes = { "asm", "s", "S" },
  root_markers = { ".git" },
}

