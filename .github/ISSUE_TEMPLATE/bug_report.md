---
name: Bug report
about: Report a defect in the compiler, runtime, CLI, or LSP.
title: "bug(area): "
labels: bug
---

## Summary

<!-- One or two sentences describing the wrong behavior. -->

## Reproduction

Minimal `.mbtv` source (please trim — large repros are hard to bisect):

```html
<script setup>
</script>

<template>
</template>

<style>
</style>
```

CLI / LSP command used:

```bash
moon run src/cmd/vapor_moon -- compile ./Repro.mbtv
```

## Expected vs. actual

- **Expected:**
- **Actual:**

## Environment

- Vapor Moon version (`vapor-moon --version` output):
- MoonBit CLI version (`moon version` output):
- OS / arch (e.g. `Darwin arm64`, `Linux x86_64`):
- Editor / LSP client (if reporting an LSP bug):

## Anything else?

<!-- Relevant logs, screenshots, related issues. -->
