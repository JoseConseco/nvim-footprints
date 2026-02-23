local M = {}

--- Get match IDs for a highlight group
--- @param group_name string highlight group name (regex pattern)
--- @return table<number> list of match IDs
local function get_matches(group_name)
  local matches = vim.fn.getmatches()
  return vim.tbl_filter(function(match)
    return string.match(match.group, group_name)
  end, matches)
end

--- Clear highlights for a group in current window
--- @param group_name string highlight group name
function M.ClearHighlights(group_name)
  for _, match in ipairs(get_matches(group_name)) do
    pcall(vim.fn.matchdelete, match.id)
  end
end

--- Clear highlights for a group in all buffers across all tabpages/windows
--- @param group_name string highlight group name
function M.ClearHighlightsInAllBuffers(group_name)
  for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
    local tab_windows = vim.api.nvim_tabpage_list_wins(tabpage)
    for _, win in ipairs(tab_windows) do
      for _, match in ipairs(get_matches(group_name)) do
        pcall(vim.fn.matchdelete, match.id)
      end
    end
  end
end

return M
