local M = {}
local ts_utils = require "nvim-treesitter.ts_utils"

M.find_translation_keys = function()
  local node = ts_utils.get_node_at_cursor()
  if not node then
    return
  end

  local text = vim.treesitter.get_node_text(node, 0)
  local pattern = 't%("%s*([^"]+)%s*"%)'
  local match = string.match(text, pattern)

  if match then
    print("번역 키 감지: " .. match)
  end
end

vim.api.nvim_create_user_command("I18nDetectKey", M.find_translation_keys, {})

return M
