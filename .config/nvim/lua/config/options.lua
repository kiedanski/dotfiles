-- ~/.config/nvim/lua/config/options.lua
-- Basic Neovim settings

local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.wrap = false
opt.cursorline = true

-- Behavior
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.splitbelow = true
opt.splitright = true
opt.updatetime = 250

-- File handling
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true

-- Create undo directory
local undo_dir = vim.fn.expand('~/.local/share/nvim/undo')
if vim.fn.isdirectory(undo_dir) == 0 then
    vim.fn.mkdir(undo_dir, 'p')
end
opt.undodir = undo_dir

-- Modern treesitter folding (add to your existing options)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = true
opt.foldlevel = 99
opt.foldlevelstart = 99
-- Python
vim.g.python3_host_prog = vim.fn.exepath("python3") or vim.fn.exepath("python")


-- disable unsed plugins

vim.g.loaded_gzip = 1
vim.g.loaded_zip = 1
vim.g.loaded_zipPlugin = 1
vim.g.loaded_tar = 1
vim.g.loaded_tarPlugin = 1
vim.g.loaded_getscript = 1
vim.g.loaded_getscriptPlugin = 1
vim.g.loaded_vimball = 1
vim.g.loaded_vimballPlugin = 1
vim.g.loaded_2html_plugin = 1
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrwSettings = 1
vim.g.loaded_netrwFileHandlers = 1
vim.g.loaded_matchit = 1
vim.g.loaded_matchparen = 1
vim.g.loaded_logiPat = 1
vim.g.loaded_rrhelper = 1
vim.g.loaded_spellfile_plugin = 1
vim.g.loaded_tutor_mode_plugin = 1

-- Disable unused providers
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Performance settings
vim.opt.lazyredraw = true
vim.opt.updatetime = 100
vim.opt.synmaxcol = 200
