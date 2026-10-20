-- One palette for ordinary syntax, Tree-sitter captures, and plugin surfaces.
local M = {}
function M.apply()
  vim.cmd("highlight clear")
  vim.g.colors_name = "autovim"
  local c = { bg = "#10151c", panel = "#19232e", fg = "#dbe6ee", muted = "#7e929f", teal = "#79d9cf", amber = "#e8b779", blue = "#8db9df", red = "#e78a8a", green = "#a7c9a0" }
  local groups = {
    Normal = { fg = c.fg, bg = c.bg }, NormalNC = { fg = c.fg, bg = c.bg },
    NormalFloat = { fg = c.fg, bg = c.bg }, FloatBorder = { fg = c.teal, bg = c.bg },
    FloatTitle = { fg = c.teal, bg = c.bg, bold = true },
    EndOfBuffer = { fg = c.bg }, WinSeparator = { fg = "#354a59", bg = c.bg },
    LineNr = { fg = "#526775" }, CursorLineNr = { fg = c.teal, bold = true },
    CursorLine = { bg = "#17222c" }, Visual = { bg = "#29404b" },
    Search = { fg = c.bg, bg = c.amber }, IncSearch = { fg = c.bg, bg = c.teal },
    Comment = { fg = c.muted, italic = true }, Constant = { fg = c.amber },
    String = { fg = c.green }, Character = { fg = c.green }, Number = { fg = c.amber },
    Boolean = { fg = c.amber }, Float = { fg = c.amber },
    Identifier = { fg = c.fg }, Function = { fg = c.teal }, Statement = { fg = c.amber },
    Keyword = { fg = c.amber }, Operator = { fg = c.teal }, PreProc = { fg = c.blue },
    Type = { fg = c.blue }, Special = { fg = c.teal }, Delimiter = { fg = c.muted },
    Error = { fg = c.red }, Todo = { fg = c.amber, bold = true },
    Directory = { fg = c.teal }, Title = { fg = c.teal, bold = true },
    Pmenu = { fg = c.fg, bg = c.panel }, PmenuSel = { fg = c.teal, bg = "#29404b" },
    DiagnosticError = { fg = c.red }, DiagnosticWarn = { fg = c.amber },
    DiagnosticInfo = { fg = c.blue }, DiagnosticHint = { fg = c.teal },
    DiagnosticUnderlineError = { sp = c.red, undercurl = true }, DiagnosticUnderlineWarn = { sp = c.amber, undercurl = true },
    DiagnosticUnderlineInfo = { sp = c.blue, undercurl = true }, DiagnosticUnderlineHint = { sp = c.teal, undercurl = true },
    LspReferenceText = { bg = "#29404b" }, LspReferenceRead = { bg = "#29404b" }, LspReferenceWrite = { bg = "#29404b" },
    LspSignatureActiveParameter = { fg = c.amber, bold = true },
    DiffAdd = { bg = "#20342c" }, DiffDelete = { bg = "#3a242c" }, DiffChange = { bg = "#263547" },
    TelescopeNormal = { fg = c.fg, bg = c.bg }, TelescopeBorder = { fg = "#354a59", bg = c.bg },
    TelescopeTitle = { fg = c.teal, bg = c.bg, bold = true },
    TelescopeSelection = { fg = c.teal, bg = "#192a32", bold = true },
    TelescopeMatching = { fg = c.amber, bold = true }, TelescopePromptPrefix = { fg = c.teal },
  }
  for name, definition in pairs(groups) do vim.api.nvim_set_hl(0, name, definition) end
  local links = {
    ["@variable"] = "Identifier", ["@variable.builtin"] = "Special", ["@variable.parameter"] = "Identifier",
    ["@constant"] = "Constant", ["@constant.builtin"] = "Constant", ["@module"] = "Type",
    ["@string"] = "String", ["@string.escape"] = "Special", ["@character"] = "Character",
    ["@number"] = "Number", ["@boolean"] = "Boolean", ["@type"] = "Type",
    ["@type.builtin"] = "Type", ["@attribute"] = "PreProc", ["@property"] = "Identifier",
    ["@function"] = "Function", ["@function.call"] = "Function", ["@function.method"] = "Function",
    ["@constructor"] = "Type", ["@operator"] = "Operator", ["@keyword"] = "Keyword",
    ["@punctuation"] = "Delimiter", ["@comment"] = "Comment", ["@comment.todo"] = "Todo",
    ["@markup.heading"] = "Title", ["@markup.link"] = "Underlined", ["@tag"] = "Type",
    ["@lsp.type.function"] = "Function", ["@lsp.type.method"] = "Function", ["@lsp.type.type"] = "Type",
    ["@lsp.type.class"] = "Type", ["@lsp.type.struct"] = "Type", ["@lsp.type.interface"] = "Type",
    ["@lsp.type.variable"] = "Identifier", ["@lsp.type.parameter"] = "Identifier", ["@lsp.type.property"] = "Identifier",
    CmpItemAbbrMatch = "Function", CmpItemAbbrMatchFuzzy = "Function", CmpItemKind = "Type", CmpItemMenu = "Comment",
    UndotreeNode = "AVTitle", UndotreeCurrent = "AVGear", UndotreeSeq = "AVMuted",
  }
  for name, target in pairs(links) do vim.api.nvim_set_hl(0, name, { link = target }) end
end
return M
