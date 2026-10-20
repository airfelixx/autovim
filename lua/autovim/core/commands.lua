-- Commands registered here are available from any ordinary Neovim buffer.
local M = {}

function M.setup()
  vim.api.nvim_create_user_command("Open", function()
    require("autovim.workspace").pick()
  end, { desc = "Search for a file or workspace", force = true })
  vim.api.nvim_create_user_command("AutoVim", function()
    require("autovim.dashboard").open()
  end, { desc = "Return to the AutoVim start menu", force = true })
  vim.api.nvim_create_user_command("Workspace", function(opts)
    require("autovim.workspace").open(opts.fargs[1])
  end, { nargs = "?", complete = "dir", desc = "Open a folder as this tab's workspace", force = true })
  vim.api.nvim_create_user_command("OpenFile", function(opts)
    require("autovim.workspace").open_file(opts.fargs[1], false)
  end, { nargs = "?", complete = "file", desc = "Open a file in the current workspace context", force = true })
  vim.api.nvim_create_user_command("Standalone", function(opts)
    require("autovim.workspace").open_file(opts.fargs[1], true)
  end, { nargs = "?", complete = "file", desc = "Open a file without a workspace root", force = true })
end

return M
