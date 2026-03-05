# AGENTS.md - SupGIT Project Guidelines

## Project Overview

SupGIT (Simple Git) is a Rust CLI wrapper around Git that provides simplified workflows for common Git operations. It is a single-binary project with a modular code structure.

## Build/Lint/Test Commands

```bash
# Build the project
cargo build

# Build with optimizations
cargo build --release

# Run the binary directly
cargo run -- <command>

# Check for compilation errors (faster than build)
cargo check

# Run all tests
cargo test

# Run a specific test by name
cargo test <test_name>

# Run tests with output shown
cargo test -- --nocapture

# Lint with clippy
cargo clippy

# Format code
cargo fmt

# Check formatting without applying
cargo fmt -- --check
```

## Code Style Guidelines

### Imports

- Group imports: std library → external crates → local modules
- Import specific items, avoid glob imports (`use anyhow::{bail, Context}` not `use anyhow::*`)
- Rename to avoid conflicts: `use std::process::Command as StdCommand`

```rust
use std::process::Command as StdCommand;
use anyhow::{bail, Context, Result};
use dialoguer::{Confirm, Input, Select};
use crate::git::run_git_silent;
```

### Formatting

- 4 spaces indentation, 100 char max line length
- Opening braces on same line
- Always run `cargo fmt` before committing

### Types

- Use `Result<T>` for fallible functions (alias for `anyhow::Result`)
- Use `Option<T>` for optional values
- `String` for owned, `&str` for borrowed strings
- `Vec<T>` for collections

### Naming Conventions

- Functions/variables: `snake_case` (`run_git`, `get_staged_files`)
- Structs/Enums: `PascalCase` (`Cli`, `SupgitCommand`)
- Constants: `SCREAMING_SNAKE_CASE` (`NOT_IN_REPO_HINT`)
- Enum variants: `PascalCase` (`SupgitCommand::Init`)

### Error Handling

- Use `anyhow` crate, `bail!` macro for early returns
- Add context with `.context()` or `.with_context()`

```rust
pub fn check_in_repo() -> Result<()> {
    StdCommand::new("git")
        .args(["rev-parse", "--git-dir"])
        .status()
        .context("failed to execute git - is git installed?")?
        .success()
        .then_some(())
        .ok_or_else(|| anyhow::anyhow!("{}", NOT_IN_REPO_HINT))
}
```

### CLI Structure (clap)

- Use derive macros: `#[derive(Parser, Subcommand)]`
- Document with doc comments: `///`
- Flags: `#[arg(long)]` or `#[arg(short, long)]`
- Subcommands: `#[command(subcommand)]`

```rust
#[derive(Parser)]
#[command(name = "supgit", about = "Description", version)]
pub struct Cli {
    #[arg(long, global = true)]
    pub explain: bool,
    #[command(subcommand)]
    pub command: Option<SupgitCommand>,
}
```

### Functions & Pattern Matching

- Keep functions focused, use `-> Result<()>` for fallible functions
- Use `match` for enum dispatch, handle all variants explicitly
- Use `_ => Ok(())` for no-op defaults

### Command Execution

- Use `std::process::Command` for Git commands
- Check `output.status.success()` before returning
- Use `.output()` when capturing stdout/stderr

```rust
let output = StdCommand::new("git")
    .args(["status", "--porcelain"])
    .output()
    .context("running git status --porcelain")?;
```

### String Handling

- `String::from_utf8_lossy()` for command output conversion
- `.trim()` to clean strings, `.lines()` for iteration
- `.as_str()` for String → &str conversion

## Architecture

- `src/main.rs` - Entry point, command dispatch via `execute_command()`
- `src/cli.rs` - CLI definitions (`Cli`, `SupgitCommand` enum)
- `src/git.rs` - Git command helpers (`run_git`, `run_git_silent`, etc.)
- `src/status.rs` - Status utilities (`get_staged_files`, `get_branches`)
- `src/commands/` - Individual command implementations
- Interactive prompts via `dialoguer` crate
- Errors printed with `eprintln!` + error chain

## Adding New Commands

1. Add variant to `SupgitCommand` in `src/cli.rs` with doc comment
2. Add arguments as fields with `#[arg]` attributes
3. Create implementation in `src/commands/`
4. Export from `src/commands/mod.rs`
5. Add match arm in `main.rs::execute_command()`
6. Update `print_explanations()` in main.rs

## Dependencies

- `anyhow`: Error handling
- `clap`: CLI parsing (derive feature)
- `dialoguer`: Interactive prompts
- `strsim`: String similarity (for command suggestions)
- `dirs`: Platform-specific directories

## Known Issues

- Cargo.toml has `edition = "2024"` which is invalid; should be `2021`
