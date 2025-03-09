local M = {}
local Path = require "plenary.path"

-- 현재 프로젝트의 root 폴더명 가져오기
local function get_project_root()
  local cwd = vim.fn.getcwd()
  return vim.fn.fnamemodify(cwd, ":t")
end

-- JSON 파일 로드 함수
M.load_translation_file = function(filepath)
  local path = Path:new(filepath)
  if not path:exists() then
    return {}
  end
  local content = path:read()
  return vim.json.decode(content) or {}
end

-- 현재 프로젝트의 번역 파일 로드
M.load_current_project_translations = function()
  local config = require("i18n.core.config").config
  local project_name = get_project_root()
  local project_config = config.projects[project_name]

  if not project_config then
    error("No i18n configuration found for project: " .. project_name)
  end

  local translations = {}
  for _, lang in ipairs(project_config.languages) do
    local path = project_config.locales_path .. lang .. ".json"
    translations[lang] = M.load_translation_file(path)
  end
  return translations
end

return M
