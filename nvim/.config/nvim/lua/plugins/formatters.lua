-- Code formatter with auto-format on save and manual formatting
vim.pack.add({
  'https://github.com/stevearc/conform.nvim',
})

require('conform').setup({
  notify_on_error = false,
  format_on_save = function(bufnr)
    local disable_filetypes = { c = true, cpp = true }
    if disable_filetypes[vim.bo[bufnr].filetype] then
      return nil
    else
      return {
        timeout_ms = 500,
        lsp_format = 'fallback',
      }
    end
  end,
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'ruff_format' },
    cs = { 'csharpier' },
    typescript = { 'prettier' },
    typescriptreact = { 'prettier' },
    javascript = { 'prettier' },
    javascriptreact = { 'prettier' },
    json = { 'prettier' },
    jsonc = { 'prettier' },
    markdown = { 'prettier' },
    html = { 'prettier' },
    yaml = { 'prettier' },
    css = { 'prettier' },
    scss = { 'prettier' },
    toml = { 'taplo' },
    go = { 'goimports' },
    sh = { 'shfmt' },
    bash = { 'shfmt' },
    zsh = { 'shfmt' },
  },
})

vim.keymap.set('n', '<leader>f', function()
  require('conform').format { async = true, lsp_format = 'fallback' }
end, { desc = '[F]ormat buffer' })
