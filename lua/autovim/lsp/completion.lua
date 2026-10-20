-- Completion is only active in editing buffers, never menus or tool panels.
local M = {}
function M.setup()
  local cmp = require('cmp')
  local function has_text_before_cursor()
    local column = vim.api.nvim_win_get_cursor(0)[2]
    return column > 0 and vim.api.nvim_get_current_line():sub(column, column):match('%s') == nil
  end
  cmp.setup({
    enabled = function() return vim.bo.buftype == '' and vim.bo.filetype ~= 'netrw' end,
    preselect = cmp.PreselectMode.None,
    completion = { completeopt = 'menu,menuone,noinsert,noselect' },
    snippet = { expand = function(args) vim.snippet.expand(args.body) end },
    window = { completion = cmp.config.window.bordered(), documentation = cmp.config.window.bordered() },
    mapping = {
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-n>'] = cmp.mapping.select_next_item(), ['<C-p>'] = cmp.mapping.select_prev_item(),
      ['<C-e>'] = cmp.mapping.abort(), ['<C-b>'] = cmp.mapping.scroll_docs(-4), ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<CR>'] = cmp.mapping.confirm({ select = false }),
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.select_next_item()
        elseif vim.snippet.active({ direction = 1 }) then vim.snippet.jump(1)
        elseif has_text_before_cursor() then cmp.complete()
        else fallback() end
      end, { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then cmp.select_prev_item()
        elseif vim.snippet.active({ direction = -1 }) then vim.snippet.jump(-1)
        else fallback() end
      end, { 'i', 's' }),
    },
    sources = cmp.config.sources({ { name = 'nvim_lsp' }, { name = 'path' } }, { { name = 'buffer', keyword_length = 3 } }),
    formatting = { format = function(entry, item)
      item.menu = ({ nvim_lsp = '[LSP]', path = '[Path]', buffer = '[Buffer]' })[entry.source.name]
      return item
    end },
  })
end
return M
