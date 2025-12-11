local keymap = vim.keymap.set
local fzf = require("fzf-lua")

keymap("n", "<leader>f", fzf.files, { desc = "Fzf files" })
keymap("n", "<leader>g", fzf.live_grep, { desc = "Fzf live grep" })
keymap("n", "<leader>b", fzf.buffers, { desc = "Fzf buffers" })
keymap("n", "<leader>o", fzf.oldfiles, { desc = "Fzf oldfiles" })

