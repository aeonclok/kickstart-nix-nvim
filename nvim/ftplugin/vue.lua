-- nvim/ftplugin/vue.lua
if vim.fn.executable('vue-language-server') ~= 1 then return end
local caps = require('user.lsp').make_client_capabilities()
local root = function()
  local f = vim.fs.find({
    'package.json','vite.config.ts','vite.config.js',
    'nuxt.config.ts','nuxt.config.js','vue.config.ts','vue.config.js',
    'tsconfig.json','.git',
  }, { upward = true })[1]
  return f and vim.fs.dirname(f) or vim.uv.cwd()
end

-- Start TS side (vtsls preferred)
local vue_ls_path = vim.fs.find({ 'node_modules/@vue/language-server' }, { upward = true, type='directory' })[1]
local vue_plugin = vue_ls_path and {
  name='@vue/typescript-plugin', location=vue_ls_path, languages={'vue'}, configNamespace='typescript',
} or nil

if vim.fn.executable('vtsls') == 1 then
  vim.lsp.start{
    name='vtsls', cmd={'vtsls'}, root_dir=root(), capabilities=caps,
    settings={ vtsls = { tsserver = { globalPlugins = vue_plugin and { vue_plugin } or {} } } },
    on_attach=function(client,b) if vim.bo[b].filetype=='vue' and client.server_capabilities.semanticTokensProvider then client.server_capabilities.semanticTokensProvider.full=false end end,
  }
elseif vim.fn.executable('typescript-language-server') == 1 then
  vim.lsp.start{
    name='ts_ls', cmd={'typescript-language-server','--stdio'}, root_dir=root(), capabilities=caps,
    init_options={ plugins = vue_plugin and { vue_plugin } or {} },
    on_attach=function(client,b) if vim.bo[b].filetype=='vue' and client.server_capabilities.semanticTokensProvider then client.server_capabilities.semanticTokensProvider.full=false end end,
  }
end

vim.lsp.start{
  name='vue_ls', cmd={'vue-language-server','--stdio'}, root_dir=root(), capabilities=caps,
  on_attach=function(client,_) if client.server_capabilities.semanticTokensProvider then client.server_capabilities.semanticTokensProvider.full=true end end,
}
