-- Native Neovim LSP client: file routing, roots, shared UI, and buffer keymaps.
local M = {}
local api = vim.api
local warned = {}

function M.server(filetype)
  for id, spec in pairs(require('autovim.lsp.servers')) do
    if vim.tbl_contains(spec.filetypes, filetype) then return id, spec end
  end
end

local function within(file, directory)
  return file == directory or file:sub(1, #(directory == '/' and '/' or directory .. '/')) == (directory == '/' and '/' or directory .. '/')
end

function M.root(buf, spec)
  local file = api.nvim_buf_get_name(buf)
  local directory = vim.fs.dirname(file)
  local workspace = require('autovim.workspace').root()
  -- LSP roots may follow build files; the editor's explicit workspace never changes.
  local boundary = workspace and within(file, workspace) and workspace or nil
  local current = directory
  while current do
    for _, marker in ipairs(spec.markers) do if vim.uv.fs_stat(current .. '/' .. marker) then return current end end
    if vim.tbl_contains(spec.filetypes, 'nim') and #vim.fn.glob(current .. '/*.nimble', false, true) > 0 then return current end
    if boundary and current == boundary then break end
    if not boundary and vim.uv.fs_stat(current .. '/.git') then return current end
    local parent = vim.fs.dirname(current)
    if parent == current then break end
    current = parent
  end
  if boundary then return boundary end
  return directory
end

function M.config(id, buf, root)
  local spec = require('autovim.lsp.servers')[id]
  root = root or M.root(buf, spec)
  local config = {
    name = id, cmd = vim.deepcopy(spec.cmd), root_dir = root,
    capabilities = vim.tbl_deep_extend('force', vim.lsp.protocol.make_client_capabilities(), require('cmp_nvim_lsp').default_capabilities()),
    settings = vim.deepcopy(spec.settings or {}), init_options = vim.deepcopy(spec.init_options),
    flags = { debounce_text_changes = 150 },
  }
  if id == 'jdtls' then
    local data = vim.fn.stdpath('cache') .. '/autovim/jdtls/' .. vim.fn.sha256(root)
    vim.fn.mkdir(data, 'p')
    vim.list_extend(config.cmd, { '-data', data }) -- Unique Java metadata per project.
  elseif id == 'pyright' then
    -- Prefer a project's environment to an unrelated interpreter on PATH.
    local paths = { root .. '/.venv/bin/python', root .. '/venv/bin/python' }
    if vim.env.VIRTUAL_ENV then paths[#paths + 1] = vim.env.VIRTUAL_ENV .. '/bin/python' end
    for _, path in ipairs(paths) do
      if vim.fn.executable(path) == 1 then config.settings.python.pythonPath = path; break end
    end
  end
  return config
end

function M.start(buf, root)
  buf = buf or api.nvim_get_current_buf()
  if not api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= '' or api.nvim_buf_get_name(buf) == '' then return end
  local id, spec = M.server(vim.bo[buf].filetype)
  if not id then return end
  require('mason') -- Setup exposes installed server executables on PATH.
  local installer = require('autovim.lsp.installer')
  local missing = installer.missing(spec.tools)
  if vim.fn.executable(spec.cmd[1]) ~= 1 or #missing > 0 then
    if not warned[id] then
      warned[id] = true
      local message = #missing > 0 and ('Install the ' .. table.concat(missing, ', ') .. ' toolchain first.') or ('Install the server with :LspInstall ' .. id)
      vim.notify(spec.label .. ' LSP: ' .. message .. ' See :LspInfo.', vim.log.levels.INFO)
    end
    return
  end
  return vim.lsp.start(M.config(id, buf, root), { bufnr = buf })
end

local function attach(buf)
  local function map(keys, action, description, mode)
    vim.keymap.set(mode or 'n', keys, action, { buffer = buf, silent = true, desc = 'LSP: ' .. description })
  end
  map('gd', vim.lsp.buf.definition, 'definition')
  map('gD', vim.lsp.buf.declaration, 'declaration')
  map('gr', vim.lsp.buf.references, 'references')
  map('gi', vim.lsp.buf.implementation, 'implementation')
  map('gy', vim.lsp.buf.type_definition, 'type definition')
  map('K', vim.lsp.buf.hover, 'hover documentation')
  map('<C-k>', vim.lsp.buf.signature_help, 'signature help', 'i')
  map('<leader>lr', vim.lsp.buf.rename, 'rename symbol')
  map('<leader>la', vim.lsp.buf.code_action, 'code action')
  map('<leader>lf', function() vim.lsp.buf.format({ async = true, bufnr = buf }) end, 'format buffer')
  map('<leader>ld', vim.diagnostic.open_float, 'line diagnostics')
  map('<leader>lq', vim.diagnostic.setloclist, 'diagnostics list')
  map('<leader>ls', function() require('telescope.builtin').lsp_document_symbols() end, 'document symbols')
  map('<leader>lw', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, 'workspace symbols')
  for key, direction in pairs({ ['[d'] = -1, [']d'] = 1 }) do
    map(key, function()
      if vim.diagnostic.jump then vim.diagnostic.jump({ count = direction, float = true })
      else vim.diagnostic[direction == 1 and 'goto_next' or 'goto_prev']({ float = true }) end
    end, 'navigate diagnostics')
  end
end

function M.info()
  local installer, servers = require('autovim.lsp.installer'), require('autovim.lsp.servers')
  require('mason')
  local lines = { 'AutoVim · Language servers', '', 'Install: :LspInstall <name> | :LspInstall all | :Mason', 'After installing toolchains: restart Neovim, then :LspInstall all.', '' }
  for _, id in ipairs(vim.fn.sort(vim.tbl_keys(servers))) do
    local spec, state = servers[id], {}
    if vim.fn.executable(spec.cmd[1]) ~= 1 then state[#state + 1] = 'server missing' end
    local missing = installer.missing(spec.tools)
    if #missing > 0 then state[#state + 1] = 'needs ' .. table.concat(missing, ', ') end
    lines[#lines + 1] = id .. ' · ' .. spec.label .. ' · ' .. (#state == 0 and 'ready' or table.concat(state, '; '))
    lines[#lines + 1] = '  Mason: ' .. spec.package .. '@' .. spec.version
  end
  lines[#lines + 1] = ''; lines[#lines + 1] = 'Attached to this buffer:'
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do lines[#lines + 1] = '  ' .. client.name .. ' · ' .. (client.config.root_dir or '') end
  return vim.lsp.util.open_floating_preview(lines, 'text', { border = 'rounded', max_width = 94, max_height = 32 })
end

function M.restart()
  local buffers, ids = {}, {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    ids[#ids + 1] = client.id
    for buf in pairs(client.attached_buffers) do buffers[buf] = client.config.root_dir end
  end
  vim.lsp.stop_client(ids, true)
  vim.defer_fn(function() for buf, root in pairs(buffers) do if api.nvim_buf_is_valid(buf) then M.start(buf, root) end end end, 200)
end

function M.setup()
  vim.filetype.add({ extension = { nim = 'nim', nims = 'nim', nimble = 'nim', zig = 'zig', zon = 'zig' } })
  vim.diagnostic.config({
    virtual_text = { spacing = 2, prefix = '●' }, underline = true, severity_sort = true, update_in_insert = false,
    signs = { text = { [1] = 'E', [2] = 'W', [3] = 'I', [4] = 'H' } }, float = { border = 'rounded', source = 'always' },
  })
  for _, method in ipairs({ 'textDocument/hover', 'textDocument/signatureHelp' }) do
    vim.lsp.handlers[method] = vim.lsp.with(vim.lsp.handlers[method], { border = 'rounded' })
  end
  local group = api.nvim_create_augroup('AutoVimLSP', { clear = true })
  api.nvim_create_autocmd({ 'FileType', 'BufEnter' }, { group = group, callback = function(event) M.start(event.buf) end })
  api.nvim_create_autocmd('LspAttach', { group = group, callback = function(event) attach(event.buf) end })
  for name, action in pairs({ LspStart = M.start, LspInfo = M.info, LspRestart = M.restart }) do
    api.nvim_create_user_command(name, function() action() end, { force = true })
  end
  api.nvim_create_user_command('LspInstall', function(opts) require('autovim.lsp.installer').install(opts.args) end, {
    nargs = '?', force = true, complete = function() local names = vim.tbl_keys(require('autovim.lsp.servers')); names[#names + 1] = 'all'; table.sort(names); return names end,
  })
end

return M
