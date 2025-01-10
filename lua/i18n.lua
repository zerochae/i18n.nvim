local state = require "i18n.state"
local renderer = require "i18n.renderer"

local M = {}

M.setup = function(user_config)
  state.setup(user_config) -- 설정 저장

  vim.api.nvim_create_user_command("I18nReplace", function(opts)
    local args = vim.split(opts.args or "", " ") -- lang과 tags 분리
    local lang = args[1] or state.config.default_lang
    local tags = vim.tbl_slice(args, 2) -- 태그 목록 가져오기

    if #tags == 0 then
      tags = { "common" } -- 기본 태그
    end

    renderer.replace_i18n_keys(lang, tags) -- 태그 전달
  end, {
    nargs = "*",
    desc = "Replace i18n keys with translations",
  })

  print(state.config.icon .. " I18n plugin initialized with default language: " .. state.config.default_lang)
end

return M
