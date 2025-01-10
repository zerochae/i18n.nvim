local Path = require "plenary.path"
local state = require "i18n.state"
local M = {}

local function load_file(file_path)
  local file = Path:new(file_path)

  if not file:exists() then
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

M.load_locale = function(lang, tags)
  local base_path = state.get_path()
  if not base_path then
    print "Locale path is not configured for the current project."
    return nil
  end

  tags = tags or state.get_tag()
  if #tags == 0 then
    tags = { "common" }
  end

  local merged_data = {}

  for _, tag in ipairs(tags) do
    local file_path = string.format("%s/%s/%s.json", base_path, lang, tag)

    local data = load_file(file_path)
    if data then
      for key, value in pairs(data) do
        merged_data[key] = value
      end
    else
      print("Locale file not found or failed to load: " .. file_path)
    end
  end

  return merged_data
end

return M
