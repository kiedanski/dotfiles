require "plugins"
require "lsp"
require "autocomplete"


vim.g.slime_target = "tmux"
vim.g["slime_default_config"] = {socket_name = "default", target_pane = "{last}"}

-- Set background color for folded regions
vim.cmd('highlight Folded guibg=DarkGrey guifg=White')

-- Set the character used to separate folded regions
vim.o.fillchars = 'fold:─'

