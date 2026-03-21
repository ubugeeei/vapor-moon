use std::env;
use std::fs;
use zed_extension_api::{self as zed, Result};

struct VaporMoonExtension;

impl VaporMoonExtension {
    fn default_command_name() -> &'static str {
        if cfg!(target_os = "windows") {
            "vapor-moon-lsp.cmd"
        } else {
            "vapor-moon-lsp"
        }
    }

    fn repo_local_command() -> Option<String> {
        let extension_root = env::current_dir().ok()?;
        let command = extension_root
            .join("..")
            .join("..")
            .join("bin")
            .join(Self::default_command_name());
        fs::metadata(&command)
            .ok()
            .filter(|metadata| metadata.is_file())
            .map(|_| command.to_string_lossy().to_string())
    }
}

impl zed::Extension for VaporMoonExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        _language_server_id: &zed::LanguageServerId,
        _worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        let command = env::var("VAPOR_MOON_LSP")
            .ok()
            .or_else(Self::repo_local_command)
            .unwrap_or_else(|| Self::default_command_name().to_string());
        Ok(zed::Command {
            command,
            args: Vec::<String>::new(),
            env: Default::default(),
        })
    }
}

zed::register_extension!(VaporMoonExtension);
