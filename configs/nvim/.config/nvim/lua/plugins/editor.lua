return {
  -- Fuzzy finder: files, live grep, etc.
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Grep repo" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers" },
    },
  },
  -- File explorer sidebar
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "File explorer" },
    },
  },
  -- Autocomplete
  { "saghen/blink.cmp", version = "*", opts = { keymap = { preset = "default" } } },
  -- Treesitter highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = { ensure_installed = { "rust", "javascript", "typescript", "php", "lua" }, highlight = { enable = true } },
    config = function(_, opts) require("nvim-treesitter.configs").setup(opts) end,
  },
}
