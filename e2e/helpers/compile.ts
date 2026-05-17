import { mkdtempSync, rmSync, writeFileSync } from "fs";
import { tmpdir } from "os";
import { join, resolve } from "path";
import { spawnSync } from "child_process";

export interface CompileOutput {
  client_code: string;
  server_code: string;
  css_output: string;
  meta: Record<string, string>;
}

const ROOT = resolve(__dirname, "../..");

export function compileFile(filePath: string): CompileOutput {
  const absPath = resolve(ROOT, filePath);
  const raw = runCompiler(absPath, { allowFailure: false });

  return parseCompileOutput(raw);
}

export function compileSource(
  source: string,
  filename: string
): CompileOutput {
  const tmpDir = mkdtempSync(join(tmpdir(), "vapor-moon-e2e-"));
  const tmpFile = join(tmpDir, filename);
  writeFileSync(tmpFile, source);
  try {
    const raw = runCompiler(tmpFile, { allowFailure: true });
    return parseCompileOutput(raw);
  } finally {
    rmSync(tmpDir, { recursive: true, force: true });
  }
}

function runCompiler(
  filePath: string,
  options: { allowFailure: boolean }
): string {
  const result = spawnSync(
    "moon",
    ["run", "src/cmd/vapor_moon", "--", "compile", filePath],
    {
      cwd: ROOT,
      encoding: "utf-8",
    }
  );

  if (result.error) {
    throw result.error;
  }

  if (result.status !== 0 && !options.allowFailure) {
    throw new Error(result.stderr || result.stdout);
  }

  return result.stdout || result.stderr || "";
}

function parseCompileOutput(raw: string): CompileOutput {
  const sections: Record<string, string> = {};
  let currentSection = "";
  const lines = raw.split("\n");

  for (const line of lines) {
    const match = line.match(/^=== (\w+) ===$/);
    if (match) {
      currentSection = match[1];
      sections[currentSection] = "";
    } else if (currentSection) {
      sections[currentSection] += (sections[currentSection] ? "\n" : "") + line;
    }
  }

  const meta: Record<string, string> = {};
  for (const line of (sections.meta || "").split("\n")) {
    const [key, ...rest] = line.split("=");
    if (key && rest.length > 0) {
      meta[key.trim()] = rest.join("=").trim();
    }
  }

  return {
    client_code: (sections.client || "").trim(),
    server_code: (sections.server || "").trim(),
    css_output: sections.css?.trim() === "<empty>" ? "" : (sections.css || "").trim(),
    meta,
  };
}

/**
 * Build a minimal HTML page from SSR output for Playwright testing.
 * The HTML is a self-contained page with the SSR content and scoped CSS.
 */
export function buildSSRHtml(output: CompileOutput): string {
  const css = output.css_output ? `<style>${output.css_output}</style>` : "";
  // For SSR, we extract the HTML structure from server_code metadata
  // Since we can't run MoonBit's render_html() from Node.js directly,
  // we parse the server codegen to infer the expected DOM structure.
  // For now, we return a placeholder that tests can use with page.setContent().
  return `<!DOCTYPE html>
<html>
<head><meta charset="utf-8">${css}</head>
<body><div id="app"></div></body>
</html>`;
}
