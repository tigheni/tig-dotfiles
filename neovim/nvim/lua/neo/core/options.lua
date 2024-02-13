-- line numbers
vim.opt.relativenumber = true -- show relative line numbers
vim.opt.number = true -- shows absolute line number on cursor line (when relative number is on)

-- tabs & indentation
vim.opt.tabstop = 2 -- 2 spaces for tabs
vim.opt.shiftwidth = 4 -- 4 spaces for indent width
vim.opt.expandtab = true -- expand tab to spaces
vim.opt.autoindent = true -- copy indent from current line when starting new one

-- line wrapping
vim.opt.wrap = false -- disable line wrapping

-- search settings
vim.opt.ignorecase = true -- ignore case when searching
vim.opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- appearance
vim.opt.background = "dark" -- colorschemes that can be light or dark will be made dark
vim.opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- clipboard
vim.opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
vim.opt.splitright = true -- split vertical window to the right
vim.opt.splitbelow = true -- split horizontal window to the bottom

-- turn off swapfile
vim.opt.swapfile = false

-- Diff view fill characters
vim.opt.fillchars = vim.opt.fillchars + "diff:╱"

-- disable mouse
vim.opt.mouse = ""

-- spelling
vim.opt.spelllang = { "en" }

-- scroll offset
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 40

-- presist undo history
vim.opt.undofile = true
vim.opt.undolevels = 1000

-- auto read file when changed outside of vim
vim.opt.autoread = true

-- disable startup message
vim.opt.shortmess:append("I")
