vim.pack.add({
  { src = 'https://github.com/catppuccin/nvim', name = 'catppuccin' },
})
vim.opt.termguicolors = true -- 24-bit true color

require('catppuccin').setup({
  flavour = 'mocha',
  integrations = {
    gitsigns = true,
    treesitter = true,
    telescope = true,
    render_markdown = true,
  },
})

vim.cmd.colorscheme('catppuccin-mocha')
