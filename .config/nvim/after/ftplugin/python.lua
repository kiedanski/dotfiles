local set = vim.opt

set.wrap = true
-- set.linewidth = 80

set.tabstop = 4
set.softtabstop = 4
set.shiftwidth = 4
set.expandtab = true

vim.g.slime_python_ipython = true

-- require'lspconfig'.pyright.setup{}
--
-- Custom folding configuration for Python files
local function custom_python_folding()
  -- Set the foldmethod to marker
  vim.wo.foldmethod = 'marker'
  
  -- Set the foldmarker to use the custom marker
  vim.wo.foldmarker = '## %,## %'
end

-- Enable custom folding for Python files
vim.cmd('autocmd FileType python lua custom_python_folding()')

