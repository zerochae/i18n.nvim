local M = {}
local config = require("i18n.core.config")
local loader = require("i18n.core.loader")
local treesitter = require("i18n.finder.treesitter")

M.namespace = vim.api.nvim_create_namespace("i18n.nvim")
M.enabled = false

M.locale_flags = {
  en = "🇺🇸",
  ko = "🇰🇷", 
  ja = "🇯🇵",
  zh = "🇨🇳",
  fr = "🇫🇷",
  de = "🇩🇪",
  es = "🇪🇸",
  it = "🇮🇹",
  pt = "🇵🇹",
  ru = "🇷🇺",
  ar = "🇸🇦",
  hi = "🇮🇳",
  th = "🇹🇭",
  vi = "🇻🇳",
  id = "🇮🇩",
  ms = "🇲🇾",
  tr = "🇹🇷",
  pl = "🇵🇱",
  nl = "🇳🇱",
  sv = "🇸🇪",
  da = "🇩🇰",
  no = "🇳🇴",
  fi = "🇫🇮",
}

local function get_flag_for_locale(locale)
  return M.locale_flags[locale] or "🌐"
end

local function truncate_text(text, max_width)
  if #text <= max_width then
    return text
  end
  return text:sub(1, max_width - 3) .. "..."
end

M.clear_virtual_text = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
end

M.render_key_translation = function(bufnr, key_info, locale)
  local cfg = config.get()
  locale = locale or cfg.default_locale
  
  if not cfg.virtual_text.enabled then
    return
  end
  
  local translation = loader.get_translation(key_info.key, locale)
  if not translation then
    return
  end
  
  local flag = get_flag_for_locale(locale)
  local truncated = truncate_text(translation, cfg.virtual_text.max_width)
  local text = flag .. " " .. cfg.virtual_text.prefix .. truncated .. cfg.virtual_text.suffix
  
  local start_row = key_info.range[1]
  local end_col = key_info.range[4]
  
  vim.api.nvim_buf_set_extmark(bufnr, M.namespace, start_row, end_col, {
    virt_text = { { text, cfg.virtual_text.highlight } },
    virt_text_pos = cfg.virtual_text.position,
    hl_mode = "combine",
  })
end

M.render_all_translations = function(bufnr, locale)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  M.clear_virtual_text(bufnr)
  
  if not M.enabled then
    return
  end
  
  local keys = treesitter.find_i18n_keys_in_buffer(bufnr)
  
  for _, key_info in ipairs(keys) do
    M.render_key_translation(bufnr, key_info, locale)
  end
end

M.render_cursor_translation = function(bufnr, locale)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  local key_info = treesitter.find_i18n_key_at_cursor(bufnr)
  if not key_info then
    return
  end
  
  M.render_key_translation(bufnr, key_info, locale)
end

M.toggle = function()
  M.enabled = not M.enabled
  local bufnr = vim.api.nvim_get_current_buf()
  
  if M.enabled then
    M.render_all_translations(bufnr)
    vim.notify("i18n virtual text enabled", vim.log.levels.INFO)
  else
    M.clear_virtual_text(bufnr)
    vim.notify("i18n virtual text disabled", vim.log.levels.INFO)
  end
end

M.set_locale = function(locale)
  local cfg = config.get()
  cfg.default_locale = locale
  
  if M.enabled then
    local bufnr = vim.api.nvim_get_current_buf()
    M.render_all_translations(bufnr)
  end
  
  vim.notify("i18n locale changed to: " .. locale, vim.log.levels.INFO)
end

M.get_available_locales = function()
  local info = loader.get_project_info()
  return info.available_locales
end

M.setup_autocommands = function()
  local augroup = vim.api.nvim_create_augroup("i18n_virtual_text", { clear = true })
  
  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
    group = augroup,
    callback = function()
      if M.enabled then
        local bufnr = vim.api.nvim_get_current_buf()
        vim.defer_fn(function()
          M.render_all_translations(bufnr)
        end, 100)
      end
    end,
  })
  
  vim.api.nvim_create_autocmd("BufLeave", {
    group = augroup,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      M.clear_virtual_text(bufnr)
    end,
  })
end

M.is_enabled = function()
  return M.enabled
end

return M
