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
  -- Rendered markdown, incl. a synced-scroll split preview (:Markview splitToggle).
  { src = 'https://github.com/OXY2DEV/markview.nvim' },
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

require('nvim-treesitter').install({ 'python', 'dart', 'markdown', 'markdown_inline' })
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
    python = { 'ruff_organize_imports', 'ruff_format' },
    -- Explicit (rather than relying on the dartls lsp_format fallback below)
    -- so it works the moment a buffer opens, before dartls finishes attaching.
    dart = { 'dart_format' },
  },
})

-- lsp_format = 'fallback' covers filetypes absent from formatters_by_ft above.
-- <leader>cf, not <leader>f: the latter is the telescope prefix below, and
-- making it a mapping too would stall every <leader>f* binding for 'timeoutlen'.
vim.keymap.set({ 'n', 'x' }, '<leader>cf', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Format buffer/selection' })

-- Route the built-in `gq` operator through conform too.
vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

-- `dart format` (and so conform's dart_format/dartls above) deliberately
-- never rewraps comment prose -- including /// doc comments -- to avoid
-- mangling markdown/code samples inside them. That also means routing `gq`
-- through conform (above) is useless on doc comments: it just reruns
-- `dart format` and diffs, which touches nothing there. For dart buffers,
-- give `gq` back to Neovim's built-in formatter instead: the bundled dart
-- ftplugin already sets 'comments' to recognize `///`/`//` leaders, it just
-- needs 'formatexpr' out of the way and a 'textwidth' to wrap to.
--
-- A plain '' would normally mean "use the internal formatter", but dartls
-- specifically treats an empty formatexpr as unset and stomps it back to
-- v:lua.vim.lsp.formatexpr() on attach (see is_empty_or_default() in
-- $VIMRUNTIME/lua/vim/lsp.lua). So use a function that always defers to the
-- internal formatter (returning 1) instead -- non-empty is enough to make
-- dartls leave it alone.
function _G.__dart_native_formatexpr()
  return 1
end
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'dart',
  callback = function()
    vim.opt_local.formatexpr = 'v:lua.__dart_native_formatexpr()'
    vim.opt_local.textwidth = 80
  end,
})

-- `gqap`/`gqip` reformat the whole paragraph under the cursor, but a dartdoc
-- comment normally sits directly above the thing it documents with no blank
-- line between them -- so "the paragraph" includes the code line right
-- after the comment, and gq drags it into the wrapped text. <leader>cq
-- instead walks up/down from the cursor over contiguous `//`-leader lines
-- only, and wraps just those.
vim.keymap.set('n', '<leader>cq', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local total = vim.api.nvim_buf_line_count(bufnr)
  local function get(l)
    return vim.api.nvim_buf_get_lines(bufnr, l - 1, l, false)[1]
  end
  local function is_comment(l)
    return l >= 1 and l <= total and get(l):match('^%s*//') ~= nil
  end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  if not is_comment(lnum) then
    return vim.notify('Not in a `//` comment', vim.log.levels.WARN)
  end
  local first, last = lnum, lnum
  while is_comment(first - 1) do first = first - 1 end
  while is_comment(last + 1) do last = last + 1 end
  vim.api.nvim_win_set_cursor(0, { first, 0 })
  vim.cmd('normal! V')
  vim.api.nvim_win_set_cursor(0, { last, 0 })
  vim.cmd('normal! gq')
end, { desc = 'Format doc comment block' })

-- Telescope ---
require('telescope').setup()

vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files)
vim.keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep)
vim.keymap.set('n', '<leader>fb', require('telescope.builtin').buffers)
vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags)

-- Grep the source of installed packages, which <leader>fg can't reach: ripgrep
-- skips `.venv` for being a dotdir, and uv writes a `.gitignore` containing `*`
-- inside it, so both --hidden and --no-ignore are needed.
vim.keymap.set('n', '<leader>fd', function()
  local venv = vim.env.VIRTUAL_ENV or vim.fs.joinpath(vim.fn.getcwd(), '.venv')
  local dirs = vim.fn.glob(vim.fs.joinpath(venv, 'lib', 'python*', 'site-packages'), false, true)
  if vim.tbl_isempty(dirs) then
    return vim.notify('No site-packages found under ' .. venv, vim.log.levels.WARN)
  end
  require('telescope.builtin').live_grep({
    search_dirs = dirs,
    additional_args = { '--hidden', '--no-ignore' },
  })
end, { desc = 'Grep installed packages' })

-- Treesitter textobjects ---
-- Bound to `m`/`c` (not `f`/`a`) to avoid clashing with mini.ai's
-- built-in "function call" (f) and "argument" (a) textobjects below.
local ts_select = require('nvim-treesitter-textobjects.select')
vim.keymap.set({ 'x', 'o' }, 'am', function() ts_select.select_textobject('@function.outer', 'textobjects') end)
vim.keymap.set({ 'x', 'o' }, 'im', function() ts_select.select_textobject('@function.inner', 'textobjects') end)
vim.keymap.set({ 'x', 'o' }, 'ac', function() ts_select.select_textobject('@class.outer', 'textobjects') end)
vim.keymap.set({ 'x', 'o' }, 'ic', function() ts_select.select_textobject('@class.inner', 'textobjects') end)

-- Git ---
require('gitsigns').setup({
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')
    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Hunk navigation; falls back to the builtin diff-mode ]c/[c when a
    -- window actually has 'diff' set (e.g. inside :Gitsigns diffthis).
    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({ ']c', bang = true })
      else
        gitsigns.nav_hunk('next')
      end
    end, { desc = 'Next hunk' })
    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({ '[c', bang = true })
      else
        gitsigns.nav_hunk('prev')
      end
    end, { desc = 'Previous hunk' })

    map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'Preview hunk' })
    map('n', '<leader>hd', gitsigns.diffthis, { desc = 'Diff this' })
  end,
})

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

-- Markdown preview ---
-- Renders headings/tables/code blocks/etc. in-buffer via treesitter + text
-- (no image protocol needed). `splitToggle` opens a synced-scroll rendered
-- preview beside the raw source.
require('markview').setup()
vim.keymap.set('n', '<leader>mp', '<cmd>Markview splitToggle<cr>', { desc = 'Markdown preview' })
