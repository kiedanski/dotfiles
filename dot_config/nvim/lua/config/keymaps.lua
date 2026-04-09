-- ~/.config/nvim/lua/config/keymaps.lua
-- Essential keybindings

local keymap = vim.keymap.set

-- Better escape
keymap("i", "jk", "<ESC>")
keymap("i", "kj", "<ESC>")

-- Clear search highlighting
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Window navigation
keymap("n", "<C-h>", "<C-w>h")
keymap("n", "<C-j>", "<C-w>j")
keymap("n", "<C-k>", "<C-w>k")
keymap("n", "<C-l>", "<C-w>l")

-- Terminal mode window navigation (add these)
keymap("t", "<C-h>", "<C-\\><C-n><C-w>h")
keymap("t", "<C-j>", "<C-\\><C-n><C-w>j")
keymap("t", "<C-k>", "<C-\\><C-n><C-w>k")
keymap("t", "<C-l>", "<C-\\><C-n><C-w>l")

-- Bonus: easier escape from terminal mode
keymap("t", "<Esc>", "<C-\\><C-n>")


-- File operations
keymap("n", "<leader>w", "<cmd>w<CR>")
keymap("n", "<leader>q", "<cmd>q<CR>")

-- Better indenting
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- Move lines
keymap("v", "J", ":m '>+1<CR>gv=gv")
keymap("v", "K", ":m '<-2<CR>gv=gv")

-- Buffers
keymap("n", "<S-h>", "<cmd>bprevious<CR>")
keymap("n", "<S-l>", "<cmd>bnext<CR>")
keymap("n", "<leader>x", "<cmd>bdelete<CR>")

-- Find files (will work once Telescope is loaded)
keymap("n", "<leader>ff", "<cmd>Telescope find_files<CR>")
keymap("n", "<leader>fg", "<cmd>Telescope live_grep<CR>")
keymap("n", "<leader>fb", "<cmd>Telescope buffers<CR>")

-- LSP (will work once LSP is loaded)
keymap("n", "gd", vim.lsp.buf.definition)
keymap("n", "gr", vim.lsp.buf.references)
keymap("n", "K", vim.lsp.buf.hover)
keymap("n", "<leader>ca", vim.lsp.buf.code_action)
keymap("n", "<leader>rn", vim.lsp.buf.rename)
keymap("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end)


-- Folding
keymap("n", "zf", "zc", { desc = "Fold current block" })      -- Fold
keymap("n", "zo", "zo", { desc = "Open current fold" })       -- Open fold
keymap("n", "za", "za", { desc = "Toggle current fold" })     -- Toggle fold
keymap("n", "zR", "zR", { desc = "Open all folds" })          -- Open all
keymap("n", "zM", "zM", { desc = "Close all folds" })         -- Close all
keymap("n", "zr", "zr", { desc = "Reduce fold level" })       -- Reduce fold level
keymap("n", "zm", "zm", { desc = "Increase fold level" })     -- More folding

-- Custom shortcuts
keymap("n", "<Space>z", "za", { desc = "Toggle fold" })       -- Space+z to toggle
keymap("n", "<Space>Z", "zR", { desc = "Open all folds" })    -- Space+Z to open all


-- Jumping functions
keymap("n", "<leader>nf", "]f", { desc = "Next function" })
keymap("n", "<leader>pf", "[f", { desc = "Previous function" })
keymap("n", "<leader>nc", "]c", { desc = "Next class" })
keymap("n", "<leader>pc", "[c", { desc = "Previous class" })


keymap("n", "]e", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next error" })

keymap("n", "[e", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Previous error" })

-- Show current error details
keymap("n", "<leader>e", function()
  vim.diagnostic.open_float({
    border = "rounded",
    source = "always",
    header = "",
    prefix = "🔴 ",
    width = 80,
    max_width = 120,
    wrap = true,
    focusable = true,
  })
end, { desc = "Show current error" })


keymap("n", "<leader>rr", function()
  vim.cmd("source ~/.config/nvim/init.lua")
  print("🔄 Config reloaded!")
end, { desc = "Reload config" })


-- Close any popup quickly
keymap("n", "<leader>qq", function()
  -- Close quickfix first
  vim.cmd("cclose")
  -- Close any floating windows
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then  -- floating window
      vim.api.nvim_win_close(win, false)
    end
  end
end, { desc = "Close quickfix and floats" })




-- AI Assistant (Avante)
keymap("n", "<leader>aa", "<cmd>AvanteAsk<cr>", { desc = "Ask AI" })
keymap("v", "<leader>aa", "<cmd>AvanteAsk<cr>", { desc = "Ask AI about selection" })
keymap("n", "<leader>ae", "<cmd>AvanteEdit<cr>", { desc = "Edit with AI" })
keymap("v", "<leader>ae", "<cmd>AvanteEdit<cr>", { desc = "Edit selection with AI" })
keymap("n", "<leader>ar", "<cmd>AvanteRefresh<cr>", { desc = "Refresh AI" })
keymap("n", "<leader>at", "<cmd>AvanteToggle<cr>", { desc = "Toggle AI sidebar" })
keymap("n", "<leader>ac", "<cmd>AvanteChat<cr>", { desc = "Open AI chat" })

-- Quick AI prompts for Python
keymap("n", "<leader>ad", function()
  vim.cmd("AvanteAsk Add comprehensive docstrings to this Python code")
end, { desc = "Add docstrings" })

keymap("n", "<leader>ah", function()
  vim.cmd("AvanteAsk Add type hints to this Python function")
end, { desc = "Add type hints" })

keymap("n", "<leader>ao", function()
  vim.cmd("AvanteAsk Optimize this Python code for better performance")
end, { desc = "Optimize code" })

keymap("n", "<leader>ab", function()
  vim.cmd("AvanteAsk Find and fix potential bugs in this code")
end, { desc = "Find bugs" })

keymap("n", "<leader>au", function()
  vim.cmd("AvanteAsk Write unit tests for this Python function")
end, { desc = "Write unit tests" })


-- Undo tree
keymap("n", "<leader>u", "<cmd>UndotreeToggle<cr>", { desc = "Toggle undo tree" })


-- Iron vim
-- Iron.nvim Python workflow
keymap("n", "<leader>rs", "<cmd>IronRepl<cr>", { desc = "Start REPL" })
keymap("n", "<leader>rr", "<cmd>IronRestart<cr>", { desc = "Restart REPL" })
keymap("n", "<leader>rf", "<cmd>IronFocus<cr>", { desc = "Focus REPL" })
keymap("n", "<leader>rh", "<cmd>IronHide<cr>", { desc = "Hide REPL" })

-- Quick Python commands
keymap("n", "<leader>ri", function()
  require("iron.core").send(nil, "import numpy as np\nimport pandas as pd\nimport matplotlib.pyplot as plt")
end, { desc = "Send common imports" })

keymap("n", "<leader>rp", function()
  require("iron.core").send(nil, "%pwd")
end, { desc = "Print working directory" })

keymap("n", "<leader>rw", function()
  require("iron.core").send(nil, "%who")
end, { desc = "Show variables" })

-- Send current function (Python-specific)
keymap("n", "<leader>sf", function()
  -- Save cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  
  -- Find function start
  vim.cmd("normal! [[")
  local func_start = vim.api.nvim_win_get_cursor(0)[1]
  
  -- Find function end (next function or class or end of file)
  vim.cmd("normal! ][")
  local func_end = vim.api.nvim_win_get_cursor(0)[1] - 1
  
  -- If no next function found, go to end of file
  if func_end < func_start then
    func_end = vim.api.nvim_buf_line_count(0)
  end
  
  -- Restore cursor position
  vim.api.nvim_win_set_cursor(0, cursor)
  
  -- Send the function
  require("iron.core").send_motion(func_start .. "G")
end, { desc = "Send current function" })



-- LLM keybindings
vim.keymap.set('n', '<leader>lla', ':LLMProvider anthropic<CR>', { noremap = true, silent = true, desc = 'Anthropic' })
vim.keymap.set('n', '<leader>lll', ':LLMProvider local<CR>', { noremap = true, silent = true, desc = 'Local LLM' })
vim.keymap.set('n', '<leader>lls', ':LLMStatus<CR>', { noremap = true, silent = true, desc = 'LLM Status' })
