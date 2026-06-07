-- Auto-close brackets and quotes
vim.pack.add({
  'https://github.com/windwp/nvim-autopairs',
})

require('nvim-autopairs').setup({
  check_ts = true,
  ts_config = {
    lua = { 'treesitter' },
    javascript = { 'treesitter' },
    typescript = { 'treesitter' },
  },
})
