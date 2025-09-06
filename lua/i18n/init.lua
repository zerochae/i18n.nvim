local M = {}

M.config = require("i18n.core.config")
M.loader = require("i18n.core.loader")
M.treesitter = require("i18n.finder.treesitter")
M.virtual_text = require("i18n.renderer.virtual_text")

M.setup = function(opts)
  M.config.setup(opts or {})
  
  M.virtual_text.setup_autocommands()
  
  M.setup_commands()
  M.setup_keymaps()
  
  if M.config.get().auto_setup then
    M.enable()
  end
end

M.setup_commands = function()
  vim.api.nvim_create_user_command("I18nToggle", function()
    M.virtual_text.toggle()
  end, { desc = "Toggle i18n virtual text display" })
  
  vim.api.nvim_create_user_command("I18nEnable", function()
    M.enable()
  end, { desc = "Enable i18n virtual text" })
  
  vim.api.nvim_create_user_command("I18nDisable", function()
    M.disable()
  end, { desc = "Disable i18n virtual text" })
  
  vim.api.nvim_create_user_command("I18nSetLocale", function(args)
    if not args.args or args.args == "" then
      local available = M.virtual_text.get_available_locales()
      if #available == 0 then
        vim.notify("No locale files found", vim.log.levels.WARN)
        return
      end
      vim.ui.select(available, {
        prompt = "Select locale:",
      }, function(choice)
        if choice then
          M.virtual_text.set_locale(choice)
        end
      end)
    else
      M.virtual_text.set_locale(args.args)
    end
  end, { 
    nargs = "?", 
    desc = "Set i18n locale",
    complete = function()
      return M.virtual_text.get_available_locales()
    end
  })
  
  vim.api.nvim_create_user_command("I18nInfo", function()
    local info = M.loader.get_project_info()
    local current_locale = M.config.get().default_locale
    local is_enabled = M.virtual_text.is_enabled()
    
    print("i18n.nvim Status:")
    print("  Enabled: " .. (is_enabled and "Yes" or "No"))
    print("  Current locale: " .. current_locale)
    print("  Project root: " .. (info.root or "Not found"))
    print("  Locales directory: " .. (info.locales_dir or "Not found"))
    print("  Available locales: " .. table.concat(info.available_locales, ", "))
  end, { desc = "Show i18n plugin information" })
end

M.setup_keymaps = function()
  local cfg = M.config.get()
  
  if cfg.keymaps.toggle then
    vim.keymap.set("n", cfg.keymaps.toggle, function()
      M.virtual_text.toggle()
    end, { desc = "Toggle i18n translations" })
  end
  
  if cfg.keymaps.next_key then
    vim.keymap.set("n", cfg.keymaps.next_key, function()
      M.goto_next_key()
    end, { desc = "Go to next i18n key" })
  end
  
  if cfg.keymaps.prev_key then
    vim.keymap.set("n", cfg.keymaps.prev_key, function()
      M.goto_prev_key()
    end, { desc = "Go to previous i18n key" })
  end
end

M.enable = function()
  M.virtual_text.enabled = true
  local bufnr = vim.api.nvim_get_current_buf()
  M.virtual_text.render_all_translations(bufnr)
  vim.notify("i18n.nvim enabled", vim.log.levels.INFO)
end

M.disable = function()
  M.virtual_text.enabled = false
  local bufnr = vim.api.nvim_get_current_buf()
  M.virtual_text.clear_virtual_text(bufnr)
  vim.notify("i18n.nvim disabled", vim.log.levels.INFO)
end

M.goto_next_key = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local keys = M.treesitter.find_i18n_keys_in_buffer(bufnr)
  
  if #keys == 0 then
    vim.notify("No i18n keys found in buffer", vim.log.levels.WARN)
    return
  end
  
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor[1] - 1
  
  for _, key_info in ipairs(keys) do
    local start_row = key_info.range[1]
    if start_row > cursor_row then
      vim.api.nvim_win_set_cursor(0, { start_row + 1, key_info.range[2] })
      return
    end
  end
  
  vim.api.nvim_win_set_cursor(0, { keys[1].range[1] + 1, keys[1].range[2] })
end

M.goto_prev_key = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local keys = M.treesitter.find_i18n_keys_in_buffer(bufnr)
  
  if #keys == 0 then
    vim.notify("No i18n keys found in buffer", vim.log.levels.WARN)
    return
  end
  
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = cursor[1] - 1
  
  for i = #keys, 1, -1 do
    local key_info = keys[i]
    local start_row = key_info.range[1]
    if start_row < cursor_row then
      vim.api.nvim_win_set_cursor(0, { start_row + 1, key_info.range[2] })
      return
    end
  end
  
  local last_key = keys[#keys]
  vim.api.nvim_win_set_cursor(0, { last_key.range[1] + 1, last_key.range[2] })
end

M.toggle = function()
  M.virtual_text.toggle()
end

M.set_locale = function(locale)
  M.virtual_text.set_locale(locale)
end

M.get_translation = function(key, locale)
  return M.loader.get_translation(key, locale)
end

return M
