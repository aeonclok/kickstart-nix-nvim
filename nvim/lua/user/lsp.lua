---@mod user.lsp
---
---@brief [[
---LSP related functions
---@brief ]]

local M = {}

---Gets a 'ClientCapabilities' object, describing the LSP client capabilities
---Extends the object with capabilities provided by plugins.
---@return lsp.ClientCapabilities
function M.make_client_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local cmp_lsp = require('cmp_nvim_lsp')
  local cmp_lsp_capabilities = cmp_lsp.default_capabilities()
  capabilities = vim.tbl_deep_extend('keep', capabilities, cmp_lsp_capabilities)
  return capabilities
end

-- --- Helper to locate vue-language-server under Nix store
local function vue_ls_plugin_path()
  local bin = vim.fn.exepath('vue-language-server')
  if bin == '' then
    vim.notify('vue-language-server not found in PATH. Install it via Nix.', vim.log.levels.ERROR)
    return nil
  end
  local outdir = vim.fn.fnamemodify(bin, ':h')
  outdir = vim.fn.fnamemodify(outdir, ':h')
  local candidate = outdir .. '/lib/node_modules/@vue/language-server'
  if vim.uv.fs_stat(candidate) then
    return candidate
  end
  local alt = outdir .. '/lib/@vue/language-server'
  if vim.uv.fs_stat(alt) then
    return alt
  end
  vim.notify('Could not locate @vue/language-server under ' .. outdir, vim.log.levels.ERROR)
  return nil
end

function M.setup()
  local capabilities = M.make_client_capabilities()
  local vue_language_server_path = vue_ls_plugin_path()
  local ts_filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' }

  local vue_plugin = {
    name = '@vue/typescript-plugin',
    location = vue_language_server_path,
    languages = { 'vue' },
    configNamespace = 'typescript',
  }

  local vtsls_config = {
    capabilities = capabilities,
    settings = {
      vtsls = {
        tsserver = {
          globalPlugins = { vue_plugin },
        },
      },
    },
    filetypes = ts_filetypes,
  }

  local vue_ls_config = {
    capabilities = capabilities,
  }

  if vim.lsp and vim.lsp.config then
    -- Neovim 0.11+
    vim.lsp.config('vtsls', vtsls_config)
    vim.lsp.config('vue_ls', vue_ls_config)
    vim.lsp.enable({ 'vtsls', 'vue_ls' })
  else
    -- Neovim < 0.11
    local lspconfig = require('lspconfig')
    lspconfig.vtsls.setup(vtsls_config)
    lspconfig.vue_ls.setup(vue_ls_config)
  end
end

return M

