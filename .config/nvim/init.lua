require "plugins"
require "lsp"
require "autocomplete"

vim.cmd("filetype plugin on")

vim.cmd [[
  autocmd BufRead,BufNewFile *.md set filetype=markdown 
  autocmd vimenter *.md Goyo
]]

vim.g.slime_target = "tmux"
vim.g["slime_default_config"] = {socket_name = "default", target_pane = "{last}"}

-- Set background color for folded regions
vim.cmd('highlight Folded guibg=DarkGrey guifg=White')

-- Set the character used to separate folded regions


-- First, specify the directory for undo files
local undo_dir = vim.fn.expand('~/.local/share/nvim/undo')

-- Check if the undo directory exists, if not, create it
if not vim.fn.isdirectory(undo_dir) then
    vim.fn.mkdir(undo_dir, 'p')
end

-- Set up Neovim to use the specified undo directory and enable infinite undo
vim.opt.undodir = undo_dir   -- Set the undo directory
vim.opt.undofile = true      -- Enable persistent undo
vim.opt.undolevels = 1000    -- Maximum number of changes that can be undone
vim.opt.undoreload = 10000   -- Maximum number lines to save for undo on a buffer reload


require('tabnine').setup({
  disable_auto_comment=true,
  accept_keymap="<Tab>",
  dismiss_keymap = "<C-]>",
  debounce_ms = 800,
  suggestion_color = {gui = "#808080", cterm = 244},
  exclude_filetypes = {"TelescopePrompt", "NvimTree"},
  log_file_path = nil, -- absolute path to Tabnine log file
})
