local function get_python_path(workspace)
  -- 1. An explicitly activated venv always wins.
  if vim.env.VIRTUAL_ENV then
    return vim.fs.joinpath(vim.env.VIRTUAL_ENV, 'bin', 'python')
  end

  -- 2. uv's default: .venv in the project root.
  if workspace then
    local venv = vim.fs.joinpath(workspace, '.venv', 'bin', 'python')
    if vim.uv.fs_stat(venv) then
      return venv
    end
  end

  -- 3. Fall back to system python.
  return vim.fn.exepath('python3')
end

local function set_python_path(command)
  local clients = vim.lsp.get_clients({
    bufnr = vim.api.nvim_get_current_buf(),
    name = 'basedpyright',
  })
  for _, client in ipairs(clients) do
    client.settings = vim.tbl_deep_extend('force', client.settings or {}, {
      python = { pythonPath = command.args },
    })
    client:notify('workspace/didChangeConfiguration', { settings = nil })
  end
end

---@type vim.lsp.Config
return {
  cmd = { 'basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyrightconfig.json',
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  },
  settings = {
    basedpyright = {
      disableOrganizeImports = true, -- ruff owns imports
      disableTaggedHints = true,
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = 'openFilesOnly',
      },
    },
  },
  before_init = function(_, config)
    config.settings = config.settings or {}
    config.settings.python = config.settings.python or {}
    config.settings.python.pythonPath = get_python_path(config.root_dir)
  end,
  on_attach = function(_, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightSetPythonPath', set_python_path, {
      desc = 'Point basedpyright at a specific python interpreter',
      nargs = 1,
      complete = 'file',
    })
  end,
}
