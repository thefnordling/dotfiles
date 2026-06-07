-- Mini plugins: ai text objects, surround pairs, statusline
vim.pack.add({
  'https://github.com/echasnovski/mini.nvim',
})

require('mini.ai').setup({ n_lines = 500 })
require('mini.surround').setup()

local statusline = require('mini.statusline')
statusline.setup({ use_icons = vim.g.have_nerd_font })
statusline.section_location = function()
  return '%2l:%-2v'
end
