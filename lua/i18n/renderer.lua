local parser = require "i18n.parser"
local locale = require "i18n.locale"
local state = require "i18n.state"

local M = {}

M.replace_i18n_keys = function(lang)
  local bufnr = vim.api.nvim_get_current_buf()
  local path = state.get_path()

  if not path then
    return
  end

  local translations = locale.load_locale(lang or state.config.default_lang, path)
  if not translations then
    print(state.config.icon .. " Translations for language not loaded: " .. (lang or state.config.default_lang))
    return
  end

  local pattern = "t%([\"'](.-)[\"']%)"
  local keys = parser.find_keys(bufnr, pattern)

  if not keys or #keys == 0 then
    print(state.config.icon .. " No translation keys found.")
    return
  end

  for _, key_info in ipairs(keys) do
    local key = key_info.key
    local line = key_info.line - 1 -- Lua는 0-based index
    local translation = translations[key]

    if translation then
      local line_content = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
      local new_content = line_content:gsub("t%([\"']" .. key .. "[\"']%)", '"' .. translation .. '"')
      vim.api.nvim_buf_set_lines(bufnr, line, line + 1, false, { new_content })
    end
  end

  print(state.config.icon .. " Keys replaced successfully!")
end

return M
