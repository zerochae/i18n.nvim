local M = {}

M.config = {
  render = "virtual_text",
  default_lang = "en",
  default_tag = "common",
  locale_path = {},
  auto_enable = false,
}

M.setup = function(user_config)
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
end

local function get_root_folder_name()
  local cwd = vim.fn.getcwd()
  return vim.fn.fnamemodify(cwd, ":t")
end

M.get_path = function()
  local root_folder = get_root_folder_name()
  if not M.config.locale_path then
    print "Locale path is not configured!"
    return nil
  end

  local path = M.config.locale_path[root_folder]
  if not path then
    print("Locale path not found for project: " .. root_folder)
    return nil
  end

  return string.gsub(path, "/$", "")
end

M.get_tag = function()
  return M.config.default_tag
end

M.get_lang = function()
  return M.config.default_lang
end

return M
