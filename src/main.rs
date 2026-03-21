use std::{
    collections::HashMap,
    fs::read_to_string,
    path::PathBuf,
    process::{Command, ExitCode},
};

use serde::{Deserialize, Serialize};

#[derive(Default, Debug, Serialize, Deserialize, Clone)]
struct ConfigFile {
    base: PathBuf,
    #[serde(default)]
    mappings: HashMap<String, PathBuf>,
}

mod flags {
    use std::path::PathBuf;

    xflags::xflags! {
        /// Allows you to clone repositories from a given URL or clipboard to configured base directory and mappings for cloning repositories. Useful for managing multiple repositories under a single directory related to host name.
        cmd git-site-clone {
            /// Silent mode
            optional -v,--verbose
            /// Show version information
            optional -V,--version
            /// Clone a repository from a given URL (or clipboard if not provided)
            default cmd clone {
                /// Clone a repository from a given URL (or clipboard if not provided)
                optional url: String
                /// Base directory for cloning repositories
                optional --base base: PathBuf
                /// Do not change the current directory after cloning
                optional --no-cwd
            }
            /// Configure the base directory and mappings for cloning repositories.
            cmd config {
                /// Show the current configuration
                cmd show {}
                /// Set the base directory for cloning repositories.
                cmd base {
                    required base: PathBuf
                }
                /// Configure mappings for cloning repositories.
                cmd mappings {
                    /// Add a mapping for cloning repositories.
                    cmd add {
                        /// Hostname (key) of the mapping
                        required host: String
                        /// Path to the mapping
                        required path: PathBuf
                    }
                    cmd remove {
                        required host: String
                    }
                }
            }
            /// Initialize shell integration
            cmd init {}
            /// Self-update the binary (requires self-update feature)
            cmd self-update {}
        }
    }
}

fn main() -> ExitCode {
    let flags = flags::GitSiteClone::from_env_or_exit();

    if flags.version {
        println!("{}", env!("CARGO_PKG_VERSION"));
        return ExitCode::SUCCESS;
    }

    let verbose = flags.verbose;
    match flags.subcommand {
        flags::GitSiteCloneCmd::Clone(flags::Clone { url, base, no_cwd }) => {
            let config_path = get_config_path();
            if verbose {
                eprintln!("Configuration path: {}", config_path.display());
            }
            let config = load_config();

            let url = url.unwrap_or_else(|| {
                #[cfg(feature = "clipboard")]
                {
                    if cfg!(target_os = "linux") && std::env::var("DISPLAY").is_err() {
                        panic!("url not provided");
                    }
                    use arboard::Clipboard;
                    Clipboard::new()
                        .expect("clipboart")
                        .get_text()
                        .expect("clipboard text")
                }
                #[cfg(not(feature = "clipboard"))]
                {
                    panic!("url not provided");
                }
            });
            let git_url = git_url_parse::GitUrl::parse(&url).expect("valid git url");
            if let Some(host) = git_url.host() {
                let base_dir = base
                    .as_ref()
                    .map(|base| base.join(host))
                    .unwrap_or_else(|| {
                        config
                            .mappings
                            .get(host)
                            .cloned()
                            .unwrap_or(config.base.join(host))
                    });
                let path = git_url.path();
                let path = path.strip_prefix("/").unwrap_or(path);
                let path = path.strip_suffix(".git").unwrap_or(path);
                let target = base_dir.join(path);
                if verbose {
                    eprintln!("Target: {}", target.display());
                }
                if target.exists() {
                    if verbose {
                        eprintln!("Target directory already exists");
                    }
                } else {
                    if verbose {
                        eprintln!("Cloning with git {url} to {target:?}...");
                    }
                    let status = Command::new("git")
                        .arg("clone")
                        .arg(&url)
                        .arg(&target)
                        .status()
                        .expect("git clone repository");
                    if !status.success() {
                        if verbose {
                            eprintln!("Failed to clone repository");
                        }
                        return ExitCode::from(status.code().unwrap_or(1) as u8);
                    }
                }
                if !no_cwd {
                    if verbose {
                        eprintln!("Changing directory to {}", target.display());
                    }
                    println!("{}", target.to_string_lossy());
                }
            } else {
                if verbose {
                    eprintln!("Invalid git url");
                }
                return ExitCode::FAILURE;
            }
        }
        flags::GitSiteCloneCmd::Config(config_cmd) => {
            let config_path = get_config_path();
            if verbose {
                eprintln!("Configuration path: {}", config_path.display());
            }

            match config_cmd.subcommand {
                flags::ConfigCmd::Show(_) => {
                    let _ = load_config();
                    let config_str = read_to_string(&config_path).expect("config file read");
                    println!("{config_str}");
                }
                flags::ConfigCmd::Base(cmd) => {
                    let mut stored_config = load_config();
                    stored_config.base = cmd.base;
                    store_config(stored_config);
                }
                flags::ConfigCmd::Mappings(mappings) => {
                    let mut stored_config = load_config();
                    match mappings.subcommand {
                        flags::MappingsCmd::Add(flags::Add { host, path }) => {
                            stored_config.mappings.insert(host, path);
                        }
                        flags::MappingsCmd::Remove(mapping) => {
                            stored_config.mappings.remove(&mapping.host);
                        }
                    }
                    store_config(stored_config);
                }
            }
        }
        flags::GitSiteCloneCmd::Init(_) => {
            if let Err(e) = init_shell() {
                eprintln!("Failed to initialize shell: {}", e);
                return ExitCode::FAILURE;
            }
        }
        flags::GitSiteCloneCmd::SelfUpdate(_) => {
            #[cfg(feature = "self-update")]
            {
                if let Err(e) = self_update() {
                    eprintln!("Failed to self-update: {}", e);
                    return ExitCode::FAILURE;
                }
            }
            #[cfg(not(feature = "self-update"))]
            {
                eprintln!("Self-update is not enabled. Build with --features self-update");
                return ExitCode::FAILURE;
            }
        }
    }
    ExitCode::SUCCESS
}

fn store_config(stored_config: ConfigFile) {
    confy::store(env!("CARGO_BIN_NAME"), None, stored_config).expect("store configuration")
}

fn get_config_path() -> PathBuf {
    confy::get_configuration_file_path(env!("CARGO_BIN_NAME"), None).expect("configuration path")
}

fn load_config() -> ConfigFile {
    let config_path = get_config_path();
    if !config_path.exists() {
        let home = dirs::home_dir().expect("home directory");
        let config = ConfigFile {
            base: home,
            ..Default::default()
        };
        store_config(config.clone());
        return config;
    }
    confy::load(env!("CARGO_BIN_NAME"), None).expect("configuration load")
}

fn get_shell_rc() -> Option<(PathBuf, &'static str)> {
    let shell = std::env::var("SHELL").ok()?;
    let home = dirs::home_dir()?;

    if shell.contains("zsh") {
        Some((home.join(".zshrc"), "zsh"))
    } else if shell.contains("bash") {
        if home.join(".bashrc").exists() {
            Some((home.join(".bashrc"), "bash"))
        } else {
            Some((home.join(".bash_profile"), "bash"))
        }
    } else if shell.contains("fish") {
        Some((home.join(".config/fish/config.fish"), "fish"))
    } else {
        None
    }
}

fn init_shell() -> Result<(), Box<dyn std::error::Error>> {
    let (rc_path, shell) = get_shell_rc().ok_or("Could not detect shell or shell RC file")?;

    eprintln!("Detected shell: {}", shell);

    let gsc_function = match shell {
        "zsh" | "bash" => {
            r#"
function gsc() {
    local repo
    repo=$(git-site-clone "$@")
    if [ -d "$repo" ]; then
        cd "$repo"
    fi
}
"#
        }
        "fish" => {
            r#"
function gsc
    set repo (git-site-clone $argv)
    if test -d "$repo"
        cd "$repo"
    end
end
"#
        }
        _ => return Err("Unsupported shell".into()),
    };

    let rc_content = read_to_string(&rc_path).unwrap_or_default();

    if rc_content.contains("function gsc()") || rc_content.contains("function gsc") {
        eprintln!("gsc function already exists in {}", rc_path.display());
    } else {
        let mut file = std::fs::OpenOptions::new()
            .append(true)
            .create(true)
            .open(&rc_path)?;

        use std::io::Write;
        writeln!(file, "\n# git-site-clone shell integration")?;
        file.write_all(gsc_function.as_bytes())?;

        eprintln!("Added gsc function to {}", rc_path.display());
    }

    eprintln!(
        "Please restart your shell or run: source {}",
        rc_path.display()
    );

    Ok(())
}

#[cfg(feature = "self-update")]
fn self_update() -> Result<(), Box<dyn std::error::Error>> {
    let current_version = env!("CARGO_PKG_VERSION");
    let repo = "rust-application/git-site-clone";

    eprintln!("Current version: {}", current_version);
    eprintln!("Checking for updates...");

    let client = reqwest::blocking::Client::new();
    let url = format!("https://api.github.com/repos/{}/releases/latest", repo);
    let response = client
        .request(reqwest::Method::GET, &url)
        .header(reqwest::header::ACCEPT, "application/vnd.github+json")
        .header(reqwest::header::USER_AGENT, "git-site-clone")
        .send()?;

    let json: serde_json::Value = response.json()?;
    let latest_version = json["tag_name"]
        .as_str()
        .ok_or("Could not find latest version")?
        .trim_start_matches('v');

    eprintln!("Latest version: {}", latest_version);

    if latest_version == current_version {
        println!("Already up to date!");
        return Ok(());
    }

    let os = std::env::consts::OS;
    let arch = std::env::consts::ARCH;

    let binary_name = if os == "windows" {
        "git-site-clone.exe"
    } else {
        "git-site-clone"
    };

    let target = match (os, arch) {
        ("linux", "x86_64") => "x86_64-unknown-linux-musl",
        ("linux", "aarch64") => "aarch64-unknown-linux-musl",
        ("macos", "x86_64") => "x86_64-apple-darwin",
        ("macos", "aarch64") => "aarch64-apple-darwin",
        ("windows", "x86_64") => "x86_64-pc-windows-msvc",
        _ => return Err(format!("Unsupported platform: {}-{}", os, arch).into()),
    };

    let download_url = json["assets"]
        .as_array()
        .ok_or("Could not find release assets")?
        .iter()
        .find(|asset| {
            let name = asset["name"].as_str().unwrap_or("");
            name.contains(target) && name.contains(binary_name)
        })
        .ok_or("Could not find release binary")?["browser_download_url"]
        .as_str()
        .ok_or("Could not find download URL")?;

    eprintln!("Downloading: {}", download_url);

    let response = client.get(download_url).send()?;
    let binary_data = response.bytes()?;

    let exe_path = std::env::current_exe()?;
    std::fs::write(&exe_path, &binary_data)?;

    println!("Updated to version {}!", latest_version);

    Ok(())
}
