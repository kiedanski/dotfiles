-- ~/.config/nvim/lua/plugins/iron.lua
-- Modern REPL integration

return {
  "Vigemus/iron.nvim",
  keys = {
    { "<leader>rs", "<cmd>IronRepl<cr>", desc = "Start REPL" },
    { "<leader>rr", "<cmd>IronRestart<cr>", desc = "Restart REPL" },
    { "<leader>rf", "<cmd>IronFocus<cr>", desc = "Focus REPL" },
    { "<leader>rh", "<cmd>IronHide<cr>", desc = "Hide REPL" },
  },
  config = function()
    local iron = require("iron.core")
    local view = require("iron.view")
    
    iron.setup({
      config = {
        -- Whether a repl should be discarded or not
        scratch_repl = true,
        
        -- Your repl definitions
        repl_definition = {
          python = {
            command = { "uv", "run", "ipython", "--no-autoindent" },
            format = require("iron.fts.common").bracketed_paste_python,
            block_dividers = { "# %%", "#%%" },
            env = {PYTHON_BASIC_REPL = "1"} --this is needed for python3.13 and up.
          },
          lua = {
            command = { "lua" }
          },
        },
        -- set the file type of the newly created repl to ft
        -- bufnr is the buffer id of the REPL and ft is the filetype of the 
        -- language being used for the REPL. 
        repl_filetype = function(bufnr, ft)
          return ft
          -- or return a string name such as the following
          -- return "iron"
        end,
        
        -- How the repl window will be displayed
        -- Try different layouts:
        repl_open_cmd = view.split.vertical.botright(100), -- Right side, 50% width
        -- repl_open_cmd = view.split.horizontal.botright(30), -- Bottom, 30% height
        -- repl_open_cmd = view.split("40%"), -- Right side, 40% width
        
        -- Automatically close repl on process end
        close_window_on_exit = true,
      },
      
      -- Keymaps - Iron doesn't set these by default anymore
      keymaps = {
        send_motion = "<leader>sc",      -- Send motion (e.g., <leader>scip for paragraph)
        visual_send = "<leader>s",       -- Send visual selection
        send_file = "<leader>sf",        -- Send entire file
        send_line = "<leader>ss",        -- Send current line
        send_until_cursor = "<leader>su", -- Send from start to cursor
        send_mark = "<leader>sm",        -- Send marked region
        mark_motion = "<leader>mc",      -- Mark motion
        mark_visual = "<leader>mv",      -- Mark visual selection
        remove_mark = "<leader>md",      -- Remove mark
        cr = "<leader>s<cr>",           -- Send carriage return
        interrupt = "<leader>s<space>", -- Interrupt REPL
        exit = "<leader>sq",            -- Exit REPL
        clear = "<leader>sl",           -- Clear REPL
      },
      
      -- Highlight sent code
      highlight = {
        italic = true,
        bold = false,
      },
      
      -- Ignore blank lines when sending visual selections
      ignore_blank_lines = true,
    })
  end,
}
