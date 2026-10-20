-- One shell per Neovim tab. Windows are disposable; terminal buffers are not.
local M = {}
local api = vim.api
local sessions = {}

function M.mount(win)
  local tab = api.nvim_get_current_tabpage()
  local session = sessions[tab]
  api.nvim_set_current_win(win)
  if session and api.nvim_buf_is_valid(session.buf) then
    api.nvim_win_set_buf(win, session.buf)
  else
    local buf = api.nvim_create_buf(false, true)
    api.nvim_win_set_buf(win, buf)
    vim.bo[buf].bufhidden = "hide"
    -- cwd is fixed when this shell starts. Reopening never changes a running shell.
    local job = vim.fn.termopen(vim.o.shell, { cwd = require("autovim.workspace").directory() })
    sessions[tab] = { buf = buf, job = job }
  end
  vim.bo.bufhidden = "hide"
  vim.wo.number, vim.wo.relativenumber = false, false
  vim.wo.signcolumn = "no"
  local job = vim.b.terminal_job_id
  if job and vim.fn.jobwait({ job }, 0)[1] == -1 then vim.cmd("startinsert") end
end

-- No jobstop, buffer deletion, or TabClosed cleanup: even a closed tab must
-- not kill its shell. Hidden terminal buffers remain accessible with :ls!.
return M
