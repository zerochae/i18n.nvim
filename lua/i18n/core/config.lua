local M = {}

M.defaults = {
  enabled = true,
  auto_setup = true,
  default_locale = "en",
  locales_dir = "locales",
  filename_format = "{locale}.json",
  detect_patterns = {
    "t%((['\"])(.-)%1%)",
    "i18n%.t%((['\"])(.-)%1%)",
    "%.t%((['\"])(.-)%1%)",
    "%$t%((['\"])(.-)%1%)",
  },
  virtual_text = {
    enabled = true,
    max_width = 50,
    prefix = "💬 ",
    suffix = "",
    highlight = "Comment",
    position = "eol",
  },
  keymaps = {
    toggle = "<leader>it",
    next_key = "]t",
    prev_key = "[t",
    hover = "<leader>ih",
  },
  hover = {
    enabled = true,
    auto_show = false,
    delay = 500,
    max_width = 80,
    max_height = 20,
  },
}

M.config = vim.deepcopy(M.defaults)

M.setup = function(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", M.config, opts)
  end
  
  vim.validate({
    enabled = { M.config.enabled, "boolean" },
    auto_setup = { M.config.auto_setup, "boolean" },
    default_locale = { M.config.default_locale, "string" },
    locales_dir = { M.config.locales_dir, "string" },
    filename_format = { M.config.filename_format, "string" },
    detect_patterns = { M.config.detect_patterns, "table" },
  })
  
  return M.config
end

M.get = function()
  return M.config
end

return M
