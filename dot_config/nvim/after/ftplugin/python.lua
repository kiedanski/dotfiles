-- ~/.config/nvim/after/ftplugin/python.lua
-- Python-specific iron settings

local keymap = vim.keymap.set
local opts = { buffer = true }

-- Enhanced Python function sending
keymap("n", "<leader>sf", function()
  -- Find function boundaries more accurately
  local current_line = vim.fn.line(".")
  local func_start = vim.fn.search("^def ", "bcnW")
  
  if func_start == 0 then
    print("No function found")
    return
  end
  
  -- Find function end
  vim.fn.cursor(func_start, 1)
  local func_end = vim.fn.search("^\\(def\\|class\\|^[[:alpha:]]\\)", "nW")
  if func_end == 0 then
    func_end = vim.fn.line("$")
  else
    func_end = func_end - 1
  end
  
  -- Send the function
  require("iron.core").send_motion(func_start .. "," .. func_end .. "y")
  
  -- Restore cursor
  vim.fn.cursor(current_line, 1)
end, vim.tbl_extend("force", opts, { desc = "Send current function" }))

-- Send class
keymap("n", "<leader>sC", function()
  local current_line = vim.fn.line(".")
  local class_start = vim.fn.search("^class ", "bcnW")
  
  if class_start == 0 then
    print("No class found")
    return
  end
  
  vim.fn.cursor(class_start, 1)
  local class_end = vim.fn.search("^\\(class\\|def\\|^[[:alpha:]]\\)", "nW")
  if class_end == 0 then
    class_end = vim.fn.line("$")
  else
    class_end = class_end - 1
  end
  
  require("iron.core").send_motion(class_start .. "," .. class_end .. "y")
  vim.fn.cursor(current_line, 1)
end, vim.tbl_extend("force", opts, { desc = "Send current class" }))

-- Quick debugging
keymap("n", "<leader>sb", function()
  local line = vim.fn.line(".")
  require("iron.core").send(nil, "print(f'Line " .. line .. ": {locals()}')")
end, vim.tbl_extend("force", opts, { desc = "Debug current line" }))

vim.opt.makeprg = [[uvx ruff-quickfix %]]
vim.opt.errorformat = [[%f:%l:%c:%t:%m]]
