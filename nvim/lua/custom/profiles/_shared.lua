-- Shared helpers for JS/TS-family profiles (node, react, vue).
local M = {}

-- Walk up from the buffer to the nearest package.json and check whether the
-- project actually depends on prettier. Some projects (e.g. Nuxt with
-- `@nuxt/eslint` `stylistic: true`) use ESLint's own stylistic rules instead
-- of prettier — running prettier anyway fights those rules every save.
local function uses_prettier(bufnr)
  local dirname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':h')
  local pkg = vim.fs.find('package.json', { path = dirname, upward = true })[1]
  if not pkg then return false end

  local f = io.open(pkg, 'r')
  if not f then return false end
  local content = f:read '*a'
  f:close()

  local ok, data = pcall(vim.json.decode, content)
  if not ok or type(data) ~= 'table' then return false end

  return (data.dependencies and data.dependencies.prettier ~= nil)
    or (data.devDependencies and data.devDependencies.prettier ~= nil)
end

-- Formatter chain for js/ts/vue filetypes: prettier (if the project depends on
-- it) formats first, eslint_d applies lint auto-fixes last so its fixes are
-- the final state. If the project has no prettier dependency, eslint_d alone
-- owns formatting (it's the project's actual configured style authority).
function M.js_formatters(bufnr)
  if uses_prettier(bufnr) then
    return { 'prettier', 'eslint_d' }
  end
  return { 'eslint_d' }
end

return M
