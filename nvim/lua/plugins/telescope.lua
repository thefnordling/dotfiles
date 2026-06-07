-- Fuzzy finder: search files, grep, project picker
vim.pack.add({
  'https://github.com/nvim-telescope/telescope.nvim',
  -- Telescope dependency: utility functions for async operations
  'https://github.com/nvim-lua/plenary.nvim',
  -- FZF extension for faster fuzzy matching
  'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
  -- UI select extension for code actions
  'https://github.com/nvim-telescope/telescope-ui-select.nvim',
  -- Project picker extension
  'https://github.com/nvim-telescope/telescope-project.nvim',
  -- Symbols picker extension
  'https://github.com/nvim-telescope/telescope-symbols.nvim',
})

local telescope = require('telescope')
telescope.setup({
  extensions = {
    ['ui-select'] = {
      require('telescope.themes').get_dropdown(),
    },
  },
})

pcall(telescope.load_extension, 'fzf')
pcall(telescope.load_extension, 'ui-select')
pcall(telescope.load_extension, 'project')
pcall(telescope.load_extension, 'symbols')

local builtin = require('telescope.builtin')

vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

vim.keymap.set('n', '<leader>sp', function()
  require('telescope').extensions.project.project({ display_type = 'full' })
end, { desc = '[S]earch [P]rojects' })

vim.keymap.set('n', '<leader>sy', builtin.symbols, { desc = '[S]earch [S]ymbols' })

vim.keymap.set('n', '<leader>sI', function()
  require('telescope.builtin').find_files(require('telescope.themes').get_ivy())
end, { desc = '[S]earch [I]vy theme' })

vim.keymap.set('n', '<leader>sn', function()
  builtin.find_files({ cwd = vim.fn.stdpath('config') })
end, { desc = '[S]earch [N]eovim files' })

vim.keymap.set('n', '<leader>/', function()
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown({
    winblend = 10,
    previewer = false,
  }))
end, { desc = '[/] Fuzzy search in current buffer' })

vim.keymap.set('n', '<leader>s/', function()
  builtin.live_grep({
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  })
end, { desc = '[S]earch [/] in Open Files' })
