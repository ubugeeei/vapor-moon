local source = debug.getinfo(1, "S").source:sub(2)
local repo_root = vim.fn.fnamemodify(source, ":p:h:h:h")
local repo_command = repo_root .. "/bin/vapor-moon-lsp"
local command = vim.fn.executable(repo_command) == 1 and repo_command or "vapor-moon-lsp"

return {
  cmd = { command },
  filetypes = { "vapor_moon" },
  root_markers = { "moon.mod.json", ".git" },
  single_file_support = true,
}
