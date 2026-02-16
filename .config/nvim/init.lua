-- ~/.config/nvim/init.lua
-- Minimal Python development setup

-- Set leader key FIRST
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Load configuration
require("config.options")
require("config.keymaps")
require("config.lazy")
require("config.commands")
require("config.terminal")
