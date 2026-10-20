-- Mason installs servers on request; it never installs the user's toolchains.
local M = {}

function M.setup()
  require('mason').setup({
    registries = { 'github:mason-org/mason-registry@2026-10-20-stark-key' },
    ui = { border = 'rounded' }, max_concurrent_installers = 3,
  })
end

function M.available(tool)
  if vim.fn.executable(tool) == 1 then return true end
  return tool == 'java' and vim.env.JAVA_HOME ~= nil and vim.fn.executable(vim.env.JAVA_HOME .. '/bin/java') == 1
end

function M.missing(tools)
  return vim.tbl_filter(function(tool) return not M.available(tool) end, tools or {})
end

function M.install(name)
  require('mason') -- lazy.nvim loads and configures the manager here.
  local servers, selected = require('autovim.lsp.servers'), {}
  if name == '' then
    local current = require('autovim.lsp').server(vim.bo.filetype)
    if current then selected = { current } end
  elseif name == 'all' then selected = vim.tbl_keys(servers)
  elseif servers[name] then selected = { name }
  else
    for id, spec in pairs(servers) do if spec.package == name then selected = { id }; break end end
  end
  if #selected == 0 then
    vim.notify('Choose a configured server: :LspInstall <name> or :LspInstall all', vim.log.levels.INFO)
    return
  end
  table.sort(selected)
  require('mason-registry').refresh(vim.schedule_wrap(function(ok)
    if not ok then vim.notify('Mason registry unavailable. Try :MasonUpdate; see :MasonLog.', vim.log.levels.ERROR); return end
    for _, id in ipairs(selected) do
      local spec = servers[id]
      local missing = M.missing(spec.install_tools)
      if #missing > 0 then
        vim.notify(spec.label .. ': install ' .. table.concat(missing, ', ') .. ' first, then :LspInstall ' .. id, vim.log.levels.WARN)
      else
        local found, pkg = pcall(require('mason-registry').get_package, spec.package)
        if not found then vim.notify('Mason package unavailable: ' .. spec.package, vim.log.levels.ERROR)
        elseif not pkg:is_installing() then
          -- Explicit installs restore the declared version, even after a Mason update.
          pkg:install({ version = spec.version }, vim.schedule_wrap(function(success)
            if success then
              vim.notify(spec.label .. ' server ready (' .. spec.version .. ')')
              require('autovim.lsp').start()
            else vim.notify(spec.label .. ' server installation failed. See :MasonLog.', vim.log.levels.ERROR) end
          end))
        end
      end
    end
  end))
end

return M
