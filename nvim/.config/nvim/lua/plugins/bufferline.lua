vim.pack.add({
  'https://github.com/akinsho/bufferline.nvim',
})

require('bufferline').setup {
  highlights = require('catppuccin.special.bufferline').get_theme(),
  options = {
    close_command = function(bufnum)
      require('mini.bufremove').delete(bufnum, false)
    end,
    right_mouse_command = function(bufnum)
      require('mini.bufremove').delete(bufnum, false)
    end,
    separator_style = 'slant',
    show_buffer_close_icons = true,
    show_close_icon = true,
    color_icons = true,
    offsets = {
      {
        filetype = 'neo-tree',
        text = '󰀊  Neo-Tree',
        text_align = 'left',
        highlight = 'Directory',
        separator = true,
      },
    },

    get_element_icon = function(element)
      local filename = vim.fn.fnamemodify(element.path, ':t')
      local icon, hl = require('nvim-web-devicons').get_icon(filename, element.extension, { default = false })
      return icon, hl
    end,
  },
}

vim.keymap.set('n', '<A-h>', '<cmd>BufferLineCyclePrev<cr>', { desc = 'Buffer: Previous' })
vim.keymap.set('n', '<A-l>', '<cmd>BufferLineCycleNext<cr>', { desc = 'Buffer: Next' })
vim.keymap.set('n', '<leader>bd', function()
  require('mini.bufremove').delete(0, false)
end, { desc = 'Buffer: Delete' })
