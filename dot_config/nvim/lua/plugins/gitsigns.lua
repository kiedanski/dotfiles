return {
  'lewis6991/gitsigns.nvim',
  config = function()
    require('gitsigns').setup({
      signs = {
        add          = { text = '▎' },
        change       = { text = '▎' },
        delete       = { text = '契' },
        topdelete    = { text = '契' },
        changedelete = { text = '▎' },
        untracked    = { text = '┆' },
      },
      signcolumn = true,
      numhl = true,  -- Highlight line numbers - very visible!
      linehl = false,
      word_diff = true,
      show_deleted = true,
      current_line_blame = true,  -- Shows who/when changed current line
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol',
        delay = 500,
        ignore_whitespace = false,
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        -- Navigation
        vim.keymap.set('n', ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, {expr=true, buffer=bufnr, desc='Next hunk'})
        vim.keymap.set('n', '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, {expr=true, buffer=bufnr, desc='Previous hunk'})
        -- Actions
        vim.keymap.set('n', '<leader>hp', gs.preview_hunk, {buffer=bufnr, desc='Preview hunk'})
        vim.keymap.set('n', '<leader>hs', gs.stage_hunk, {buffer=bufnr, desc='Stage hunk'})
        vim.keymap.set('n', '<leader>hr', gs.reset_hunk, {buffer=bufnr, desc='Reset hunk'})
        vim.keymap.set('n', '<leader>hu', gs.undo_stage_hunk, {buffer=bufnr, desc='Undo stage'})
        vim.keymap.set('n', '<leader>hb', gs.blame_line, {buffer=bufnr, desc='Blame line'})
      end
    })
  end
}
