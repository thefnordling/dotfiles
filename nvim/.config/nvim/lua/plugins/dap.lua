-- Debug Adapter Protocol: packages for debugging
vim.pack.add({
  -- Debug Adapter Protocol client
  'https://github.com/mfussenegger/nvim-dap',
  -- DAP UI components
  'https://github.com/rcarriga/nvim-dap-ui',
  -- Async utilities for DAP
  'https://github.com/nvim-neotest/nvim-nio',
  -- Virtual text for DAP variable inspection
  'https://github.com/theHamsta/nvim-dap-virtual-text',
})

local dap = require('dap')
local dapui = require('dapui')

dapui.setup({
  layouts = {
    {
      elements = {
        { id = 'scopes', size = 0.25 },
        { id = 'breakpoints', size = 0.25 },
        { id = 'stacks', size = 0.25 },
        { id = 'watches', size = 0.25 },
      },
      size = 0.33,
      position = 'left',
    },
    {
      elements = {
        { id = 'repl', size = 0.45 },
        { id = 'console', size = 0.55 },
      },
      size = 0.27,
      position = 'bottom',
    },
  },
})

require('nvim-dap-virtual-text').setup({
  commented = true,
  highlight_changed_variables = true,
  highlight_new_as_changed = true,
  virt_text_pos = 'eol',
})

vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError', priority = 50 })
vim.fn.sign_define('DapBreakpointCondition', { text = '◐', texthl = 'DiagnosticWarn', priority = 50 })
vim.fn.sign_define('DapBreakpointRejected', { text = '○', texthl = 'DiagnosticHint', priority = 50 })
vim.fn.sign_define('DapLogPoint', { text = '◆', texthl = 'DiagnosticInfo', priority = 50 })
vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DiagnosticInfo', linehl = 'Visual', priority = 60 })

dap.listeners.after.event_initialized['dapui_config'] = function()
  pcall(vim.cmd, 'Neotree left close')
  pcall(vim.cmd, 'Neotree right toggle')
  dapui.open()
end
dap.listeners.before.event_terminated['dapui_config'] = function()
  dapui.close()
end
dap.listeners.before.event_exited['dapui_config'] = function()
  dapui.close()
  pcall(vim.cmd, 'Neotree right close')
  pcall(vim.cmd, 'Neotree left toggle')
end

local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = 'DAP: ' .. desc })
end

map('<F5>', function()
  if dap.session() then
    dap.continue()
  else
    dap.continue()
  end
end, 'Continue/Start')
map('<F9>', dap.toggle_breakpoint, 'Toggle Breakpoint')
map('<F10>', dap.step_over, 'Step Over')
map('<F11>', dap.step_into, 'Step Into')
map('<S-F11>', dap.step_out, 'Step Out')

map('<leader>db', dap.toggle_breakpoint, 'Toggle Breakpoint')
map('<leader>dB', function()
  dap.set_breakpoint(vim.fn.input('Condition: '))
end, 'Conditional Breakpoint')
map('<leader>dl', function()
  dap.set_breakpoint(nil, nil, vim.fn.input('Log: '))
end, 'Log Point')
map('<leader>dr', dap.repl.open, 'REPL')
map('<leader>du', dapui.toggle, 'Toggle UI')
map('<leader>de', function()
  dap.evaluate()
end, 'Evaluate')
map('<leader>dh', function()
  require('dap.ui.widgets').hover()
end, 'Hover Inspect')
map('<leader>dC', dap.run_to_cursor, 'Run to Cursor')
map('<leader>dS', dap.terminate, 'Stop')
map('<leader>dR', dap.restart, 'Restart')

vim.keymap.set('v', '<leader>de', function()
  require('dap.ui.widgets').hover()
end, { desc = 'DAP: Evaluate selection' })

local function get_mason_path(package, executable)
  local path = vim.fn.stdpath('data') .. '/mason/packages/' .. package .. '/' .. (executable or package)
  if vim.fn.executable(path) == 1 then
    return path
  end
  return nil
end

local debugpy_path = get_mason_path('debugpy', 'venv/bin/python') or 'python3'
dap.adapters.python = {
  type = 'executable',
  command = debugpy_path,
  args = { '-m', 'debugpy.adapter' },
}

dap.configurations.python = {
  {
    type = 'python',
    request = 'launch',
    name = 'Launch file',
    program = '${file}',
    pythonPath = function()
      return vim.env.VIRTUAL_ENV and (vim.env.VIRTUAL_ENV .. '/bin/python') or 'python3'
    end,
  },
  {
    type = 'python',
    request = 'launch',
    name = 'Launch file with venv',
    program = '${file}',
    pythonPath = function()
      local venv = vim.fn.finddir('venv', vim.fn.getcwd() .. ';')
      if venv ~= '' then
        return venv .. '/bin/python'
      end
      venv = vim.fn.finddir('.venv', vim.fn.getcwd() .. ';')
      if venv ~= '' then
        return venv .. '/bin/python'
      end
      return 'python3'
    end,
  },
  {
    type = 'python',
    request = 'launch',
    name = 'Pytest debug current file',
    module = 'pytest',
    args = { '${file}', '-v', '-s' },
    cwd = '${workspaceFolder}',
  },
  {
    type = 'python',
    request = 'launch',
    name = 'Pytest debug at cursor',
    module = 'pytest',
    args = { '-v', '-s', vim.fn.expand('%:$<SLINE>') },
    cwd = '${workspaceFolder}',
  },
}

local netcoredbg_path = vim.fn.stdpath('data') .. '/mason/packages/netcoredbg/libexec/netcoredbg/netcoredbg'
if vim.fn.executable(netcoredbg_path) == 1 then
  dap.adapters.coreclr = {
    type = 'executable',
    command = netcoredbg_path,
    args = { '--interpreter=vscode' },
  }
else
  dap.adapters.coreclr = {
    type = 'executable',
    command = 'netcoredbg',
    args = { '--interpreter=vscode' },
  }
end

dap.configurations.cs = {
  {
    type = 'coreclr',
    request = 'launch',
    name = 'Build and Launch',
    program = function()
      local csproj = vim.fn.glob('*.csproj')
      if csproj == '' then
        return vim.fn.input('Path to DLL: ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
      end

      local name = vim.fn.fnamemodify(csproj, ':t:r')
      local dll = vim.fn.glob(vim.fn.getcwd() .. '/bin/Debug/net' .. '*/' .. name .. '.dll')
      if dll ~= '' then
        return dll
      end

      return vim.fn.input('DLL path: ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
    end,
  },
}

local dlv_path = get_mason_path('delve', 'dlv') or 'dlv'
dap.adapters.delve = {
  type = 'server',
  port = '${port}',
  executable = {
    command = dlv_path,
    args = { 'dap', '-l', '127.0.0.1:${port}' },
  },
}

dap.configurations.go = {
  {
    type = 'delve',
    request = 'launch',
    name = 'Debug file',
    program = '${file}',
  },
  {
    type = 'delve',
    request = 'launch',
    name = 'Debug package',
    program = '${fileDirname}',
  },
  {
    type = 'delve',
    request = 'launch',
    name = 'Debug test',
    mode = 'test',
    program = '${fileDirname}',
  },
  {
    type = 'delve',
    request = 'attach',
    name = 'Attach to process',
    program = '${file}',
  },
}

dap.configurations.javascript = {
  {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch Node.js Program',
    program = '${file}',
    cwd = '${workspaceFolder}',
  },
  {
    type = 'pwa-node',
    request = 'attach',
    name = 'Attach to Node Process',
    port = 9229,
    restart = true,
    skipFiles = { '<node_internals>/**' },
  },
  {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch Jest Test',
    runtimeExecutable = 'node',
    runtimeArgs = { '${workspaceFolder}/node_modules/.bin/jest', '${file}', '--runInBand' },
    cwd = '${workspaceFolder}',
    console = 'integratedTerminal',
  },
}

dap.configurations.typescript = {
  {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch TypeScript Program',
    program = '${file}',
    cwd = '${workspaceFolder}',
    resolveSourceMapLocations = {
      '${workspaceFolder}/**',
      '!**/node_modules/**',
    },
  },
  {
    type = 'pwa-node',
    request = 'attach',
    name = 'Attach to Node Process',
    port = 9229,
    restart = true,
    skipFiles = { '<node_internals>/**' },
  },
  {
    type = 'pwa-node',
    request = 'launch',
    name = 'Launch Jest Test (TS)',
    runtimeExecutable = 'node',
    runtimeArgs = { '${workspaceFolder}/node_modules/.bin/jest', '${file}', '--runInBand' },
    cwd = '${workspaceFolder}',
    console = 'integratedTerminal',
  },
}

local jsdebug_adapter_path = vim.fn.stdpath('data') .. '/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js'
if vim.fn.filereadable(jsdebug_adapter_path) == 1 then
  dap.adapters['pwa-node'] = {
    type = 'server',
    port = 9876,
    executable = {
      command = 'node',
      args = { jsdebug_adapter_path, '${port}' },
    },
  }
else
  dap.adapters['pwa-node'] = {
    type = 'executable',
    command = 'node',
    args = { vim.fn.stdpath('data') .. '/mason/packages/js-debug-adapter/js-debug-adapter', '${port}' },
  }
end

dap.configurations['javascriptreact'] = dap.configurations.javascript
dap.configurations['typescriptreact'] = dap.configurations.typescript
