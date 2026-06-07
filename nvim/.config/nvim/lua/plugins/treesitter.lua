-- Syntax highlighting and parsing for multiple languages
vim.pack.add({
  'https://github.com/nvim-treesitter/nvim-treesitter',
  -- Auto-close and rename HTML/JSX/TSX tags
  'https://github.com/windwp/nvim-ts-autotag',
})

require('nvim-treesitter.config').setup({
  ensure_installed = {
    'bash',
    'c',
    'diff',
    'html',
    'lua',
    'luadoc',
    'markdown',
    'markdown_inline',
    'query',
    'vim',
    'vimdoc',
    'python',
    'c_sharp',
    'go',
    'typescript',
    'tsx',
    'javascript',
    'json',
    'jsonc',
  },
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = { 'ruby' },
  },
  indent = {
    enable = true,
    disable = { 'ruby' },
  },
})

require('nvim-ts-autotag').setup({
  opts = {
    enable_close = true,
    enable_rename = true,
    enable_close_on_slash = false,
  },
})
