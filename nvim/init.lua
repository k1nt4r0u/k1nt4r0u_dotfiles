local vim = vim
local Plug = vim.fn['plug#']

vim.call('plug#begin')

Plug('yuttie/hydrangea-vim')
Plug('mistweaverco/bluloco.nvim')
Plug('nvim-treesitter/nvim-treesitter', {[ 'do' ] = ':TSUpdate'})
Plug('neovim/nvim-lspconfig')
Plug('hrsh7th/vim-vsnip')
Plug('hrsh7th/cmp-buffer')
Plug('hrsh7th/cmp-path')
Plug('hrsh7th/cmp-cmdline')
Plug('hrsh7th/nvim-cmp')
Plug('hrsh7th/cmp-nvim-lsp' )
Plug('hrsh7th/cmp-nvim-lsp-signature-help')
Plug('uloco/bluloco.nvim')
--Plug('rktjmp/lush.nvim')
Plug('folke/tokyonight.nvim')
Plug('rafi/awesome-vim-colorschemes')
Plug('catppuccin/nvim')
Plug('scottmckendry/cyberdream.nvim')
Plug('EdenEast/nightfox.nvim')
Plug('romgrk/barbar.nvim')
Plug('kyazdani42/nvim-web-devicons')
Plug('kyazdani42/nvim-tree.lua')
Plug('nvim-lua/plenary.nvim')
Plug('nvim-telescope/telescope.nvim', { [ 'tag' ] = '0.1.4' })
Plug('nvim-lualine/lualine.nvim')
Plug('windwp/nvim-autopairs')
Plug('L3MON4D3/LuaSnip')
Plug('saadparwaiz1/cmp_luasnip')
Plug('drazil100/dusklight.vim')
Plug('ibhagwan/fzf-lua', {['branch'] = 'main'})
Plug('lewis6991/gitsigns.nvim')
Plug('numToStr/Comment.nvim')
Plug('lukas-reineke/indent-blankline.nvim')
Plug('norcalli/nvim-colorizer.lua')
Plug('folke/which-key.nvim')
Plug('windwp/nvim-ts-autotag')
Plug('stevearc/conform.nvim')
Plug('goolord/alpha-nvim')
Plug('lervag/vimtex')

vim.call('plug#end')

local home=os.getenv("HOME")
package.path = home .. "/.config/nvim/?.lua;" .. package.path
require"theme"
require"common" 
require"combinations"
require('plugins.lualine')
require('plugins.telescope')
require('plugins.treesitter')
require('plugins.vimtree')
require('plugins.barbar')
require('plugins.cmp')
require('plugins.lspconfig')
require('plugins.autopairs')
require('plugins.whichkey')
require('plugins.coding')
require('plugins.interface')
require("luasnip.loaders.from_vscode").lazy_load({
    paths = { vim.fn.stdpath("config") .. "/lua/snippets" }
})
require('plugins.pwn')
require('plugins.cpp_snip')
require('plugins.asm_snip')
vim.cmd [[
  hi Normal guibg=none
  hi NormalNC guibg=none
  hi SignColumn guibg=none
  hi EndOfBuffer guibg=none
  hi LineNr guibg=none
  hi CursorLine guibg=none
  hi CursorLineNr guibg=none
  hi NormalFloat guibg=none
  hi FloatBorder guibg=none
  hi Pmenu guibg=none
  hi PmenuSel guibg=none
  hi PmenuThumb guibg=none
  hi NvimTreeNormal guibg=none
  hi NvimTreeNormalNC guibg=none
  hi NvimTreeEndOfBuffer guibg=none
  hi StatusLine guibg=none
  hi StatusLineNC guibg=none
  hi TabLine guibg=none
  hi TabLineFill guibg=none
  hi TabLineSel guibg=none
  hi TelescopeNormal guibg=none
  hi TelescopeBorder guibg=none
]]
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.opt.cmdheight = 0 
vim.opt.laststatus = 3





