-- Clipboard integration via OSC52 terminal protocol
vim.pack.add({
  'https://github.com/ojroques/nvim-osc52',
})

require('osc52').setup({
  max_length = 0,
  silent = false,
  trim = false,
})

local function copy(lines, _)
  require('osc52').copy(table.concat(lines, '\n'))
end

local function paste()
  return { vim.fn.getreg '', vim.fn.getregtype '' }
end

vim.g.clipboard = {
  name = 'osc52',
  copy = { ['+'] = copy, ['*'] = copy },
  paste = { ['+'] = paste, ['*'] = paste },
}

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Copy to clipboard on yank',
  group = vim.api.nvim_create_augroup('osc52-yank', { clear = true }),
  callback = function()
    if vim.v.event.operator == 'y' and vim.v.event.regname == '' then
      require('osc52').copy_register('')
    end
  end,
})
