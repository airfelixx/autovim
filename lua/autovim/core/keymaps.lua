local M = {}

function M.setup()
  -- Editor and terminal shortcuts call the same action, with different keys.
  local function bind(normal, terminal, action, description)
    local function run()
      if require("autovim.explorer.picker").active() then return end
      action()
    end
    vim.keymap.set("n", normal, run, { desc = description, silent = true })
    vim.keymap.set("t", terminal, run, { desc = description, silent = true, nowait = true })
  end
  -- Keep Space literal in terminal input mode: no leader-prefix timeout.
  -- Delete the previous mappings too, so rerunning setup updates live sessions.
  pcall(vim.keymap.del, "t", "<leader><Tab>")
  pcall(vim.keymap.del, "t", "<leader>\\")
  for _, tool in ipairs({
    { "<leader><Tab>", "<C-Tab>", "explorer", "Toggle workspace file tree" },
    { "<leader>\\", "<C-\\>", "terminal", "Toggle persistent terminal" },
    { "<leader>u", "<C-u>", "undo", "Toggle undo history" },
    { "<leader>h", "<C-h>", "harpoon", "Toggle Harpoon list" },
  }) do
    bind(tool[1], tool[2], function() require("autovim.sidebar").toggle(tool[3]) end, tool[4])
  end
  bind("<leader>a", "<C-a>", function()
    require("autovim.harpoon").add()
  end, "Add file to Harpoon")
  for key, direction in pairs({ Left = "h", Down = "j", Up = "k", Right = "l" }) do
    bind("<leader><" .. key .. ">", "<C-" .. key .. ">", function()
      vim.cmd("wincmd " .. direction)
    end, "Move to the " .. key:lower() .. " pane")
  end
  for number = 1, 9 do
    bind("<leader>" .. number, "<C-" .. number .. ">", function()
      require("autovim.harpoon").select_number(number)
    end, "Open Harpoon file " .. number)
  end
end

return M
