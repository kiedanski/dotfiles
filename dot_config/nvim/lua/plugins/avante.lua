-- ~/.config/nvim/lua/plugins/avante.lua
-- AI coding assistant

return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false,
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = { insert_mode = true },
          use_absolute_path = true,
        },
      },
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = { file_types = { "markdown", "Avante" } },
      ft = { "markdown", "Avante" },
    },
  },
  config = function()
    require("avante").setup({
      -- Provider configuration (modern format)
      provider = "claude-code", -- "claude", "openai", "copilot"
      auto_suggestions = false,
      acp_providers = {
        ["claude-code"] = {
            command = "npx",
            args = { "@zed-industries/claude-code-acp" },
            env = {
                NODE_NO_WARNINGS = "1",
                ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY"),
            },
        }
      },
      providers = {
        ollama = {
          endpoint = "http://localhost:11434",
          model = "llama3.1:8b",
        },
      },
      -- Behavior
      behaviour = {
        auto_suggestions = false,
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = false,
        auto_approve_tool_permissions = false,
      },
      -- Window settings
      windows = {
        position = "right",
        wrap = true,
        width = 30,
        sidebar_header = {
          align = "center",
          rounded = true,
        },
      },
      -- Hints
      hints = { enabled = true },
    })
  end,
}
