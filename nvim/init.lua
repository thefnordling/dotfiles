-- Core settings: options, keymaps, filetypes, netrw disabled, yank highlight
require('options')

-- Colorscheme configuration
require('theme')

-- Syntax highlighting and parsing
require('plugins.treesitter')

-- Completion with LSP integration and snippet support
require('plugins.blink')

-- Telescope extensions: search, find, grep, project picker
require('plugins.telescope')

-- Auto-detect indent settings from file content
require('plugins.guess-indent')

-- Auto-close brackets and quotes
require('plugins.autopairs')

-- Git integration: signs, hunk navigation, staging, blame, diff
require('plugins.gitsigns')

-- Keymap prefix helper: shows available commands on leader press
require('plugins.which-key')

-- TODO/FIXME/BUG highlights and navigation
require('plugins.todo-comments')

-- Mini plugins: ai text objects, surround, statusline
require('plugins.mini')

-- Markdown rendering: headings, tables, checkboxes, code blocks
require('plugins.render-markdown')

-- Tmux pane navigation from within Neovim
require('plugins.vim-tmux-navigator')

-- Package manager for LSP servers and formatters
require('plugins.lsp')

-- LSP configuration: rename, references, definitions, code actions
require('plugins.lspconfig')

-- Debug Adapter Protocol: breakpoints, step through, inspect variables
require('plugins.dap')

-- Auto-format code on save and manual formatting
require('plugins.formatters')

-- File browser: filesystem, buffers, git status
require('plugins.neo-tree')

-- OSC52 clipboard: copy to system clipboard via terminal
require('plugins.osc52')
