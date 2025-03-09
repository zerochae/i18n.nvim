local M = {}
local ts_utils = require "nvim-treesitter.ts_utils"
local namespace = vim.api.nvim_create_namespace "i18n.nvim"

M.render_translation = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local translations = require("i18n.core.loader").load_current_project_translations()

  local node = ts_utils.get_node_at_cursor()
  if not node then
    return
  end

  local text = vim.treesitter.get_node_text(node, 0)
  local pattern = 't%("%s*([^"]+)%s*"%)'
  local match = string.match(text, pattern)

  if match and translations["ko"] and translations["ko"][match] then
    local row, col, _ = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_extmark(bufnr, namespace, row - 1, col, {
      virt_text = { { " 📝 " .. translations["ko"][match], "Comment" } },
      hl_mode = "combine",
    })
  end
end

vim.api.nvim_create_user_command("I18nRender", M.render_translation, {})

return M
