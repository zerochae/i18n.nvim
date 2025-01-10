local state = require "i18n.state"
local renderer = require "i18n.renderer"

local M = {}

-- 설정 및 명령어 등록
M.setup = function(user_config)
  state.setup(user_config) -- 설정 저장

  vim.api.nvim_create_user_command("I18nReplace", function(opts)
    local lang = opts.args or state.config.default_lang
    renderer.replace_i18n_keys(lang) -- renderer.lua의 함수 호출
  end, {
    nargs = "?",
    desc = "Replace i18n keys with translations",
  })

  print(state.config.icon .. " I18n plugin initialized with default language: " .. state.config.default_lang)
end

return M
