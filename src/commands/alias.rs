use std::env;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::PathBuf;

use anyhow::{Context, Result};

const ALIAS_MARKER_START: &str = "# >>> supgit alias >>>";
const ALIAS_MARKER_END: &str = "# <<< supgit alias <<<";

pub fn run_alias(dry_run: bool) -> Result<()> {
    let shell_config = get_shell_config()?;

    if dry_run {
        println!("Would add alias to: {}", shell_config.display());
        println!("Alias: git -> supgit");
        return Ok(());
    }

    let existing_content = fs::read_to_string(&shell_config).unwrap_or_default();

    if existing_content.contains(ALIAS_MARKER_START) {
        println!("Alias already exists in {}", shell_config.display());
        return Ok(());
    }

    let alias_block = format!(
        "\n{}\nalias git='supgit'\n{}\n",
        ALIAS_MARKER_START, ALIAS_MARKER_END
    );

    let mut file = OpenOptions::new()
        .append(true)
        .open(&shell_config)
        .with_context(|| format!("failed to open {}", shell_config.display()))?;

    file.write_all(alias_block.as_bytes())
        .with_context(|| format!("failed to write to {}", shell_config.display()))?;

    println!("✓ Added 'git' alias to {}", shell_config.display());
    println!(
        "  Run 'source {}' or start a new shell for changes to take effect.",
        shell_config.display()
    );

    Ok(())
}

pub fn run_unalias(dry_run: bool) -> Result<()> {
    let shell_config = get_shell_config()?;

    if dry_run {
        println!("Would remove alias from: {}", shell_config.display());
        return Ok(());
    }

    let existing_content = fs::read_to_string(&shell_config)
        .with_context(|| format!("failed to read {}", shell_config.display()))?;

    if !existing_content.contains(ALIAS_MARKER_START) {
        println!("No alias found in {}", shell_config.display());
        return Ok(());
    }

    let start_idx = existing_content
        .find(ALIAS_MARKER_START)
        .context("failed to find alias start marker")?;
    let end_idx = existing_content
        .find(ALIAS_MARKER_END)
        .context("failed to find alias end marker")?;

    let end_of_block = end_idx + ALIAS_MARKER_END.len();

    let new_content = if start_idx > 0 && existing_content[..start_idx].ends_with('\n') {
        let trimmed_start = start_idx - 1;
        format!(
            "{}{}",
            &existing_content[..trimmed_start],
            &existing_content[end_of_block..]
        )
    } else {
        format!(
            "{}{}",
            &existing_content[..start_idx],
            &existing_content[end_of_block..]
        )
    };

    fs::write(&shell_config, new_content.trim_end())
        .with_context(|| format!("failed to write to {}", shell_config.display()))?;

    println!("✓ Removed 'git' alias from {}", shell_config.display());
    println!(
        "  Run 'source {}' or start a new shell for changes to take effect.",
        shell_config.display()
    );

    Ok(())
}

fn get_shell_config() -> Result<PathBuf> {
    let home = env::var("HOME")
        .or_else(|_| env::var("USERPROFILE"))
        .context("could not determine home directory")?;

    let home_path = PathBuf::from(&home);

    let shell = env::var("SHELL").unwrap_or_default();

    let config_name = if shell.contains("zsh") {
        ".zshrc"
    } else {
        ".bashrc"
    };

    Ok(home_path.join(config_name))
}
