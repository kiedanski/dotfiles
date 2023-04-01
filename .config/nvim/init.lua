require "plugins"
require "lsp"
require "autocomplete"
require "user.keybinds"


vim.g.slime_target = "tmux"
vim.g["slime_default_config"] = {socket_name = "default", target_pane = "{last}"}
