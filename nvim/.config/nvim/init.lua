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
  -- $VIMRUNTIME/indent/python.vim dates to 2005 and puts continuation lines a
  -- double shiftwidth in, with the closing bracket under the last argument.
  -- This replaces it with PEP8/black layout.
  { src = 'https://github.com/Vimjas/vim-python-pep8-indent' },
  { src = 'https://github.com/lewis6991/gitsigns.nvim' },
  { src = 'https://github.com/nvim-lualine/lualine.nvim' },
  { src = 'https://github.com/folke/which-key.nvim' },
  { src = 'https://github.com/echasnovski/mini.nvim' },
  { src = 'https://github.com/stevearc/conform.nvim' },
  { src = 'https://github.com/folke/todo-comments.nvim' },
  { src = 'https://github.com/nvim-flutter/flutter-tools.nvim' },
  { src = 'https://github.com/folke/snacks.nvim' },
  { src = 'https://github.com/sidlatau/flutter-icons.nvim' },
})

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    if ev.data.spec.name == 'nvim-treesitter' and ev.data.kind == 'update' then
      vim.cmd('TSUpdate')
    end
  end,
})

vim.o.foldlevel = 99

-- Indentation ---
-- Neovim's raw defaults are sw=8/ts=8/noexpandtab, which is what makes Lua,
-- JSON and Dart buffers jump 8 columns per level and insert hard tabs. Python
-- is unaffected either way: $VIMRUNTIME/ftplugin/python.vim forces 4/expandtab.
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.tabstop = 2
vim.o.softtabstop = 2

require('nvim-treesitter').install({ 'python', 'dart' })
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

-- Extend the built-in gr* keymaps with definition/declaration (core leaves
-- these unbound so as to not clobber the legacy gd/gD).
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set('n', 'grd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'grD', vim.lsp.buf.declaration, opts)
  end,
})

-- File explorer (snacks.nvim) ---
-- Also doubles as the image backend for flutter-icons below, hence being
-- configured up here instead of in the Flutter section.
require('snacks').setup({
  image = { enabled = true },
  explorer = {}, -- sidebar tree; replaces netrw
})
vim.keymap.set('n', '<leader>e', function() Snacks.explorer() end, { desc = 'Explorer' })

-- Flutter / Dart ---
-- flutter-tools configures dartls itself; it deliberately isn't wired up
-- through vim.lsp.enable above.
require('flutter-tools').setup({
  fvm = true, -- use <workspace>/.fvm/flutter_sdk when present
  lsp = {
    capabilities = require('blink.cmp').get_lsp_capabilities(),
  },
})
require('flutter-icons').setup()

-- Completion ---
require('blink.cmp').setup({
  keymap = {
    -- <Tab> accepts the selected item; the 'default' preset only uses <Tab>
    -- to jump snippet placeholders. <C-y> accepts under either preset.
    preset = 'super-tab',
  },
  sources = {
    -- renders Icons.*/Symbols.* glyphs inline in completion docs
    transform_items = require('flutter-icons').transform_items,
  },
})

-- Formatting ---
require('conform').setup({
  formatters_by_ft = {
    python = { 'ruff_format' },
  },
})

-- lsp_format = 'fallback' covers filetypes absent from formatters_by_ft above,
-- e.g. Dart, which dartls formats itself.
-- <leader>cf, not <leader>f: the latter is the telescope prefix below, and
-- making it a mapping too would stall every <leader>f* binding for 'timeoutlen'.
vim.keymap.set({ 'n', 'x' }, '<leader>cf', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Format buffer/selection' })

-- Route the built-in `gq` operator through conform too.
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

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
