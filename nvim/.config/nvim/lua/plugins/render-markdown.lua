-- Render Markdown with headings, tables, checkboxes, code blocks
vim.pack.add({
  'https://github.com/MeanderingProgrammer/render-markdown.nvim',
})

require('render-markdown').setup({
  render_modes = { 'n', 'v' },
  filetypes = { 'markdown' },
  heading = { enabled = true, sign = true, border = true },
  checkbox = { enabled = true, toggle_in_visual = true },
  table = { enabled = true },
  code = { enabled = true, sign = true, language_label = true },
  latex = { enabled = false },
  frontmatter = { enabled = true },
  admonitions = {
    enabled = true,
    types = {
      NOTE = { icon = '', highlight = 'DiagnosticHint' },
      TIP = { icon = '', highlight = 'DiagnosticHint' },
      IMPORTANT = { icon = '', highlight = 'DiagnosticInfo' },
      WARNING = { icon = '', highlight = 'DiagnosticWarn' },
      CAUTION = { icon = '', highlight = 'DiagnosticWarn' },
      DANGER = { icon = '', highlight = 'DiagnosticError' },
    },
    border = 'rounded',
    padding = 1,
    collapse_marker = true,
  },
})
