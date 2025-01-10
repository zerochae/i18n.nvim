local M = {}

M.find_keys = function(bufnr, pattern)
  local keys = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for i, line in ipairs(lines) do
    for key in line:gmatch(pattern) do
      table.insert(keys, { key = key, line = i })
    end
  end

  return keys
end

return M
