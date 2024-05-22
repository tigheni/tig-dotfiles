-- set leader key to space
vim.g.mapleader = " "

-- close all open buffers
vim.keymap.set("n", "<leader>b", "<cmd>%bd<cr>", { desc = "Close all open buffers" })

-- navigation
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<M-l>", "30lzszH")
vim.keymap.set("n", "<M-h>", "30hzszH")

-- Copy relatve path to clipboard
vim.keymap.set("n", "<leader>p", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
end, { expr = true, desc = "Copy relative path" })

-- Move Lines
vim.keymap.set("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
vim.keymap.set("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
vim.keymap.set("v", "<A-j>", "<cmd>m '>+1<cr>gv=gv", { desc = "Move down" })
vim.keymap.set("v", "<A-k>", "<cmd>m '<-2<cr>gv=gv", { desc = "Move up" })

-- Clear search with <esc>
vim.keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- save file
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>update<cr><esc>", { desc = "Save file" })

-- lazy
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- quit
vim.keymap.set("n", "<leader>q", "<cmd>qa<cr>", { desc = "Quit" })
vim.keymap.set("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit Without saving" })
vim.keymap.set("n", "<leader>W", "<cmd>wqa<cr>", { desc = "Save all buffers" })
vim.keymap.set("n", "<leader>w", "<cmd>wa<cr>", { desc = "Save all buffers and quit" })

-- Duplicate visual selection and comment a copy out
vim.keymap.set(
  "v",
  "<leader>gc",
  [[y`>pgv:norm gcc<CR>`>j^]],
  { desc = "Duplicate and comment a copy out", silent = true }
)

-- Search and replace
vim.keymap.set("n", "<leader>S", ":%s//g<left><left>", { desc = "Search and replace" })
vim.keymap.set("x", "<leader>S", ":s//g<left><left>", { desc = "Search and replace" })

-- Select in visual line mode using matchit
vim.keymap.set("n", "<leader>k", "$V%")

-- Swap p and P in visual mode
vim.keymap.set("x", "p", "P")
vim.keymap.set("x", "P", "p")

-- Move to start/end of line
vim.keymap.set({ "n", "x" }, "H", "^")
vim.keymap.set({ "n", "x" }, "L", "$")

-- quickfix list
vim.keymap.set("n", "<c-p>", "<cmd>cprevious<cr>", { desc = "Previous quickfix" })
vim.keymap.set("n", "<c-n>", "<cmd>cnext<cr>", { desc = "Next quickfix" })
vim.keymap.set("n", "<leader>v", function()
  vim.cmd(vim.fn.getqflist({ winid = 0 }).winid > 0 and "cclose" or "copen")
end, { silent = true })

vim.keymap.set("n", "g*", "*Ncgn", { desc = "Change word with . repeat" })
