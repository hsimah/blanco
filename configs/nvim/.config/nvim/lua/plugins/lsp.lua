return {
  -- Installs language servers for you (:Mason to browse)
  { "williamboman/mason.nvim", config = true },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "neovim/nvim-lspconfig" },
    opts = {
      -- rust handled by rustaceanvim below, so not listed here.
      -- ts_ls (JS/TS) and intelephense (PHP) are npm packages and need
      -- Node installed first. Add them back here once you're doing JS/PHP:
      --   sudo pacman -S nodejs npm
      --   ensure_installed = { "ts_ls", "intelephense" }
      ensure_installed = {},
    },
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Navigation keymaps, active in any buffer with an LSP attached
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local map = function(keys, fn) vim.keymap.set("n", keys, fn, { buffer = ev.buf }) end
          map("gd", vim.lsp.buf.definition)      -- go to definition
          map("gr", vim.lsp.buf.references)      -- find references
          map("K",  vim.lsp.buf.hover)           -- show type / docs
          map("<leader>rn", vim.lsp.buf.rename)  -- rename symbol
          map("<leader>ca", vim.lsp.buf.code_action)
          map("[d", vim.diagnostic.goto_prev)    -- prev error
          map("]d", vim.diagnostic.goto_next)    -- next error
        end,
      })
    end,
  },
}
