local state = require "i18n.state"
local renderer = require "i18n.renderer"

local M = {}

M.setup = function(user_config)
  state.setup(user_config)

  vim.api.nvim_create_user_command("I18nRender", function(opts)
    local args = vim.split(opts.args or "", " ")
    local tags = vim.tbl_filter(function(tag)
      return tag ~= nil and tag ~= ""
    end, args)

    if #tags == 0 then
      tags = { "common" }
    end

    local lang = state.get_lang()
    renderer.render(lang, tags)
  end, {
    nargs = "*",
    desc = "Render i18n keys using the selected render mode",
  })

  if state.config.auto_enable then
    vim.api.nvim_create_autocmd("BufReadPost", {
      pattern = "*",
      callback = function()
        local lang = state.get_lang()
        renderer.render(lang, state.get_tag())
      end,
      desc = "Automatically enable i18n rendering",
    })
  end

  print(state.config.icon .. " I18n plugin initialized with render mode: " .. state.config.render)
end


  vim.api.nvim_create_user_command("I18nClear", function()
    renderer.clear_virtual_text()
  end, {
    nargs = 0,
    desc = "Clear rendered virtual text",
  })
end

return M
