require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "c", "cpp", "python", "lua",
    "bash", "json", "jsonc",
    "markdown", "markdown_inline",
    "vim", "vimdoc", "query",
  },

  highlight = { enable = true },
  incremental_selection = { enable = true },
  textobjects = { enable = true },

  indent = {
    enable = true,
    disable = { "python" },
  },
})
