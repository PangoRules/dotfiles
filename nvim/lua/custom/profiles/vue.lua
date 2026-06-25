-- Vue 3 + TypeScript profile (Hybrid Mode: ts_ls + vue_ls together)
return {
  treesitter = { 'typescript', 'javascript', 'vue', 'css', 'json' },

  mason = {
    'vue-language-server',        -- volar
    'typescript-language-server', -- ts_ls
    'eslint-lsp',
    'eslint_d',                   -- conform formatter: applies eslint autofixes on save
    'prettier',
    'tailwindcss-language-server',
  },

  lsp_setup = function(cap)
    -- Vue 3 uses "Hybrid Mode": two language servers run simultaneously.
    --
    -- 1. vue_ls (Volar) handles everything Vue-specific: template type-checking,
    --    component resolution, `<script setup>` transforms, and SFC block extraction.
    --
    -- 2. ts_ls (TypeScript Language Server) handles all pure TypeScript features:
    --    completions, go-to-definition, rename, and diagnostics inside <script> blocks.
    --    It would normally ignore `.vue` files, so we extend its `filetypes` to include
    --    them AND register the @vue/typescript-plugin in its `init_options`.
    --
    -- The @vue/typescript-plugin registration tells ts_ls to delegate any request
    -- touching a `.vue` file to Volar's TypeScript plugin layer, which understands
    -- Vue's SFC format. Without it, ts_ls would either refuse .vue files outright
    -- or give incorrect results (it can't parse <template> blocks on its own).

    -- The plugin lives inside Mason's Volar package directory.
    local volar_path = vim.fn.stdpath 'data'
      .. '/mason/packages/vue-language-server/node_modules/@vue/language-server'

    vim.lsp.config('ts_ls', {
      capabilities  = cap,
      init_options  = {
        plugins = {
          -- Register Volar's TypeScript plugin so ts_ls can handle .vue files.
          -- `location` points to Mason's install of the vue-language-server package.
          { name = '@vue/typescript-plugin', location = volar_path, languages = { 'vue' } },
        },
      },
      -- ts_ls normally only activates on .ts/.js files; add .vue so it also
      -- attaches to Vue SFCs and can serve TypeScript features inside them.
      filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
    })
    vim.lsp.config('vue_ls', { capabilities = cap })
    vim.lsp.config('eslint', { capabilities = cap })
    vim.lsp.config('tailwindcss', {
      capabilities = cap,
      filetypes = { 'html', 'css', 'vue', 'javascript', 'typescript' },
    })

    return { 'ts_ls', 'vue_ls', 'eslint', 'tailwindcss' }
  end,

  -- js/ts/vue: prettier only runs if the project actually depends on it; otherwise
  -- eslint_d alone owns formatting (e.g. Nuxt projects using @nuxt/eslint's stylistic
  -- rules instead of prettier — running both fights forever, see _shared.lua).
  formatters = {
    javascript = require('custom.profiles._shared').js_formatters,
    typescript = require('custom.profiles._shared').js_formatters,
    vue        = require('custom.profiles._shared').js_formatters,
    json       = { 'prettier' },
    css        = { 'prettier' },
  },
}
