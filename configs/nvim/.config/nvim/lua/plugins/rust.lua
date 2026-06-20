return {
  -- Wraps rust-analyzer with extra goodies (run/debug, macro expand, etc.)
  -- Install rust-analyzer via rustup: `rustup component add rust-analyzer`
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    ft = "rust",   -- lazy-load only for Rust files
  },
}
