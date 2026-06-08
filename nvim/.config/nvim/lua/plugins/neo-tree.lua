-- File browser with filesystem and buffers sources
vim.pack.add({
  'https://github.com/nvim-neo-tree/neo-tree.nvim',
  -- File icons for neo-tree
  'https://github.com/nvim-tree/nvim-web-devicons',
  -- UI components for neo-tree
  'https://github.com/MunifTanjim/nui.nvim',
})

require('neo-tree').setup({
  close_if_last_window = false,
  popup_border_style = 'rounded',
  enable_git_status = true,
  enable_diagnostics = true,
  enable_cursorline = true,
  use_popup_filetype_check = true,
  trim_whitespace_on_save = true,
  sort_case_insensitive = true,
  source_selector = {
    winbar = false,
    statusline = false,
  },
  window = {
    position = 'left',
    width = 32,
    reserve_size_of_preview = true,
    mappings = {
      ['<CR>'] = 'open',
      ['l'] = 'open',
      ['h'] = 'close_node',
      ['v'] = 'open_vsplit',
      ['s'] = 'open_split',
      ['q'] = 'close_window',
    },
  },
  filesystem = {
    bind_to_cwd = false,
    follow_current_file = { enabled = true, leave_dirs_open = false },
    use_libuv_file_watcher = true,
    hijack_netrw_behavior = 'open_default',
    filtered_items = {
      hide_dotfiles = false,
      hide_gitignored = false,
    },
  },
  buffers = {
    follow_current_file = { enabled = true },
  },
})

vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle left<CR>', { desc = 'Neo-tree: Toggle' })
vim.keymap.set('n', '<leader>E', '<cmd>Neotree left reveal<CR>', { desc = 'Neo-tree: Focus & Reveal Current File' })
vim.keymap.set('n', '\\', '<cmd>Neotree reveal<CR>', { desc = 'Neo-tree: Reveal' })
vim.keymap.set('n', '<C-n>', '<cmd>Neotree toggle left<CR>', { desc = 'Neo-tree: Toggle' })

vim.cmd [[
  cnoreabbrev <expr> Explore (getcmdtype() == ':' && getcmdline() ==# 'Explore') ? 'Neotree left reveal' : 'Explore'
]]
