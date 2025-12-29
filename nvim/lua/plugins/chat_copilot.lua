local status, chat = pcall(require, "CopilotChat")
if not status then
  return
end

chat.setup({
  debug = false, -- Tắt debug cho đỡ rác log, khi nào lỗi thì bật true
  
  window = {
    layout = 'float',       -- Dạng cửa sổ nổi (float) hoặc 'vertical' (chia dọc)
    width = 0.6,            -- Rộng 60% màn hình
    height = 0.6,           -- Cao 60% màn hình
    relative = 'editor',
    border = 'rounded',     -- Viền bo tròn cho nó mềm mại
    title = ' Copilot ', -- Title cửa sổ chất chơi
  },

  mappings = {
    complete = {
      insert = '<Tab>',
    },
    close = {
      normal = 'q',
      insert = '<C-c>'
    },
    reset = {
      normal = '<C-l>',
      insert = '<C-l>'
    },
    submit_prompt = {
      normal = '<CR>',
      insert = '<C-m>'
    },
  },
})

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- 1. Mở khung chat nhanh (Leader + cc)
map('n', '<leader>cc', ':CopilotChat<CR>', 'Open Copilot Chat')

-- 2. Toggle (Bật/Tắt) nhanh khung chat (Leader + ct)
map('n', '<leader>ct', ':CopilotChatToggle<CR>', 'Toggle Chat')

-- 3. Giải thích code (Bôi đen xong bấm Leader + ce)
map('v', '<leader>ce', ':CopilotChatExplain<CR>', 'Explain Code')

-- 4. Sửa bug (Bôi đen xong bấm Leader + cf)
map('v', '<leader>cf', ':CopilotChatFix<CR>', 'Fix Bug')

-- 5. Tối ưu code (Bôi đen xong bấm Leader + co)
map('v', '<leader>co', ':CopilotChatOptimize<CR>', 'Optimize Code')

-- 6. Viết Unit Test (Bôi đen xong bấm Leader + ct)
map('v', '<leader>cu', ':CopilotChatTests<CR>', 'Generate Tests')

print("Copilot Chat đã lên nòng!")
