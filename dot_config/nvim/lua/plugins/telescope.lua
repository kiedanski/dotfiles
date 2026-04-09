-- ~/.config/nvim/lua/plugins/telescope.lua
-- File finder

return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("telescope").setup({
      defaults = {
        prompt_prefix = "🔍 ",
        selection_caret = "➤ ",
        file_ignore_patterns = {
          "%.git/",
          "__pycache__/",
          "%.pyc",
          ".venv/",
          "node_modules/",
        },
      },
    })
  end,
}
