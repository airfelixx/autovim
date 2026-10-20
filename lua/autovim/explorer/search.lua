-- Require the typed text in the path; use fuzzy scores only to rank real matches.
local M = {}

function M.sorter()
  local sorter = require('telescope.sorters').get_fzy_sorter()
  local score = sorter.scoring_function
  sorter.scoring_function = function(self, prompt, ordinal)
    if not ordinal:lower():find(prompt:lower(), 1, true) then return -1 end
    return score(self, prompt, ordinal)
  end
  sorter.highlighter = function(_, prompt, display)
    if prompt == '' then return {} end
    local first, last = display:lower():find(prompt:lower(), 1, true)
    return first and { { start = first, finish = last } } or {}
  end
  return sorter
end

return M
