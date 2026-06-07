-- Package manager for LSP servers and formatters
vim.pack.add({
  'https://github.com/mason-org/mason.nvim',
  -- Bridges mason and nvim-lspconfig for auto-installation
  'https://github.com/williamboman/mason-lspconfig.nvim',
  -- Auto-installs packages from ensure_installed list
  'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
  -- LSP progress/status indicator
  'https://github.com/j-hui/fidget.nvim',
  -- Linting integration with LSP diagnostics
  'https://github.com/mfussenegger/nvim-lint',
})

require('mason').setup({
  ui = {
    border = 'rounded',
    icons = {
      package_installed = '✓',
      package_pending = '➜',
      package_uninstalled = '✗',
    },
  },
  log_level = vim.log.levels.INFO,
  max_concurrent_installers = 4,
})

local ensure_installed = {
  -- LSP servers
  'pyright',
  'typescript-language-server',
  'gopls',
  'roslyn-language-server',
  'html-lsp',
  'css-lsp',
  'json-lsp',
  'yaml-language-server',
  'taplo',
  'bash-language-server',

  -- DAP adapters
  'debugpy',
  'js-debug-adapter',
  'netcoredbg',
  'delve',

  -- Formatters (discovered by conform)
  'prettier',
  'stylua',
  'taplo',
  'ruff',
  'csharpier',
  'shfmt',

  -- Linters (discovered by nvim-lint)
  'ruff',
  'shellcheck',
  'eslint_d',
  'markdownlint',
}

require('mason-tool-installer').setup({
  ensure_installed = ensure_installed,
  auto_update = false,
  run_on_start = true,
  start_delay = 0,
  popup_notification = true,
})

require('mason-lspconfig').setup({
  automatic_installation = true,
})

require('fidget').setup({})

local lint = require('lint')
lint.linters_by_ft = {
  typescript = { 'eslint_d' },
  typescriptreact = { 'eslint_d' },
  javascript = { 'eslint_d' },
  javascriptreact = { 'eslint_d' },
  python = { 'ruff' },
  sh = { 'shellcheck' },
  bash = { 'shellcheck' },
  zsh = { 'shellcheck' },
  markdown = { 'markdownlint' },
}

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  callback = function()
    if vim.bo.modifiable then
      lint.try_lint()
    end
  end,
})

-- TS-specific LSP keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('ts-keymaps', { clear = true }),
  callback = function(event)
    local bufnr = event.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map('n', '<leader>co', function()
      vim.lsp.buf.code_action({
        apply = true,
        filter = function(action)
          return action.kind == 'source.organizeImports'
        end,
      })
    end, 'TS: [O]rganize Imports')

    map('n', '<leader>ci', function()
      vim.lsp.buf.code_action({
        apply = true,
        filter = function(action)
          return action.kind == 'source.addMissingImports'
        end,
      })
    end, 'TS: Add [I]mports')

    map('n', '<leader>cf', function()
      vim.lsp.buf.code_action({
        apply = true,
        filter = function(action)
          return action.kind == 'source.fixAll'
        end,
      })
    end, 'TS: [F]ix All')
  end,
})
