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

-- Project-wide diagnostics for ts_ls-family profiles.
--
-- ts_ls/vue_ls (unlike Roslyn) have no "analyze whole project" server setting —
-- they only ever report diagnostics for open buffers. To get solution-wide
-- coverage under `<leader>xx` we instead shell out to the project's own
-- compiler binary (tsc / vue-tsc), parse its output, and attach the results
-- to buffers via vim.diagnostic.set — Trouble picks these up like any other
-- diagnostic source and live-refreshes as they land.
local diag_ns = vim.api.nvim_create_namespace 'workspace_diagnostics_tsc'
local prev_bufs = {}

local function local_bin(name, cwd)
  local path = cwd .. '/node_modules/.bin/' .. name
  if vim.fn.executable(path) == 1 then return path end
  return nil
end

-- `bin_name` is 'tsc' or 'vue-tsc'. Silently no-ops if the project doesn't
-- have it installed locally (no global fallback — avoids running some
-- unrelated globally-installed compiler against the wrong project).
function M.run_tsc_diagnostics(bin_name)
  local cwd = vim.fn.getcwd()
  local bin = local_bin(bin_name, cwd)
  if not bin then return end

  vim.system({ bin, '--noEmit', '--pretty', 'false' }, { cwd = cwd, text = true }, function(result)
    local by_file = {}
    for line in (result.stdout or ''):gmatch '[^\r\n]+' do
      local file, lnum, col, sev, code, msg = line:match '^(.-)%((%d+),(%d+)%): (%a+) (TS%d+): (.*)$'
      if file then
        local abs = vim.fn.fnamemodify(file, ':p')
        by_file[abs] = by_file[abs] or {}
        table.insert(by_file[abs], {
          lnum     = tonumber(lnum) - 1,
          col      = tonumber(col) - 1,
          severity = sev == 'error' and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
          message  = code .. ': ' .. msg,
          source   = bin_name,
        })
      end
    end

    vim.schedule(function()
      -- Clear last run's diagnostics first so files that got fixed don't
      -- keep showing stale errors.
      for _, bufnr in ipairs(prev_bufs) do vim.diagnostic.set(diag_ns, bufnr, {}) end
      prev_bufs = {}
      for file, diags in pairs(by_file) do
        local bufnr = vim.fn.bufadd(file)
        vim.diagnostic.set(diag_ns, bufnr, diags)
        table.insert(prev_bufs, bufnr)
      end
    end)
  end)
end

return M
