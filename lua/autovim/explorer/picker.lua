-- Telescope selection scope: fuzzy files + folders, with explicit workspace action.
local M = {}
local api = vim.api
local session

function M.active()
  return session ~= nil and session.buf ~= nil and api.nvim_buf_is_valid(session.buf)
end

local function resume(value)
  if value and api.nvim_win_is_valid(value.origin) then
    api.nvim_set_current_win(value.origin)
    if vim.bo.filetype == 'autovim' then require('autovim.dashboard').open() end
  end
end

function M.dismiss(restore)
  local value = session
  if not value then return end
  session = nil
  if value.buf and api.nvim_buf_is_valid(value.buf) then require('telescope.actions').close(value.buf) end
  if restore then resume(value)
  elseif api.nvim_win_is_valid(value.origin) then api.nvim_set_current_win(value.origin) end
end

local function selected()
  if not M.active() then return nil end
  return require('telescope.actions.state').get_selected_entry()
end

local function finish(path, workspace)
  local value = session
  M.dismiss(false)
  if workspace then require('autovim.workspace').open(path)
  else require('autovim.workspace').open_file(path, value.mode == 'standalone') end
end

function M.choose_workspace()
  local value, entry = session, selected()
  if not value then return end
  local path = entry and entry.directory and entry.path or value.directory
  finish(path, true)
end

function M.home()
  local value = session
  if not value then return end
  local directory = vim.uv.os_homedir()
  if not directory then return end
  M.dismiss(false)
  M.open(value.mode, directory, value.origin)
end

function M.select()
  local value, entry = session, selected()
  if not value or not entry then return end
  if entry.directory then
    if entry.path == value.directory then return end
    M.dismiss(false)
    M.open(value.mode, entry.path, value.origin)
  elseif value.mode ~= 'workspace' then finish(entry.path, false) end
end

function M.open(mode, directory, origin)
  if M.active() then return end
  require('telescope') -- lazy.nvim loads Telescope and plenary on first use.
  directory = directory or require('autovim.workspace').directory()
  if vim.fn.isdirectory(directory) ~= 1 then directory = vim.fn.getcwd() end
  directory = vim.fs.normalize(vim.fn.fnamemodify(directory, ':p')):gsub('/$', '')
  if directory == '' then directory = '/' end
  origin = origin or api.nvim_get_current_win()
  local value = { mode = mode or 'any', directory = directory, origin = origin }
  session = value
  local conf = require('telescope.config').values
  local entry_maker = function(relative)
    relative = relative:gsub('^%./', ''):gsub('/+$', '')
    local path = relative == '.' and directory or vim.fs.normalize(directory .. '/' .. relative)
    local folder = vim.fn.isdirectory(path) == 1
    if value.mode == 'workspace' and not folder then return nil end
    local label = relative == '.' and './' or relative .. (folder and '/' or '')
    return { value = path, path = path, filename = path, directory = folder,
      ordinal = label, display = (folder and '▣  ' or '   ') .. label }
  end
  local finder
  local scanner = require('autovim.explorer.finder')
  local function command(prompt) return scanner.command(prompt, directory) end
  if command('') then
    -- A one-shot finder blocks prompt updates until its initial scan finishes.
    -- Restart a cancellable job on each query, filtering in fd/find before Lua
    -- receives paths. Empty prompts list only the current folder.
    finder = scanner.new(command, entry_maker, directory)
  else
    -- Native fallback for hosts without fd, fdfind, or find.
    local paths = { '.' }
    for _, path in ipairs(require('plenary.scandir').scan_dir(directory, { hidden = true, add_dirs = true, respect_gitignore = true })) do
      paths[#paths + 1] = path:sub(#directory + 2)
    end
    finder = require('telescope.finders').new_table({ results = paths, entry_maker = entry_maker })
  end
  local previewer = require('telescope.previewers').new_buffer_previewer({
    define_preview = function(self, entry)
      if entry.directory then
        local lines = { '  ' .. entry.path, '', '  Enter: browse this folder', '  Space Enter: open as workspace', '' }
        for name, kind in vim.fs.dir(entry.path) do
          if #lines >= 100 then break end
          lines[#lines + 1] = '  ' .. name .. (kind == 'directory' and '/' or '')
        end
        vim.bo[self.state.bufnr].filetype = ''
        api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      else conf.buffer_previewer_maker(entry.path, self.state.bufnr, { bufname = self.state.bufname, winid = self.state.winid }) end
    end,
  })
  local titles = { any = 'Open file or workspace', workspace = 'Choose workspace', file = 'Open file', standalone = 'Open standalone file' }
  require('telescope.pickers').new({}, {
    prompt_title = 'AutoVim · ' .. titles[value.mode],
    results_title = directory,
    preview_title = 'Enter: open · Space Enter: workspace · Ctrl-C: home',
    cwd = directory,
    finder = finder,
    sorter = require('autovim.explorer.search').sorter(),
    previewer = previewer,
    attach_mappings = function(buf, map)
      value.buf = buf
      api.nvim_create_autocmd('BufWipeout', { buffer = buf, once = true, callback = function()
        if session ~= value then return end
        session = nil
        vim.schedule(function() resume(value) end)
      end })
      require('telescope.actions').select_default:replace(M.select)
      for _, keymode in ipairs({ 'i', 'n' }) do
        map(keymode, '<leader><CR>', M.choose_workspace)
        map(keymode, '<Esc>', function() M.dismiss(true) end)
        map(keymode, '<C-c>', M.home)
        map(keymode, '<C-h>', function()
          local parent = vim.fs.dirname(directory)
          if parent then M.dismiss(false); M.open(value.mode, parent, origin) end
        end)
      end
      map('n', 'q', function() M.dismiss(true) end)
      map('n', '-', function()
        local parent = vim.fs.dirname(directory)
        if parent then M.dismiss(false); M.open(value.mode, parent, origin) end
      end)
      return true
    end,
  }):find()
end

return M
