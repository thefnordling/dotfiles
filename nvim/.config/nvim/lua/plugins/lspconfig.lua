-- LSP client configuration: rename, references, definitions, code actions
vim.pack.add({
  'https://github.com/neovim/nvim-lspconfig',
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
    map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')
    map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
    map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight') then
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = vim.api.nvim_create_augroup('lsp-highlight', { clear = false }),
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = vim.api.nvim_create_augroup('lsp-highlight', { clear = false }),
        callback = vim.lsp.buf.clear_references,
      })
    end

    if client and client:supports_method('textDocument_inlayHint') then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})

vim.lsp.config('pyright', {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = 'standard',
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})

vim.lsp.config('ts_ls', {
  settings = {
    typescript = {
      inlayHints = {
        functionParameters = true,
        variableTypes = true,
        parameterTypes = true,
        propertyDeclarationTypes = true,
      },
      format = {
        insertSpaceAfterFunctionKeywordForAnonymousFunctions = true,
        insertSpaceAfterOpeningAndBeforeClosingNonemptyParenthesis = true,
      },
    },
    javascript = {
      inlayHints = {
        functionParameters = true,
        variableTypes = true,
        parameterTypes = true,
        propertyDeclarationTypes = true,
      },
    },
  },
})

vim.lsp.config('gopls', {
  settings = {
    gopls = {
      analyses = {
        unusedparams = true,
        shadow = true,
      },
      staticcheck = true,
      gofumpt = true,
    },
  },
})

vim.lsp.config('roslyn', {
  settings = {
    ['dotnet.codeAnalysis.ignoredDiagnostics'] = {},
  },
})

vim.lsp.config('html', {})
vim.lsp.config('cssls', {})
vim.lsp.config('jsonls', {})
vim.lsp.config('yamlls', {})
vim.lsp.config('taplo', {})
vim.lsp.config('bashls', {})
vim.lsp.config('lua_ls', {
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' },
      },
      workspace = {
        checkThirdParty = false,
      },
    },
  },
})
vim.lsp.config('emmet_ls', {})

vim.diagnostic.config({
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  signs = true,
  underline = true,
  update_in_insert = false,
  virtual_text = {
    source = 'if_many',
    spacing = 4,
  },
})
