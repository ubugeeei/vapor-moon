@echo off
setlocal
set ROOT=%~dp0..
cd /d "%ROOT%"
set VAPOR_MOON_REQUIRE_SHIM=data:text/javascript,import{createRequire}from%%22node:module%%22;globalThis.require=createRequire(process.cwd()+%%22/%%22);
if defined NODE_OPTIONS (
  set "NODE_OPTIONS=%NODE_OPTIONS% --import=%VAPOR_MOON_REQUIRE_SHIM%"
) else (
  set "NODE_OPTIONS=--import=%VAPOR_MOON_REQUIRE_SHIM%"
)
moon run --target js src/cmd/vapor_moon_lsp -- %*
