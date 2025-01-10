local parser = require "i18n.parser"
local locale = require "i18n.locale"
local state = require "i18n.state"

local M = {}

local ns_id = vim.api.nvim_create_namespace "i18n_virtual_text"

M.render_virtual_text = function(lang, tags)
  local bufnr = vim.api.nvim_get_current_buf()
  local translations = locale.load_locale(lang, tags)

  if not translations or vim.tbl_isempty(translations) then
    print(state.config.icon .. " No translations available for language: " .. lang)
    return
  end

  local pattern = "t%([\"'](.-)[\"']%)"
  local keys = parser.find_keys(bufnr, pattern)

  if not keys or #keys == 0 then
    print(state.config.icon .. " No translation keys found in the current buffer.")
    return
  end

  for _, key_info in ipairs(keys) do
    local key = key_info.key
    local line = key_info.line - 1
    local translation = translations[key]

    if translation then
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, -1, {
        virt_text = { { translation, "Comment" } },
        virt_text_pos = "eol",
      })
    end
  end
end

M.replace_text = function(lang, tags)
  local bufnr = vim.api.nvim_get_current_buf()
  local translations = locale.load_locale(lang, tags)

  if not translations or vim.tbl_isempty(translations) then
    print(state.config.icon .. " No translations available for language: " .. lang)
    return
  end

  local pattern = "t%([\"'](.-)[\"']%)"
  local keys = parser.find_keys(bufnr, pattern)

  if not keys or #keys == 0 then
    print(state.config.icon .. " No translation keys found in the current buffer.")
    return
  end

  for _, key_info in ipairs(keys) do
    local key = key_info.key
    local line = key_info.line - 1
    local translation = translations[key]

    if translation then
      local line_content = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
      local new_content = line_content:gsub("t%([\"']" .. key .. "[\"']%)", '"' .. translation .. '"')
      vim.api.nvim_buf_set_lines(bufnr, line, line + 1, false, { new_content })
    end
  end
end

M.render = function(lang, tags)
  if state.config.render == "virtual_text" then
    M.render_virtual_text(lang, tags)
  elseif state.config.render == "replace" then
    M.replace_text(lang, tags)
  else
    print(state.config.icon .. " Invalid render mode: " .. state.config.render)
  end
end

M.clear_virtual_text = function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  print(state.config.icon .. " Virtual text cleared.")
end

return M
