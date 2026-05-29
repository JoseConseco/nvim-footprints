local M = {}

local function get_namespace(group_name)
  return vim.api.nvim_create_namespace("nvim-footprints-" .. group_name)
end

--- @param bufnr? number buffer id (defaults to current buffer)
function M.ClearHighlights(group_name, bufnr)
  local target_bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(target_bufnr, get_namespace(group_name), 0, -1)
end

function M.ClearHighlightsInAllBuffers(group_name)
  local namespace = get_namespace(group_name)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
    end
  end
end

return M
