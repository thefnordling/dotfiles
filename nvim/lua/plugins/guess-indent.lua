-- Auto-detect indentation settings from file content
vim.pack.add({
  'https://github.com/NMAC427/guess-indent.nvim',
})

require('guess-indent').setup({
  auto_cmd = true,
  override_editorconfig = false,
  filetype_exclude = { "netrw", "tutor" },
  buftype_exclude = { "help", "nofile", "terminal", "prompt" },
  on_tab_options = { ["expandtab"] = false },
  on_space_options = {
    ["expandtab"] = true,
    ["tabstop"] = "detected",
    ["softtabstop"] = "detected",
    ["shiftwidth"] = "detected",
  },
})
