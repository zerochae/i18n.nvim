local M = {}

M.config = {}

M.setup = function(user_config)
  M.config = user_config or {}
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

  return path
end

return M
