local Path = require "plenary.path"
local state = require "i18n.state"
local M = {}

-- 특정 언어(lang)와 태그(tag name)의 JSON 파일 로드
local function load_file(base_path, lang, tag)
  local file_path = base_path .. "/" .. lang .. "/" .. tag .. ".json"
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

-- 특정 언어(lang)와 태그 목록(tags)을 기반으로 데이터를 병합
M.load_locale = function(lang, tags)
  local base_path = state.get_path()
  if not base_path then
    print "Locale path is not configured for the current project."
    return nil
  end

  local merged_data = {}

  for _, tag in ipairs(tags) do
    local data = load_file(base_path, lang, tag)
    if data then
      for key, value in pairs(data) do
        merged_data[key] = value
      end
    end
  end

  return merged_data
end

return M
