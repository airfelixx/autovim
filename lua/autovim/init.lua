local M = {}

function M.setup()
  require("autovim.core.options").setup()
  vim.cmd.colorscheme("autovim")
  require("autovim.plugins").setup()
  require("autovim.lsp").setup()
  require("autovim.workspace").setup()
  require("autovim.explorer").setup()
  require("autovim.sidebar").setup()
  require("autovim.ui").setup()
  require("autovim.dashboard").setup()
  require("autovim.core.commands").setup()
  require("autovim.core.keymaps").setup()
end

return M
