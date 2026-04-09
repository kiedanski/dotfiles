-- ~/.config/nvim/lua/plugins/lsp.lua
-- Language Server Protocol with UV support

return {
    {
    "williamboman/mason.nvim",
    lazy = true,  -- Add this
    cmd = { "Mason" },  -- Add this
    config = function()
      require("mason").setup({
        ui = { border = "rounded" },
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = true,  -- Add this
    event = { "BufReadPre *.py", "BufNewFile *.py" },  -- Add this
    dependencies = { "mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright" },
        automatic_installation = false,  -- Add this
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason.nvim",
      "mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      -- Function to find Python executable (UV-aware)
      local function get_python_path()
        -- Check for activated virtual environment first
        if vim.env.VIRTUAL_ENV then
          return vim.env.VIRTUAL_ENV .. "/bin/python"
        end
        -- Check for UV project (.venv in current directory)
        local cwd = vim.fn.getcwd()
        local uv_venv = cwd .. "/.venv/bin/python"
        if vim.fn.executable(uv_venv) == 1 then
          return uv_venv
        end
        -- Check parent directories for UV .venv
        local path = vim.fn.expand("%:p:h")
        while path ~= "/" do
          local venv_python = path .. "/.venv/bin/python"
          if vim.fn.executable(venv_python) == 1 then
            return venv_python
          end
          path = vim.fn.fnamemodify(path, ":h")
        end
        -- Fallback to system python
        return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
      end
      -- Check if we're in a UV project
      local function is_uv_project()
        local pyproject = vim.fn.findfile("pyproject.toml", ".;")
        return pyproject ~= ""
      end
      -- Python LSP with UV detection
        vim.lsp.config("pyright", {
        capabilities = capabilities,
        on_new_config = function(new_config, new_root_dir)
          local python_path = get_python_path()
          new_config.settings.python.pythonPath = python_path
        end,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "workspace",
              typeCheckingMode = "basic",
            },
          },
        },
      })
    end,
  },
}
