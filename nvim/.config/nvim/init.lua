vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Plugins ---
vim.pack.add({
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects', version = 'main' },
  { src = 'https://github.com/rose-pine/neovim', name = 'rose-pine' },
  { src = 'https://github.com/nvim-lua/plenary.nvim' },
  { src = 'https://github.com/nvim-telescope/telescope.nvim' },
  { src = 'https://github.com/Saghen/blink.cmp', version = vim.version.range('1.*') },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/folke/which-key.nvim' },
  { src = 'https://github.com/echasnovski/mini.nvim' },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/folke/todo-comments.nvim' },
})

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name == 'nvim-treesitter' and ev.data.kind == 'update' then
      vim.cmd('TSUpdate')
    end
  end,
})

vim.o.foldlevel = 99

require('nvim-treesitter').install({ 'python' })
require('rose-pine').setup({
  palette = {
    main = { base = '#000000' },
  },
})
vim.cmd('colorscheme rose-pine')

-- LSP ---
vim.lsp.config('*', {
  capabilities = require('blink.cmp').get_lsp_capabilities(),
})
vim.lsp.enable({ 'basedpyright', 'ruff' })

-- Ruff's hover
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == 'ruff' then
      client.server_capabilities.hoverProvider = false
    end
  end,
})

-- Completion ---
require('blink.cmp').setup()

-- Formatting ---
require('conform').setup({
  formatters_by_ft = {
    python = { 'ruff_format' },
  },
})

-- Telescope ---
require('telescope').setup()

vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files)
vim.keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep)
vim.keymap.set('n', '<leader>fb', require('telescope.builtin').buffers)
vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags)

-- Treesitter textobjects ---
-- Bound to `m`/`c` (not `f`/`a`) to avoid clashing with mini.ai's
-- built-in "function call" (f) and "argument" (a) textobjects below.
local ts_select = require('nvim-treesitter-textobjects.select')
vim.keymap.set({ 'x', 'o' }, 'am', function() ts_select.select_textobject('@function.outer', 'textobjects') end)
vim.keymap.set({ 'x', 'o' }, 'im', function() ts_select.select_textobject('@function.inner', 'textobjects') end)
vim.keymap.set({ 'x', 'o' }, 'ac', function() ts_select.select_textobject('@class.outer', 'textobjects') end)
vim.keymap.set({ 'x', 'o' }, 'ic', function() ts_select.select_textobject('@class.inner', 'textobjects') end)

-- Git ---
require('gitsigns').setup()

-- Statusline ---
require('lualine').setup({
  options = { theme = 'rose-pine' },
})

-- Keymap hints ---
require('which-key').setup()

-- mini.nvim modules ---
require('mini.pairs').setup()
require('mini.surround').setup()
require('mini.ai').setup()
require('mini.move').setup()

-- TODO/FIXME/NOTE highlighting ---
require('todo-comments').setup()
