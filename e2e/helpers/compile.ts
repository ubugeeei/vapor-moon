import { execSync } from "child_process";
import { resolve } from "path";

export interface CompileOutput {
  client_code: string;
  server_code: string;
  css_output: string;
  meta: Record<string, string>;
}

const ROOT = resolve(__dirname, "../..");

export function compileFile(filePath: string): CompileOutput {
  const absPath = resolve(ROOT, filePath);
  const raw = execSync(`moon run src/cmd/vapor_moon -- compile ${absPath}`, {
    cwd: ROOT,
    encoding: "utf-8",
    stdio: ["pipe", "pipe", "pipe"],
  });

  return parseCompileOutput(raw);
}

export function compileSource(
  source: string,
  filename: string
): CompileOutput {
  // Write source to a temp file, compile, clean up
  const { writeFileSync, unlinkSync, mkdtempSync } = require("fs");
  const { join } = require("path");
  const tmpDir = mkdtempSync(join(require("os").tmpdir(), "vapor-moon-e2e-"));
  const tmpFile = join(tmpDir, filename);
  writeFileSync(tmpFile, source);
  try {
    const raw = execSync(
      `moon run src/cmd/vapor_moon -- compile ${tmpFile}`,
      {
        cwd: ROOT,
        encoding: "utf-8",
        stdio: ["pipe", "pipe", "pipe"],
      }
    );
    return parseCompileOutput(raw);
  } finally {
    unlinkSync(tmpFile);
    require("fs").rmdirSync(tmpDir);
  }
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
