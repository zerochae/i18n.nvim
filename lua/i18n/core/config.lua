local M = {}

-- 기본 설정 값
M.config = {
  projects = {},
}

-- 설정 함수
M.setup = function(opts)
  if opts and opts.projects then
    if type(opts.projects) ~= "table" then
      error "projects must be a table (e.g., { projectA = { locales_path = '...', languages = {...} } })"
    end
  end
  M.config = vim.tbl_extend("force", M.config, opts or {})
end

return M
