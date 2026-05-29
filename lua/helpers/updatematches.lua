local M = {}

local is_error_message_shown = false

local function get_namespace(group_name)
  return vim.api.nvim_create_namespace("nvim-footprints-" .. group_name)
end

--- Update footprint matches with gradient highlights
function M.UpdateMatches(group_name, bufnr, line_numbers, history_depth)
  local current_line = vim.fn.line(".")
  require("helpers.clearhighlights").ClearHighlights(group_name, bufnr)
  local namespace = get_namespace(group_name)

  local max_i = math.min(#line_numbers, history_depth)

  -- Show error once if highlights not ready
  if not is_error_message_shown and vim.fn.hlexists(group_name .. (history_depth - 1)) == 0 then
    is_error_message_shown = true
    vim.notify("No highlight group found for g:footprintsHistoryDepth=" .. 
               vim.g.footprintsHistoryDepth .. 
               ". You should call footprints.SetHistoryDepth(" .. vim.g.footprintsHistoryDepth .. ")", 
               vim.log.levels.WARN)
  end

  -- Add extmarks for each unique line (newest first), tinting only the number column.
  local seen_lines = {}
  local step = 0
  for i = 1, max_i do
    local line_nr = line_numbers[i]
    if vim.g.footprintsOnCurrentLine or line_nr ~= current_line then
      if line_nr and not seen_lines[line_nr] then
        seen_lines[line_nr] = true
        local highlight_group = group_name .. step
        pcall(vim.api.nvim_buf_set_extmark, bufnr, namespace, line_nr - 1, 0, {
          number_hl_group = highlight_group,
          priority = 200,
        })
        step = step + 1
        if step >= history_depth then
          break
        end
      end
    end
  end
end

return M
