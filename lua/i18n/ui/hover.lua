local M = {}
local config = require("i18n.core.config")
local loader = require("i18n.core.loader")
local treesitter = require("i18n.finder.treesitter")
local virtual_text = require("i18n.renderer.virtual_text")

M.current_window = nil
M.current_buffer = nil

local function close_hover_window()
  if M.current_window and vim.api.nvim_win_is_valid(M.current_window) then
    vim.api.nvim_win_close(M.current_window, true)
  end
  if M.current_buffer and vim.api.nvim_buf_is_valid(M.current_buffer) then
    vim.api.nvim_buf_delete(M.current_buffer, { force = true })
  end
  M.current_window = nil
  M.current_buffer = nil
end

local function get_flag_for_locale(locale)
  return virtual_text.locale_flags[locale] or "🌐"
end

local function format_hover_content(key, translations)
  local lines = {}
  local cfg = config.get()
  
  -- Header
  table.insert(lines, "🌍 i18n Translation Key")
  table.insert(lines, "")
  table.insert(lines, "Key: " .. key)
  table.insert(lines, "")
  
  -- Current locale first
  local current_locale = cfg.default_locale
  if translations[current_locale] then
    local flag = get_flag_for_locale(current_locale)
    table.insert(lines, string.format("%s %s (current)", flag, current_locale:upper()))
    table.insert(lines, "  " .. translations[current_locale])
    table.insert(lines, "")
  end
  
  -- Other locales
  local other_locales = {}
  for locale, _ in pairs(translations) do
    if locale ~= current_locale then
      table.insert(other_locales, locale)
    end
  end
  table.sort(other_locales)
  
  if #other_locales > 0 then
    table.insert(lines, "Other Languages:")
    for _, locale in ipairs(other_locales) do
      local flag = get_flag_for_locale(locale)
      table.insert(lines, string.format("%s %s", flag, locale:upper()))
      table.insert(lines, "  " .. translations[locale])
      table.insert(lines, "")
    end
  end
  
  -- Remove last empty line
  if #lines > 0 and lines[#lines] == "" then
    table.remove(lines)
  end
  
  return lines
end

local function calculate_window_size(content)
  local cfg = config.get().hover
  local width = 0
  local height = #content
  
  for _, line in ipairs(content) do
    local line_width = vim.fn.strdisplaywidth(line)
    if line_width > width then
      width = line_width
    end
  end
  
  -- Add padding and apply limits
  width = math.min(width + 4, cfg.max_width, vim.o.columns - 4)
  height = math.min(height + 2, cfg.max_height, vim.o.lines - 4)
  
  return width, height
end

local function create_hover_window(content, cursor_pos)
  local width, height = calculate_window_size(content)
  
  -- Calculate position
  local cursor_row, cursor_col = cursor_pos[1], cursor_pos[2]
  local row = cursor_row - vim.fn.line('w0') + 1
  local col = cursor_col
  
  -- Adjust position if window would go off-screen
  if col + width > vim.o.columns then
    col = vim.o.columns - width - 1
  end
  if row + height > vim.o.lines then
    row = row - height - 2
  end
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  -- Create window
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    focusable = false,
    zindex = 50,
  }
  
  local win = vim.api.nvim_open_win(buf, false, opts)
  
  -- Set window options
  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_win_set_option(win, 'cursorline', false)
  vim.api.nvim_win_set_option(win, 'winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder')
  
  M.current_window = win
  M.current_buffer = buf
  
  return win, buf
end

M.show_hover = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  -- Close existing hover window
  close_hover_window()
  
  local key_info = treesitter.find_i18n_key_at_cursor(bufnr)
  if not key_info then
    return false
  end
  
  local translations = loader.load_all_translations()
  
  -- Get translations for this key
  local key_translations = {}
  for locale, translation_data in pairs(translations) do
    local translation = loader.get_translation(key_info.key, locale)
    if translation then
      key_translations[locale] = translation
    end
  end
  
  if vim.tbl_count(key_translations) == 0 then
    return false
  end
  
  local content = format_hover_content(key_info.key, key_translations)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  
  create_hover_window(content, cursor_pos)
  
  return true
end

M.hide_hover = function()
  close_hover_window()
end

M.toggle_hover = function()
  if M.current_window then
    M.hide_hover()
  else
    M.show_hover()
  end
end

M.is_hover_visible = function()
  return M.current_window ~= nil and vim.api.nvim_win_is_valid(M.current_window)
end

-- Auto-hide hover when cursor moves
local hover_augroup = vim.api.nvim_create_augroup("i18n_hover", { clear = true })

M.setup_autocommands = function()
  local cfg = config.get()
  
  if not cfg.hover or not cfg.hover.enabled then
    return
  end
  
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = hover_augroup,
    callback = function()
      if M.is_hover_visible() then
        M.hide_hover()
      end
    end,
  })
  
  vim.api.nvim_create_autocmd("BufLeave", {
    group = hover_augroup,
    callback = function()
      M.hide_hover()
    end,
  })
  
  if cfg.hover.auto_show then
    vim.api.nvim_create_autocmd("CursorHold", {
      group = hover_augroup,
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
        
        -- Only show in supported file types
        local supported_fts = { "javascript", "typescript", "typescriptreact", "javascriptreact", "vue" }
        if vim.tbl_contains(supported_fts, ft) then
          M.show_hover(bufnr)
        end
      end,
    })
  end
end

M.clear_autocommands = function()
  vim.api.nvim_clear_autocmds({ group = hover_augroup })
end

return M