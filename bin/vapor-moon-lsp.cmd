@echo off
setlocal
set ROOT=%~dp0..
cd /d "%ROOT%"
moon run --target js src/cmd/vapor_moon_lsp -- %*
