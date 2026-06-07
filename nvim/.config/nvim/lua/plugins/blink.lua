vim.pack.add({
  -- Main completion engine with LSP integration
  'https://github.com/saghen/blink.cmp',
  -- Required dependency for blink.cmp
  'https://github.com/saghen/blink.lib',
  -- Snippet support for completion
  'https://github.com/L3MON4D3/LuaSnip',
  -- Lua development support for blink
  'https://github.com/folke/lazydev.nvim',
})

require('blink.cmp').setup({
  keymap = {
    preset = 'default',
  },
  completion = {
    documentation = {
      auto_show = false,
      auto_show_delay_ms = 500,
    },
  },
  sources = {
    default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
    providers = {
      lazydev = {
        module = 'lazydev.integrations.blink',
        score_offset = 100,
      },
    },
  },
  snippets = {
    preset = 'luasnip',
  },
  fuzzy = {
    implementation = 'lua',
  },
  signature = {
    enabled = true,
  },
})
