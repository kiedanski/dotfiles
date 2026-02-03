-- ~/.config/nvim/lua/plugins/undotree.lua
-- Visual undo tree

return {
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  config = function()
    -- Undotree configuration
    vim.g.undotree_WindowLayout = 2          -- Layout: undotree on left, diff on bottom
    vim.g.undotree_SplitWidth = 30           -- Width of undotree window
    vim.g.undotree_DiffpanelHeight = 10      -- Height of diff panel
    vim.g.undotree_SetFocusWhenToggle = 1    -- Focus undotree when opened
    vim.g.undotree_TreeNodeShape = '*'       -- Use * for tree nodes
    vim.g.undotree_TreeVertShape = '|'       -- Use | for tree lines
    vim.g.undotree_TreeSplitShape = '/'      -- Use / for tree splits
    vim.g.undotree_TreeReturnShape = '\\'    -- Use \ for tree returns
    vim.g.undotree_DiffAutoOpen = 1          -- Auto-open diff panel
    vim.g.undotree_HelpLine = 0              -- Hide help line
    vim.g.undotree_ShortIndicators = 1       -- Use short time indicators
    
    -- Enable persistent undo (if not already set)
    if vim.fn.has("persistent_undo") == 1 then
      local undo_dir = vim.fn.expand('~/.local/share/nvim/undo')
      if vim.fn.isdirectory(undo_dir) == 0 then
        vim.fn.mkdir(undo_dir, 'p')
      end
      vim.opt.undodir = undo_dir
      vim.opt.undofile = true
    end
  end,
}
