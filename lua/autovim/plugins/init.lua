-- Bootstrap only the manager here. Plugin choices and options live in specs.lua.
local M = {}

function M.setup()
  local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.uv.fs_stat(path .. "/lua/lazy/init.lua") then
    local output = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
      "https://github.com/folke/lazy.nvim.git", path })
    if vim.v.shell_error ~= 0 then error("Could not install lazy.nvim:\n" .. output) end
  end
  vim.opt.rtp:prepend(path)
  require("lazy").setup(require("autovim.plugins.specs"), {
    defaults = { lazy = true },
    lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
    install = { colorscheme = { "autovim" } },
    checker = { enabled = false },
    change_detection = { notify = false },
    rocks = { enabled = false },
    performance = { rtp = { reset = false } },
  })
end

return M
