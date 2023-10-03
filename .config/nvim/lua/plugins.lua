local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use { 'embark-theme/vim', as = 'embark' } -- colorscheme
  use 'neovim/nvim-lspconfig' -- Configurations for Nvim LSP

  use 'tpope/vim-commentary' -- comments

  use 'junegunn/goyo.vim' -- distraction free writing

  -- configurations for autocompletition
  use 'hrsh7th/nvim-cmp' -- Autocompletion plugin
  use 'hrsh7th/cmp-nvim-lsp' -- LSP source for nvim-cmp
  use 'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
  use 'L3MON4D3/LuaSnip' -- Snippets plugin

  use 'jpalardy/vim-slime' -- Send code to REPL

  use {
  "kevinhwang91/nvim-ufo",
  opt = true,
  event = { "BufReadPre" },
  wants = { "promise-async" },
  requires = "kevinhwang91/promise-async",
  config = function()
    require("ufo").setup {
      provider_selector = function(bufnr, filetype)
        return { "lsp", "treesitter", "indent" }
      end,
    }
    vim.keymap.set("n", "zR", require("ufo").openAllFolds)
    vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
  end,
  }
 
  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)


