local M = {}

M.config = require "i18n.core.config"
M.loader = require "i18n.core.loader"

M.treesitter = require "i18n.finder.treesitter"
M.telescope = require "i18n.finder.telescope"

M.virtual_text = require "i18n.renderer.virtual_text"

M.setup = function(opts)
  if opts and opts.projects then
    if type(opts.projects) ~= "table" then
      error "projects must be a table (e.g., { projectA = { locales_path = '...', languages = {...} } })"
    end
  end
  M.config = vim.tbl_extend("force", M.config, opts or {})
end

return M
