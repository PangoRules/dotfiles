-- C# / .NET profile: roslyn.nvim LSP + CSharpier formatter + netcoredbg DAP + neotest
--
-- Roslyn (and roslyn.nvim) use the LSP *pull* diagnostics model, refreshed only for
-- buffers already attached to the client (see roslyn.nvim's
-- workspace/projectInitializationComplete handler — it loops `attached_buffers`, nothing
-- else). The `fullSolution` background_analysis scope set below only widens how much a
-- given pulled document gets analyzed; it does NOT make anything pull documents that were
-- never opened. So solution-wide diagnostics still need an explicit `workspace/diagnostic`
-- pull, done in `workspace_diagnostics` below.
local diag_ns = vim.api.nvim_create_namespace 'workspace_diagnostics_roslyn'
local prev_bufs = {}

return {
  treesitter = { 'c_sharp' },

  mason = {
    'roslyn',    -- C# LSP (from github:Crashdummyy/mason-registry)
    'csharpier', -- C# formatter
    'netcoredbg', -- .NET debugger
  },

  -- No lsp_setup: roslyn.nvim auto-attaches on ft=cs
  formatters = {
    cs = { 'csharpier' },
  },

  -- Explicit workspace-wide pull: roslyn.nvim never calls this itself (see note above).
  -- Populates vim.diagnostic for every file with issues, not just open buffers.
  workspace_diagnostics = function()
    for _, client in ipairs(vim.lsp.get_clients { name = 'roslyn' }) do
      client:request('workspace/diagnostic', { previousResultIds = {} }, function(err, result)
        if err or not result then return end

        for _, bufnr in ipairs(prev_bufs) do vim.diagnostic.set(diag_ns, bufnr, {}) end
        prev_bufs = {}

        for _, item in ipairs(result.items or {}) do
          if item.kind ~= 'unchanged' and item.items then
            local bufnr = vim.uri_to_bufnr(item.uri)
            local diags = {}
            for _, d in ipairs(item.items) do
              table.insert(diags, {
                lnum     = d.range.start.line,
                col      = d.range.start.character,
                end_lnum = d.range['end'].line,
                end_col  = d.range['end'].character,
                severity = d.severity or vim.diagnostic.severity.HINT,
                message  = d.message,
                code     = d.code,
                source   = d.source or 'roslyn',
              })
            end
            vim.diagnostic.set(diag_ns, bufnr, diags)
            table.insert(prev_bufs, bufnr)
          end
        end
      end)
    end
  end,

  extra_specs = {
    {
      'seblyng/roslyn.nvim',
      ft = 'cs',
      opts = function()
        local ok, blink = pcall(require, 'blink.cmp')
        local cap = ok and blink.get_lsp_capabilities() or vim.lsp.protocol.make_client_capabilities()
        return {
          config = {
            capabilities = cap,
            settings = {
              -- These keys use the LSP convention "section|subsection" — they are passed
              -- verbatim to the Roslyn language server as server-specific configuration,
              -- not interpreted as Lua table keys.
              ['csharp|inlay_hints'] = {
                csharp_enable_inlay_hints_for_implicit_variable_types = true,
                csharp_enable_inlay_hints_for_types = true,
                dotnet_enable_inlay_hints_for_parameters = true,
                dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
                dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
              },
              ['csharp|completion'] = {
                dotnet_show_completion_items_from_unimported_namespaces = true,
                dotnet_show_name_completion_suggestions = true,
              },
              ['csharp|code_lens'] = {
                dotnet_enable_references_code_lens = true,
              },
              -- Default scope is "openFiles" — Roslyn only analyzes buffers you have
              -- open. "fullSolution" makes it analyze + push diagnostics for every
              -- project file, so <leader>xx shows solution-wide issues, not just
              -- whatever's currently loaded.
              ['csharp|background_analysis'] = {
                dotnet_analyzer_diagnostics_scope = 'fullSolution',
                dotnet_compiler_diagnostics_scope = 'fullSolution',
              },
            },
          },
        }
      end,
    },

    {
      'theHamsta/nvim-dap-virtual-text',
      opts = { enabled = true },
    },

    {
      'mfussenegger/nvim-dap',
      dependencies = {
        'rcarriga/nvim-dap-ui',
        'nvim-neotest/nvim-nio',
      },
      config = function()
        local dap = require 'dap'
        local dapui = require 'dapui'

        -- netcoredbg adapter
        dap.adapters.coreclr = {
          type = 'executable',
          command = vim.fn.stdpath 'data' .. '/mason/packages/netcoredbg/netcoredbg',
          args = { '--interpreter=vscode' },
        }

        -- Glob cwd for ASP.NET entry-point DLLs: name matches project folder,
        -- has runtimeconfig.json + appsettings.json, and is not a test project.
        local function find_entry_dlls(cwd)
          local dlls = {}
          local all = vim.fn.glob(cwd .. '/**/bin/Debug/net*/*.dll', false, true)
          for _, dll in ipairs(all) do
            -- Extract the directory name immediately before "/bin/" — this is the
            -- project name (e.g. ".../MyApp/bin/Debug/net8.0/MyApp.dll" → "MyApp").
            local project = dll:match '.*/([^/]+)/bin/'
            -- Extract the filename without the .dll extension
            -- (e.g. ".../MyApp.dll" → "MyApp").
            local dllname = dll:match '/([^/]+)%.dll$'
            if project and dllname == project and not dll:match '/tests/' then
              local dir = dll:match '(.*)/[^/]+$'
              local has_cfg      = vim.fn.filereadable((dll:gsub('%.dll$', '.runtimeconfig.json'))) == 1
              local has_settings = vim.fn.filereadable(dir .. '/appsettings.json') == 1
              if has_cfg and has_settings then table.insert(dlls, dll) end
            end
          end
          return dlls
        end

        -- Pick which discovered dll to launch. Prefer the project that contains the
        -- current buffer (so F5 in Server/Program.cs launches Server even if another
        -- project, e.g. Tui, was built more recently); otherwise fall back to newest build.
        local function pick_entry_dll(dlls)
          if #dlls == 0 then return nil end
          local bufpath = vim.api.nvim_buf_get_name(0)
          if bufpath ~= '' then
            for _, dll in ipairs(dlls) do
              local proj_dir = dll:match '(.*)/bin/'
              if proj_dir and bufpath:sub(1, #proj_dir) == proj_dir then return dll end
            end
          end
          if #dlls > 1 then
            table.sort(dlls, function(a, b) return vim.fn.getftime(a) > vim.fn.getftime(b) end)
          end
          return dlls[1]
        end

        -- C# launch config — auto-detects the project dll, falls back to prompt
        dap.configurations.cs = {
          {
            type = 'coreclr',
            name = 'Launch',
            request = 'launch',
            program = function()
              local cwd = vim.fn.getcwd()
              local dll = pick_entry_dll(find_entry_dlls(cwd))
              if not dll then return vim.fn.input('Path to dll: ', cwd .. '/', 'file') end
              return dll
            end,
            cwd = function()
              local root = vim.fn.getcwd()
              local dll = pick_entry_dll(find_entry_dlls(root))
              if dll then return dll:match '(.*)/bin/' end
              return root
            end,
            env = { ASPNETCORE_ENVIRONMENT = 'Development' },
            justMyCode = false,
            stopAtEntry = false,
          },
        }

        dapui.setup {
          layouts = {
            {
              elements = {
                { id = 'scopes', size = 0.25 },
                'breakpoints',
                'stacks',
                'watches',
              },
              size = 40,
              position = 'left',
            },
            {
              elements = {
                { id = 'repl', size = 0.75 },
                { id = 'console', size = 0.25 },
              },
              size = 0.3,
              position = 'bottom',
            },
          },
        }

        -- When the debugger starts (event_initialized fires after the adapter is ready),
        -- automatically open the DAP UI panels so the user doesn't have to do it manually.
        dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
        -- Use `after` so nvim-dap cleans up the session first; if dapui errors in 0.13+
        -- the session is already gone and won't linger to reject future breakpoints.
        dap.listeners.after.event_terminated['dapui_config'] = function() pcall(dapui.close) end
        dap.listeners.after.event_exited['dapui_config']     = function() pcall(dapui.close) end

        -- Override nvim-dap's default letter signs with icons; also re-forces the
        -- definition after nvim-dap's sign_try_define runs at module load time.
        vim.fn.sign_define('DapBreakpoint',          { text = '●', texthl = 'DiagnosticError',   linehl = '', numhl = '' })
        vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn',    linehl = '', numhl = '' })
        vim.fn.sign_define('DapBreakpointRejected',  { text = '○', texthl = 'DiagnosticError',   linehl = '', numhl = '' })
        vim.fn.sign_define('DapLogPoint',            { text = '◎', texthl = 'DiagnosticInfo',    linehl = '', numhl = '' })
        vim.fn.sign_define('DapStopped',             { text = '→', texthl = 'DiagnosticWarn',    linehl = 'debugPC', numhl = '' })

        require('which-key').add {
          { '<leader>d',  group = '[D]ebug' },
          { '<leader>dw', group = '[D]ebug [W]atch' },
        }
        local k = vim.keymap.set
        local widgets = require 'dap.ui.widgets'

        -- Core debugger controls (function keys mirror VS/VSCode conventions)
        k('n', '<F5>',       dap.continue,         { desc = 'Debug: Start / Continue' })
        k('n', '<F10>',      dap.step_over,         { desc = 'Debug: Step Over' })
        k('n', '<S-F10>',    dap.step_into,         { desc = 'Debug: Step Into' })
        k('n', '<F12>',      dap.step_out,          { desc = 'Debug: Step Out' })
        k('n', '<leader>di', dap.step_into,         { desc = 'Debug: Step Into' })
        k('n', '<leader>dj', dap.step_over,         { desc = 'Debug: Step Over' })
        k('n', '<leader>dk', dap.step_out,          { desc = 'Debug: Step Out' })
        k('n', '<leader>db', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
        k('n', '<leader>du', dapui.toggle,          { desc = 'Debug: Toggle UI' })
        k('n', '<leader>dr', dap.restart,           { desc = 'Debug: Restart' })
        k('n', '<leader>dc', dap.run_to_cursor,     { desc = 'Debug: Run to Cursor' })
        k('n', '<leader>dl', dap.run_last,          { desc = 'Debug: Run Last' })

        k('n', '<leader>dB', function()
          dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end, { desc = 'Debug: Conditional Breakpoint' })
        k('n', '<leader>dbc', function() dap.clear_breakpoints() end, { desc = 'Debug: Clear all Breakpoints' })

        -- QuickWatch: evaluate word under cursor (or visual selection) in a float
        k('n', '<leader>dwe', function() dapui.eval() end,  { desc = 'Debug: Eval under cursor' })
        k('v', '<leader>dwe', function() dapui.eval() end,  { desc = 'Debug: Eval selection' })

        -- Hover widget: inline float with current value (lighter than eval)
        k('n', '<leader>dwh', function() widgets.hover() end, { desc = 'Debug: Hover variable' })
        k('v', '<leader>dwh', function() widgets.hover() end, { desc = 'Debug: Hover selection' })

        -- Open watches panel focused so you can press `a` to add, `d` to delete
        k('n', '<leader>dww', function()
          dapui.float_element('watches', { enter = true })
        end, { desc = 'Debug: Watches panel' })

        -- Scopes panel (Locals) in a float — useful when the sidebar is too narrow
        k('n', '<leader>dws', function()
          dapui.float_element('scopes', { enter = true })
        end, { desc = 'Debug: Scopes float (Locals)' })
      end,
    },

    {
      -- Two upstream neotest-dotnet bugs patched here. build hook re-applies both
      -- whenever the plugin gets (re)built.
      --
      -- `pin = true` below is load-bearing: lazy-lock.json pins this plugin to a
      -- specific commit, and every `:Lazy update`/`sync` resyncs the checkout back
      -- to that exact locked commit before doing anything else — discarding any
      -- local commit sitting on top, every single time, not just once. So the
      -- patch can never survive an update by being committed; it survives by lazy
      -- never touching this plugin's checkout after the initial install. If you
      -- ever *want* to pull upstream neotest-dotnet changes, unpin, update, then
      -- re-pin (the build hook will reapply + recommit the patches on that build).
      --
      -- 1. Breaks on nvim 0.11+ because iter_matches changed captures[1] from
      --    TSNode to TSNode[] (framework-discovery.lua).
      -- 2. build_spec_utils.create_specs() returns `#specs < 0 and nil or specs`
      --    — 0 is never < 0, so a "file" run that resolves zero specs (e.g. a
      --    re-run racing a still-in-flight prior run for the same position)
      --    returns `{}` instead of `nil`. neotest's runner.lua then wraps that
      --    empty table as a bogus single spec with no fields, and results()
      --    crashes on `spec.context.results_path` — "attempt to index field
      --    'context' (a nil value)". Patched to `#specs == 0` so it returns nil,
      --    which routes through neotest's normal "no tests found" path instead.
      'Issafalcon/neotest-dotnet',
      pin = true,
      build = function(plugin)
        local patch = vim.fn.stdpath('config') .. '/lua/custom/patches/neotest_dotnet_framework_discovery.lua'
        local target = plugin.dir .. '/lua/neotest-dotnet/framework-discovery.lua'
        local ok = vim.fn.system({ 'cp', patch, target })
        if vim.v.shell_error ~= 0 then
          vim.notify('neotest-dotnet patch failed: ' .. ok, vim.log.levels.ERROR)
        else
          vim.notify('neotest-dotnet: nvim 0.11+ patch applied', vim.log.levels.INFO)
        end

        local bsu_target = plugin.dir .. '/lua/neotest-dotnet/utils/build-spec-utils.lua'
        local lines = vim.fn.readfile(bsu_target)
        local patched = false
        for i, line in ipairs(lines) do
          if line:find('#specs < 0 and nil or specs', 1, true) then
            lines[i] = (line:gsub('#specs < 0', '#specs == 0'))
            patched = true
            break
          end
        end
        if patched then
          vim.fn.writefile(lines, bsu_target)
          vim.notify('neotest-dotnet: empty-specs patch applied', vim.log.levels.INFO)
        else
          vim.notify('neotest-dotnet: empty-specs patch target not found (upstream changed?)', vim.log.levels.WARN)
        end

        -- Commit so the tree is clean again — see note above on why this must
        -- happen every build, not just once.
        vim.fn.system({ 'git', '-C', plugin.dir, 'diff', '--quiet' })
        if vim.v.shell_error ~= 0 then
          vim.fn.system({ 'git', '-C', plugin.dir, 'add', '-A' })
          vim.fn.system {
            'git', '-C', plugin.dir, 'commit', '-m',
            'chore: reapply nvim 0.11+ / empty-specs local patches',
          }
        end
      end,
    },

    {
      -- neotest's discovery subprocess (lib/subprocess.lua) is a bare `-u NONE`
      -- headless nvim. It adds installed treesitter parser directories to the
      -- child's rtp, but never loads nvim-treesitter itself, so the child never
      -- runs the `vim.treesitter.language.register('c_sharp', 'cs')` call that
      -- makes filetype "cs" resolve to parser "cs.so" — the child looks for a
      -- literal `parser/cs.so`, doesn't find one (parser is `c_sharp.so`), and
      -- every .cs discovery in the child throws "No parser for language 'cs'".
      -- Confirmed by reproducing a bare `-u NONE` instance directly: registering
      -- the alias before parsing fixes it, nothing else does (a `cs.so` symlink
      -- does NOT work — dlsym looks for the symbol `tree_sitter_cs`, which only
      -- exists in a real cs grammar, not in c_sharp.so under a fake name).
      -- Patched to register the alias in the child right after rtp setup.
      -- Same `pin = true` / build-hook-commits caveat as neotest-dotnet above.
      'nvim-neotest/neotest',
      pin = true,
      dependencies = {
        'nvim-neotest/nvim-nio',
        'nvim-lua/plenary.nvim',
        'antoinemadec/FixCursorHold.nvim',
        'nvim-treesitter/nvim-treesitter',
        'Issafalcon/neotest-dotnet',
      },
      build = function(plugin)
        local target = plugin.dir .. '/lua/neotest/lib/subprocess.lua'
        local lines = vim.fn.readfile(target)
        local marker = 'neotest.lib.subprocess.add_paths_to_rtp(paths_to_add)'
        local already = false
        local patched = false
        for _, line in ipairs(lines) do
          if line:find('register', 1, true) and line:find('c_sharp', 1, true) then
            already = true
            break
          end
        end
        if not already then
          for i, line in ipairs(lines) do
            if line:find(marker, 1, true) then
              table.insert(lines, i + 1, '')
              table.insert(lines, i + 2, [[    -- nvim 0.11+/c_sharp fix: see custom.profiles.dotnet for why.]])
              table.insert(lines, i + 3, [[    nio.fn.rpcrequest(child_chan, "nvim_exec_lua", "pcall(vim.treesitter.language.register, 'c_sharp', 'cs')", {})]])
              patched = true
              break
            end
          end
        end
        if patched then
          vim.fn.writefile(lines, target)
          vim.notify('neotest: c_sharp/cs subprocess alias patch applied', vim.log.levels.INFO)
        elseif not already then
          vim.notify('neotest: subprocess.lua patch target not found (upstream changed?)', vim.log.levels.WARN)
        end

        vim.fn.system({ 'git', '-C', plugin.dir, 'diff', '--quiet' })
        if vim.v.shell_error ~= 0 then
          vim.fn.system({ 'git', '-C', plugin.dir, 'add', '-A' })
          vim.fn.system {
            'git', '-C', plugin.dir, 'commit', '-m',
            'chore: reapply c_sharp/cs subprocess alias local patch',
          }
        end
      end,
      config = function()
        require('neotest').setup {
          adapters = {
            require('neotest-dotnet') {
              dap = { adapter_name = 'coreclr' },
              -- discovers tests project-by-project (better for solutions with multiple test projects)
              discovery_root = 'project',
            },
          },
        }

        require('which-key').add { { '<leader>dt', group = '[D]ebug [T]ests' } }

        local nt = require 'neotest'
        local k = vim.keymap.set

        -- Run
        k('n', '<leader>dtt', function() nt.run.run() end,
          { noremap = true, silent = true, desc = 'Test: Run nearest test' })
        k('n', '<leader>dtf', function() nt.run.run(vim.fn.expand '%') end,
          { noremap = true, silent = true, desc = 'Test: Run file' })
        k('n', '<leader>dta', function() nt.run.run { suite = true } end,
          { noremap = true, silent = true, desc = 'Test: Run all' })
        k('n', '<leader>dtl', function() nt.run.run_last() end,
          { noremap = true, silent = true, desc = 'Test: Run last' })
        k('n', '<leader>dtw', function() nt.watch.toggle(vim.fn.expand '%') end,
          { noremap = true, silent = true, desc = 'Test: Watch file' })

        -- Debug (hooks into netcoredbg via coreclr adapter)
        k('n', '<leader>dtd', function() nt.run.run { strategy = 'dap' } end,
          { noremap = true, silent = true, desc = 'Test: Debug nearest' })

        -- UI
        k('n', '<leader>dts', function() nt.summary.toggle() end,
          { noremap = true, silent = true, desc = 'Test: Toggle summary' })
        k('n', '<leader>dto', function() nt.output.open { enter = true } end,
          { noremap = true, silent = true, desc = 'Test: Open output' })
        k('n', '<leader>dtp', function() nt.output_panel.toggle() end,
          { noremap = true, silent = true, desc = 'Test: Toggle output panel' })
      end,
    },
  },
}
