-- Leader must be set before lazy loads
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Sensible baseline options
vim.opt.number = true
vim.opt.relativenumber = true   -- great for learning motions (3j, 5k)
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.signcolumn = "yes"      -- stops diagnostics from shifting text
vim.opt.termguicolors = true

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")  -- loads everything in lua/plugins/
