-- Feed Telescope from Neovim job callbacks without waiting for scanner EOF.
-- Each prompt owns one job; stale callbacks cannot populate a newer query.
local M = {}

function M.command(prompt, directory)
  local fd = vim.fn.executable('fd') == 1 and 'fd' or vim.fn.executable('fdfind') == 1 and 'fdfind' or nil
  if fd then
    local command = { fd, '--hidden', '--no-ignore', '--color', 'never', '--full-path', '--ignore-case',
      '--exclude', '.git', '--type', 'f', '--type', 'd', '--type', 'l' }
    if prompt == '' then vim.list_extend(command, { '--max-depth', '1' }) end
    -- fd matches absolute paths. Anchor the root before the literal query so
    -- a word in the root itself cannot match every file underneath it.
    local function literal(value) return vim.fn.escape(value, [[\.^$|?*+()[]{}]]) end
    local root = (vim.uv.fs_realpath(directory) or directory):gsub('/$', '')
    local pattern = prompt == '' and '' or '^' .. literal(root) .. '/.*' .. literal(prompt)
    vim.list_extend(command, { '--', pattern })
    -- fd omits the search root; keep ./ selectable in the empty prompt.
    return command, prompt == '' and { '.' } or nil
  end
  if vim.fn.executable('find') ~= 1 then return nil end
  local command = { 'find', '.' }
  if prompt == '' then vim.list_extend(command, { '-maxdepth', '1' }) end
  vim.list_extend(command, { '-name', '.git', '-prune', '-o', '(', '-type', 'd', '-o', '-type', 'f', '-o', '-type', 'l', ')' })
  if prompt ~= '' then
    local literal = prompt:gsub('[*?%[%]\\]', '\\%0')
    vim.list_extend(command, { '-ipath', '*' .. literal .. '*' })
  end
  command[#command + 1] = '-print'
  return command
end

function M.new(command, entry_maker, directory)
  local active
  local function close()
    local previous = active
    active = nil
    if previous and previous.job and previous.job > 0 then pcall(vim.fn.jobstop, previous.job) end
  end
  return setmetatable({ close = close }, {
    __call = function(_, prompt, process_result, process_complete)
      close()
      local scan = { partial = '', index = 0 }
      active = scan
      local function emit(line)
        if active ~= scan or line == '' then return end
        local entry = entry_maker(line)
        if not entry then return end
        scan.index = scan.index + 1
        entry.index = scan.index
        if process_result(entry) then close() end
      end
      local arguments, initial = command(prompt)
      for _, line in ipairs(initial or {}) do emit(line) end
      if active ~= scan then return end
      scan.job = vim.fn.jobstart(arguments, {
        cwd = directory,
        on_stdout = function(_, data)
          if active ~= scan then return end
          -- Job callbacks can split a path across chunks. Only emit full lines.
          data[1] = scan.partial .. data[1]
          scan.partial = data[#data]
          for index = 1, #data - 1 do
            if active ~= scan then break end
            emit(data[index])
          end
        end,
        on_exit = function()
          if active ~= scan then return end
          emit(scan.partial)
          if active == scan then active = nil; process_complete() end
        end,
      })
      if scan.job <= 0 then
        active = nil
        process_complete()
        vim.notify('Could not start file search', vim.log.levels.ERROR)
      end
    end,
  })
end

return M
