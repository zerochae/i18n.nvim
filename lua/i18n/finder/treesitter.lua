local M = {}
local config = require("i18n.core.config")

M.parsers = {
  javascript = {
    queries = {
      [[
        ; t('key') pattern
        (call_expression
          function: (identifier) @func (#eq? @func "t")
          arguments: (arguments
            (string (string_fragment) @key)))
      ]],
      [[
        ; i18n.t('key') pattern  
        (call_expression
          function: (member_expression
            property: (property_identifier) @method (#eq? @method "t"))
          arguments: (arguments
            (string (string_fragment) @key)))
      ]],
      [[
        ; $t('key') pattern (Vue)
        (call_expression
          function: (identifier) @func (#match? @func "^\\$t$")
          arguments: (arguments
            (string (string_fragment) @key)))
      ]],
    },
  },
  typescript = {
    queries = {
      [[
        ; t('key') pattern
        (call_expression
          function: (identifier) @func (#eq? @func "t")
          arguments: (arguments
            (string (string_fragment) @key)))
      ]],
      [[
        ; i18n.t('key') pattern
        (call_expression
          function: (member_expression
            property: (property_identifier) @method (#eq? @method "t"))
          arguments: (arguments
            (string (string_fragment) @key)))
      ]],
    },
  },
  tsx = {
    queries = {
      [[
        ; t('key') pattern
        (call_expression
          function: (identifier) @func (#eq? @func "t")
          arguments: (arguments
            (string (string_fragment) @key)))
      ]],
      [[
        ; i18n.t('key') pattern
        (call_expression
          function: (member_expression
            property: (property_identifier) @method (#eq? @method "t"))
          arguments: (arguments
            (string (string_fragment) @key)))
      ]],
    },
  },
  vue = {
    queries = {
      [[
        ; $t('key') pattern
        (call_expression
          function: (identifier) @func (#match? @func "^\\$t$")
          arguments: (arguments
            (string (string_fragment) @key)))
      ]],
    },
  },
}

local function get_parser_lang(bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  
  local lang_map = {
    javascript = "javascript",
    typescript = "typescript", 
    typescriptreact = "tsx",
    javascriptreact = "javascript",
    vue = "vue",
    jsx = "javascript",
    js = "javascript",
    ts = "typescript",
  }
  
  return lang_map[ft]
end

M.find_i18n_keys_in_buffer = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  local parser_lang = get_parser_lang(bufnr)
  if not parser_lang or not M.parsers[parser_lang] then
    return {}
  end
  
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, parser_lang)
  if not ok then
    return {}
  end
  
  local keys = {}
  local tree = parser:parse()[1]
  local root = tree:root()
  
  for _, query_str in ipairs(M.parsers[parser_lang].queries) do
    local query = vim.treesitter.query.parse(parser_lang, query_str)
    
    for id, node, _ in query:iter_captures(root, bufnr) do
      local capture_name = query.captures[id]
      if capture_name == "key" then
        local key = vim.treesitter.get_node_text(node, bufnr)
        local start_row, start_col, end_row, end_col = node:range()
        
        table.insert(keys, {
          key = key,
          node = node,
          range = { start_row, start_col, end_row, end_col },
          bufnr = bufnr,
        })
      end
    end
  end
  
  return keys
end

M.find_i18n_key_at_cursor = function(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row, cursor_col = cursor[1] - 1, cursor[2]
  
  local keys = M.find_i18n_keys_in_buffer(bufnr)
  
  for _, key_info in ipairs(keys) do
    local start_row, start_col, end_row, end_col = unpack(key_info.range)
    
    if cursor_row >= start_row and cursor_row <= end_row then
      if cursor_row == start_row and cursor_row == end_row then
        if cursor_col >= start_col and cursor_col <= end_col then
          return key_info
        end
      elseif cursor_row == start_row then
        if cursor_col >= start_col then
          return key_info
        end
      elseif cursor_row == end_row then
        if cursor_col <= end_col then
          return key_info
        end
      else
        return key_info
      end
    end
  end
  
  return nil
end

M.find_all_i18n_keys_in_project = function()
  local root = require("i18n.core.loader").get_project_info().root
  if not root then
    return {}
  end
  
  local extensions = { "js", "ts", "tsx", "jsx", "vue" }
  local all_keys = {}
  
  for _, ext in ipairs(extensions) do
    local files = vim.fn.globpath(root, "**/*." .. ext, false, true)
    
    for _, file in ipairs(files) do
      if vim.fn.filereadable(file) == 1 then
        local bufnr = vim.fn.bufnr(file, true)
        if bufnr ~= -1 then
          vim.fn.bufload(bufnr)
          local keys = M.find_i18n_keys_in_buffer(bufnr)
          
          for _, key_info in ipairs(keys) do
            key_info.file = file
            table.insert(all_keys, key_info)
          end
        end
      end
    end
  end
  
  return all_keys
end

M.get_supported_filetypes = function()
  local filetypes = {}
  for lang, _ in pairs(M.parsers) do
    table.insert(filetypes, lang)
  end
  return filetypes
end

return M