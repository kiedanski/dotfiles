return {
  'sindrets/diffview.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    require('diffview').setup({
      enhanced_diff_hl = true, -- Better syntax highlighting
      view = {
        default = {
          -- layout = "diff2_horizontal",  -- Side-by-side (default)
          -- OR try:
          layout = "diff2_vertical",  -- Top/bottom split
        },
      },
      file_panel = {
        win_config = {
          width = 25,  -- Make file panel narrower (default is 35)
        },
      },
    })
  end
}
