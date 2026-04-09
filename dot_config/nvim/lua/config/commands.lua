

-- Better formatted version
vim.api.nvim_create_user_command('MakeConfig', function()
  local lines = {
    '{',
    '  "venvPath": ".",',
    '  "venv": ".venv",',
    '  "typeCheckingMode": "basic",',
    '  "useLibraryCodeForTypes": true,',
    '  "autoSearchPaths": true',
    '}'
  }
  
  vim.fn.writefile(lines, 'pyrightconfig.json')
  print("✅ Created pyrightconfig.json")
end, { desc = "Create pyrightconfig.json" })

-- Timestamp abbreviation: type ;ts in insert mode to expand to current datetime
vim.cmd([[iab <expr> _ts strftime("%F %b %T")]])
