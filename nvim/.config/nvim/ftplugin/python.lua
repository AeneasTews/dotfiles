vim.treesitter.start()

vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.wo[0][0].foldmethod = 'expr'

-- No indentexpr here, unlike ftplugin/dart.lua: ftplugins run in the
-- filetypeplugin phase and indent/python.vim runs in the later filetypeindent
-- phase, so anything set here is overwritten. vim-python-pep8-indent supplies
-- the indentexpr instead.
