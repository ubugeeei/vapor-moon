const fs = require("node:fs");
const path = require("node:path");
const vscode = require("vscode");
const { LanguageClient } = require("vscode-languageclient/node");

let client;

function activate(context) {
  const configuration = vscode.workspace.getConfiguration("vaporMoon");
  const command =
    configuration.get("languageServer.command") || resolveDefaultCommand(context.extensionPath);
  const args = configuration.get("languageServer.args") || [];
  const cwd =
    configuration.get("languageServer.cwd") || vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;

  const serverOptions = {
    command,
    args,
    options: cwd ? { cwd } : {},
  };
  const clientOptions = {
    documentSelector: [
      { language: "vapor-moon", scheme: "file" },
      { language: "vapor-moon", scheme: "untitled" },
    ],
    synchronize: {
      configurationSection: "vaporMoon",
      fileEvents: vscode.workspace.createFileSystemWatcher("**/*.mbtv"),
    },
  };

  client = new LanguageClient(
    "vapor-moon-lsp",
    "Vapor Moon Language Server",
    serverOptions,
    clientOptions,
  );
  context.subscriptions.push(client.start());
}

function deactivate() {
  return client?.stop();
}

function resolveDefaultCommand(extensionPath) {
  const executableName = process.platform === "win32" ? "vapor-moon-lsp.cmd" : "vapor-moon-lsp";
  const commands = [
    path.join(extensionPath, "bin", executableName),
    path.resolve(extensionPath, "..", "..", "bin", executableName),
  ];
  for (const command of commands) {
    if (isFile(command)) {
      return command;
    }
  }
  return executableName;
}

function isFile(filePath) {
  try {
    return fs.statSync(filePath).isFile();
  } catch {
    return false;
  }
}

module.exports = {
  activate,
  deactivate,
};
