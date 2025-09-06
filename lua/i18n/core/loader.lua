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
  
  -- Try configured path first
  local configured_path = root .. "/" .. cfg.locales_dir
  if vim.fn.isdirectory(configured_path) == 1 then
    return configured_path
  end
  
  -- Search patterns for common locale directory structures
  local search_patterns = {
    "locales",
    "locale", 
    "lang",
    "i18n",
    "translations",
    "src/locales",
    "src/locale",
    "src/lang", 
    "src/i18n",
    "src/translations",
    "public/locales",
    "assets/locales",
  }
  
  -- First pass: direct directory search
  for _, pattern in ipairs(search_patterns) do
    local path = root .. "/" .. pattern
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  
  -- Second pass: find directories containing locale files
  local common_locales = {"en", "ko", "ja", "zh", "fr", "de", "es"}
  local json_files = vim.fn.globpath(root, "**/*.json", false, true)
  
  for _, file in ipairs(json_files) do
    local filename = vim.fn.fnamemodify(file, ":t:r")
    local dir = vim.fn.fnamemodify(file, ":h")
    
    -- Check if filename matches common locale pattern
    for _, locale in ipairs(common_locales) do
      if filename == locale then
        -- Verify other locale files exist in same directory
        local locale_count = 0
        local dir_files = vim.fn.globpath(dir, "*.json", false, true)
        for _, dir_file in ipairs(dir_files) do
          local dir_filename = vim.fn.fnamemodify(dir_file, ":t:r")
          for _, check_locale in ipairs(common_locales) do
            if dir_filename == check_locale then
              locale_count = locale_count + 1
              break
            end
          end
        end
        
        -- If multiple locale files found, this is likely the locales directory
        if locale_count >= 2 then
          return dir
        end
      end
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
