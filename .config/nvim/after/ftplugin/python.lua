local set = vim.opt

set.wrap = false

set.tabstop = 4
set.softtabstop = 4
set.shiftwidth = 4
set.expandtab = true

vim.g.slime_python_ipython = true

vim.api.nvim_command('autocmd FileType python setlocal foldmethod=indent')


-- -- Set foldmethod to "indent" for Python files
-- vim.cmd('autocmd FileType python setlocal foldmethod=indent')

-- -- Enable folding for Python files
-- vim.cmd('autocmd FileType python setlocal foldenable')


-- require'lspconfig'.pyright.setup{}
