local M = {}
local config = require("i18n.core.config")

M.cache = {}

local function find_project_root()
  local markers = { "package.json", ".git", "Cargo.toml", "go.mod", "pyproject.toml" }
  local path = vim.fn.expand("%:p:h")
  
  while path ~= "/" do
    for _, marker in ipairs(markers) do
      if vim.fn.filereadable(path .. "/" .. marker) == 1 or vim.fn.isdirectory(path .. "/" .. marker) == 1 then
        return path
      end
    end
    path = vim.fn.fnamemodify(path, ":h")
  end
  
  return vim.fn.getcwd()
end

local function find_locales_dir()
  local root = find_project_root()
  local cfg = config.get()
  local possible_paths = {
    root .. "/" .. cfg.locales_dir,
    root .. "/locales",
    root .. "/locale",
    root .. "/lang",
    root .. "/i18n",
    root .. "/src/locales",
    root .. "/src/locale",
    root .. "/src/lang",
    root .. "/src/i18n",
    root .. "/public/locales",
  }
  
  for _, path in ipairs(possible_paths) do
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  
  return nil
end

local function get_available_locales()
  local locales_dir = find_locales_dir()
  if not locales_dir then
    return {}
  end
  
  local locales = {}
  local files = vim.fn.globpath(locales_dir, "*.json", false, true)
  
  for _, file in ipairs(files) do
    local filename = vim.fn.fnamemodify(file, ":t:r")
    table.insert(locales, filename)
  end
  
  return locales
end

M.load_translation_file = function(filepath)
  if M.cache[filepath] then
    local stat = vim.loop.fs_stat(filepath)
    if stat and M.cache[filepath].mtime == stat.mtime.sec then
      return M.cache[filepath].data
    end
  end
  
  local file = io.open(filepath, "r")
  if not file then
    return {}
  end
  
  local content = file:read("*all")
  file:close()
  
  local ok, data = pcall(vim.json.decode, content)
  if not ok then
    vim.notify("Failed to parse JSON file: " .. filepath, vim.log.levels.ERROR)
    return {}
  end
  
  local stat = vim.loop.fs_stat(filepath)
  M.cache[filepath] = {
    data = data or {},
    mtime = stat and stat.mtime.sec or 0
  }
  
  return data or {}
end

M.get_translation = function(key, locale)
  local translations = M.load_all_translations()
  locale = locale or config.get().default_locale
  
  if not translations[locale] then
    return nil
  end
  
  local keys = vim.split(key, ".", { plain = true })
  local value = translations[locale]
  
  for _, k in ipairs(keys) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[k]
    if value == nil then
      return nil
    end
  end
  
  return value
end

M.load_all_translations = function()
  local locales_dir = find_locales_dir()
  if not locales_dir then
    return {}
  end
  
  local translations = {}
  local locales = get_available_locales()
  
  for _, locale in ipairs(locales) do
    local filepath = locales_dir .. "/" .. locale .. ".json"
    translations[locale] = M.load_translation_file(filepath)
  end
  
  return translations
end

M.clear_cache = function()
  M.cache = {}
end

M.get_project_info = function()
  return {
    root = find_project_root(),
    locales_dir = find_locales_dir(),
    available_locales = get_available_locales(),
  }
end

return M
