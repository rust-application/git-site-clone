# Agent Guidelines for git-site-clone

## Project Overview

`git-site-clone` is a CLI tool that clones git repositories from URLs or clipboard to a configured base directory with host-based mappings. Written in Rust (edition 2024), minimum Rust version 1.90.0.

## Feature Development Workflow

All new features must start with a GitHub issue before implementation:
1. Create an issue at https://github.com/rust-application/git-site-clone/issues/new
2. Describe the feature, expected behavior, and use case
3. Wait for issue to be triaged/approved
4. Create a branch using `gh issue develop <number> --checkout`
5. Implement the feature
6. Commit changes with descriptive message referencing the issue
7. Push and create PR with `gh pr create`
8. Reference the issue in PR body (e.g., "Fixes #9")

## Merging PRs

Use squash merge to keep main history clean:
```bash
gh pr merge <number> --admin --delete-branch --squash
```

## Build Commands

```bash
# Build debug
cargo build

# Build release
cargo build --release

# Build with specific target
cargo build --release --target x86_64-unknown-linux-musl

# Run the binary
cargo run --release -- <args>

# Run clippy lints
cargo clippy --all-targets

# Format code
cargo fmt

# Check formatting
cargo fmt -- --check
```

## Testing

This project has no test files. If adding tests:

```bash
# Run all tests
cargo test

# Run a single test
cargo test test_name

# Run tests with output
cargo test -- --nocapture
```

## Code Style Guidelines

### General
- Use Rust edition 2024
- Minimum Rust version: 1.90.0
- Run `cargo fmt` before committing
- Run `cargo clippy` to catch common mistakes

### Imports
Group imports in this order:
1. Standard library (`std::`)
2. External crates (alphabetically)
3. Local modules

```rust
use std::{
    collections::HashMap,
    fs::read_to_string,
    path::PathBuf,
    process::{Command, ExitCode},
};

use serde::{Deserialize, Serialize};
```

### Naming Conventions
- Types: `PascalCase` (e.g., `ConfigFile`, `GitSiteClone`)
- Functions/variables: `snake_case` (e.g., `load_config`, `get_config_path`)
- Modules: `snake_case` (e.g., `mod flags`)
- Constants: `SCREAMING_SNAKE_CASE`

### Error Handling
- Use `.expect()` for unrecoverable errors (e.g., config load failures, git clone failures)
- Return `ExitCode` from `main()` for CLI error handling
- Use `panic!()` for programmer errors that should never occur

```rust
fn load_config() -> ConfigFile {
    confy::load(env!("CARGO_BIN_NAME"), None).expect("configuration load")
}
```

### Types
- Use explicit types in function signatures
- Leverage Rust's type inference for local variables when clear
- Use `PathBuf` for filesystem paths
- Use `HashMap<K, V>` for key-value mappings

### Structs and Enums
- Use `#[derive(...)]` for common traits: `Default`, `Debug`, `Serialize`, `Deserialize`, `Clone`, `Copy`, `PartialEq`, `Eq`
- Place derives on same line when possible

```rust
#[derive(Default, Debug, Serialize, Deserialize)]
struct ConfigFile {
    base: PathBuf,
    #[serde(default)]
    mappings: HashMap<String, PathBuf>,
}
```

### CLI Arguments
- Use `xflags` crate for CLI parsing (already used in this project)
- Define flags in the `mod flags` block with xflags macro

### Cargo Features
- Feature-gate optional dependencies
- Default feature: `clipboard` (uses `arboard` crate)

```toml
[features]
default = ["clipboard"]
clipboard = ["dep:arboard"]
```

### Git Integration
- Use `std::process::Command` to invoke `git clone`
- Check exit status with `.status()` and verify `.success()`

### Configuration
- Use `confy` for configuration storage
- Configuration file format: TOML

### Release Build
- Use LTO and single codegen unit for optimized releases
- Strip binaries in release builds

```toml
[profile.release]
strip = true
lto = true
codegen-units = 1
```

## Common Tasks

### Adding a new CLI subcommand
1. Add to `mod flags` using xflags macro
2. Handle in `main()` match statement

### Adding configuration option
1. Add field to `ConfigFile` struct
2. Update config load/store functions
3. Add CLI flag if needed

### Building for release
```bash
cargo build --release
# Binary at: target/release/git-site-clone
```

## Dependencies

Key dependencies:
- `xflags` - CLI argument parsing
- `confy` - Configuration storage
- `serde` / `serde_json` - Serialization
- `git-url-parse` - Git URL parsing
- `arboard` - Clipboard access (optional, feature-gated)