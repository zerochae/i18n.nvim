local M = {}

-- Core 모듈
M.config = require "i18n.core.config"
M.loader = require "i18n.core.loader"

-- Finder 모듈
M.treesitter = require "i18n.finder.treesitter"
M.telescope = require "i18n.finder.telescope"

-- Renderer 모듈
M.virtual_text = require "i18n.renderer.virtual_text"

return M
