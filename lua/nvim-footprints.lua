local ClearHighlights = require("helpers.clearhighlights")
local DeclareHighlights = require("helpers.declarehighlights")
local GetChangesList = require("helpers.getchangeslist")
local UpdateMatches = require("helpers.updatematches")

local M = {}
local is_enabled = false
local group_name = "FootprintsStep"

local function get_is_enabled()
  return vim.b.isEnabled ~= nil and vim.b.isEnabled or is_enabled
end

local function should_update_matches()
  return get_is_enabled()
    and vim.bo.modifiable
    and not vim.wo.diff
    and not vim.tbl_contains(vim.g.footprintsExcludeFiletypes, vim.bo.filetype)
end

local function run_update_matches()
  UpdateMatches.UpdateMatches(
    group_name,
    vim.api.nvim_get_current_buf(),
    GetChangesList.GetChangesLinenumbersList(vim.g.footprintsHistoryDepth),
    vim.g.footprintsHistoryDepth
  )
end

local function footprints_inner(bufnr)
  if not should_update_matches() then
    ClearHighlights.ClearHighlights(group_name)
    return
  end
  GetChangesList.ClearChangesList()
  run_update_matches()
end

function M.FootprintsInit()
  DeclareHighlights.DeclareHighlights(group_name, vim.g.footprintsColor, vim.g.footprintsTermColor, vim.g.footprintsHistoryDepth)
  is_enabled = vim.g.footprintsEnabledByDefault
end

function M.SetColor(color)
  vim.g.footprintsColor = color
  DeclareHighlights.DeclareHighlights(group_name, vim.g.footprintsColor, vim.g.footprintsTermColor, vim.g.footprintsHistoryDepth)
end

function M.SetTermColor(color)
  vim.g.footprintsTermColor = color
  DeclareHighlights.DeclareHighlights(group_name, vim.g.footprintsColor, vim.g.footprintsTermColor, vim.g.footprintsHistoryDepth)
end

function M.Footprints()
  footprints_inner(vim.api.nvim_get_current_buf())
end

function M.OnBufEnter()
  ClearHighlights.ClearHighlights(group_name)
  footprints_inner(vim.api.nvim_get_current_buf())
end

function M.OnFiletypeSet()
  ClearHighlights.ClearHighlights(group_name)
  footprints_inner(vim.api.nvim_get_current_buf())
end

function M.OnCursorMove()
  if not should_update_matches() or vim.g.footprintsOnCurrentLine then
    return
  end
  run_update_matches()
end

function M.FootprintsDisable(is_buf_local)
  if is_buf_local then
    vim.b.isEnabled = false
  else
    is_enabled = false
  end
  ClearHighlights.ClearHighlightsInAllBuffers(group_name)
end

function M.FootprintsEnable(is_buf_local)
  if is_buf_local then
    vim.b.isEnabled = true
  else
    is_enabled = true
  end
  local tabpage = vim.api.nvim_get_current_tabpage()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    vim.api.nvim_buf_call(bufnr, function() footprints_inner(bufnr) end)
  end
end

function M.FootprintsToggle(is_buf_local)
  if get_is_enabled() then
    M.FootprintsDisable(is_buf_local)
  else
    M.FootprintsEnable(is_buf_local)
  end
end

function M.FootprintsEnableCurrentLine()
  vim.g.footprintsOnCurrentLine = true
  run_update_matches()
end

function M.FootprintsDisableCurrentLine()
  vim.g.footprintsOnCurrentLine = false
  run_update_matches()
end

function M.FootprintsToggleCurrentLine()
  if vim.g.footprintsOnCurrentLine then
    M.FootprintsDisableCurrentLine()
  else
    M.FootprintsEnableCurrentLine()
  end
end

function M.SetHistoryDepth(new_depth)
  vim.g.footprintsHistoryDepth = new_depth
  DeclareHighlights.DeclareHighlights(group_name, vim.g.footprintsColor, vim.g.footprintsTermColor, vim.g.footprintsHistoryDepth)
  run_update_matches()
end

local augroup = vim.api.nvim_create_augroup("footprints", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  group = augroup,
  callback = function()
    -- M.FootprintsInit()
    vim.schedule(function() M.FootprintsInit() end) -- Schedule to ensure it runs after the colorscheme is fully applied
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  callback = function() M.OnFiletypeSet() end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup,
  callback = function() M.OnBufEnter() end,
})

vim.api.nvim_create_autocmd("CursorMoved", {
  group = augroup,
  callback = function() M.OnCursorMove() end,
})

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "FileType", "BufEnter", "BufLeave" }, {
  group = augroup,
  callback = function() M.Footprints() end,
})

-- Commands
vim.api.nvim_create_user_command(
    "FootprintsDisable",
    function() M.FootprintsDisable() end,
    { desc = "Disable footprints globally" }
)

vim.api.nvim_create_user_command(
    "FootprintsEnable",
    function() M.FootprintsEnable() end,
    { desc = "Enable footprints globally" }
)

vim.api.nvim_create_user_command(
    "FootprintsToggle",
    function() M.FootprintsToggle() end,
    { desc = "Toggle footprints globally" }
)

vim.api.nvim_create_user_command(
    "FootprintsBufferDisable",
    function() M.FootprintsDisable(true) end,
    { desc = "Disable footprints for current buffer" }
)

vim.api.nvim_create_user_command(
    "FootprintsBufferEnable",
    function() M.FootprintsEnable(true) end,
    { desc = "Enable footprints for current buffer" }
)

vim.api.nvim_create_user_command(
    "FootprintsBufferToggle",
    function() M.FootprintsToggle(true) end,
    { desc = "Toggle footprints for current buffer" }
)

vim.api.nvim_create_user_command(
    "FootprintsDisableCurrentLine",
    function() M.FootprintsDisableCurrentLine() end,
    { desc = "Disable footprints for current line" }
)

vim.api.nvim_create_user_command(
    "FootprintsEnableCurrentLine",
    function() M.FootprintsEnableCurrentLine() end,
    { desc = "Enable footprints for current line" }
)

vim.api.nvim_create_user_command(
    "FootprintsToggleCurrentLine",
    function() M.FootprintsToggleCurrentLine() end,
    { desc = "Toggle footprints for current line" }
)

function M.setup(opts)
  vim.g.footprintsHistoryDepth = opts.footprintsHistoryDepth or 20
  vim.g.footprintsExcludeFiletypes = opts.footprintsExcludeFiletypes or {"magit", "nerdtree", "diff"}
  vim.g.footprintsEasingFunction = opts.footprintsEasingFunction or "easeinout"
  vim.g.footprintsEnabledByDefault = opts.footprintsEnabledByDefault ~= false
  vim.g.footprintsOnCurrentLine = opts.footprintsOnCurrentLine or false
  vim.g.footprintsColor = opts.footprintsColor or (vim.o.background == "dark" and "#3A3A3A" or "#C1C1C1")
  vim.g.footprintsTermColor = opts.footprintsTermColor or "208"

  M.FootprintsInit()
end

return M
