# Editor Integrations

Vapor Moon ships a stdio LSP server at [`bin/vapor-moon-lsp`](../bin/vapor-moon-lsp).

The launcher currently shells out to `moon run --target js src/cmd/vapor_moon_lsp`, so editor integrations expect:

- `moon` on `PATH`
- a JS runtime such as `node`, `bun`, or `deno` on `PATH`

## VS Code

- Extension source lives in [`editors/vscode`](./vscode)
- Run `npm install` in that directory before launching the extension host
- Open that folder in VS Code and run the extension in an Extension Development Host
- By default the client prefers the repo-local `bin/vapor-moon-lsp` launcher and falls back to `vapor-moon-lsp` from `PATH`
- Override the server with `vaporMoon.languageServer.command`, `vaporMoon.languageServer.args`, and `vaporMoon.languageServer.cwd`

## Zed

- Extension source lives in [`editors/zed`](./zed)
- Install it as a dev extension from the local path
- The extension checks `VAPOR_MOON_LSP`, then a repo-local `bin/vapor-moon-lsp`, then `vapor-moon-lsp` from `PATH`
- `.mbtv` is registered as the `Vapor Moon` language and uses the Vue tree-sitter grammar with MoonBit injections for `script` / `script extern` blocks and template expressions

## Neovim

- Runtime files live in [`editors/neovim`](./neovim)
- Add that directory to `runtimepath`, then enable the config with `vim.lsp.enable("vapor_moon")`
- The bundled config uses the repo-local `bin/vapor-moon-lsp` when available and otherwise falls back to `vapor-moon-lsp` from `PATH`
- `.mbtv` is mapped to the `vapor_moon` filetype through `ftdetect/mbtv.lua`
- Example setup:

```lua
vim.opt.runtimepath:append("/absolute/path/to/vapor-moon/editors/neovim")
vim.lsp.enable("vapor_moon")
```
