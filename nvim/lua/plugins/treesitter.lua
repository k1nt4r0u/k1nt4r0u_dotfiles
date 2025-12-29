local status_ok, configs = pcall(require, "nvim-treesitter.configs")
if not status_ok then
  return
end

local install_status, install = pcall(require, "nvim-treesitter.install")
if not install_status then
  return
end

install.prefer_git = true
install.compilers = { "gcc", "clang" }

configs.setup({
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
