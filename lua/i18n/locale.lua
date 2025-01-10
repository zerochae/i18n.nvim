local Path = require "plenary.path"
local state = require "i18n.state"
local M = {}

M.load_locale = function(lang)
  local base_path = state.get_path()
  if not base_path then
    print "Locale path is not configured for the current project."
    return nil
  end

  local file_path = base_path .. "/" .. lang .. ".json"
  local file = Path:new(file_path)

  if not file:exists() then
    print("Locale file not found: " .. file_path)
    return nil
  end

  local content = file:read()
  local ok, data = pcall(vim.fn.json_decode, content)
  if not ok then
    print("Failed to parse JSON: " .. file_path)
    return nil
  end

  return data
end

return M
