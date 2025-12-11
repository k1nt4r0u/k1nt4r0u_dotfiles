local npairs = require("nvim-autopairs")

npairs.setup({
  check_ts = true,
  disable_filetype = { "TelescopePrompt", "vim" },

  fast_wrap = {
    map = '<M-e>',
    chars = { '{', '[', '(', '"', "'", '<' },
    end_key = '$',
    keys = 'qwertyuiopzxcvbnmasdfghjkl',
    check_comma = true,
    highlight = "Search",
    highlight_grey = "Comment"
  }
})

local cmp_autopairs = require("nvim-autopairs.completion.cmp")
local cmp = require("cmp")

cmp.event:on(
  "confirm_done",
  cmp_autopairs.on_confirm_done()
)
