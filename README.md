# git-site-clone

Allows you to clone repositories from a given URL or clipboard to configured base directory and mappings for cloning repositories. Useful for managing multiple repositories under a single directory related to host name.

Example directory structure for GitHub and GitLab:

```
/path/to/base/directory
├── github.com
│   ├── user1
│   │   ├── repo1
│   │   └── repo2
│   └── user2
│       ├── repo3
│       └── repo4
└── gitlab.com
    ├── user1
    │   ├── repo5
    │   └── repo6
    └── user2
        ├── repo7
        └── repo8
```

## Legal

Dual-licensed under `MIT` or the [UNLICENSE](http://unlicense.org/).

## Features

- Clone repositories from a given URL or clipboard
- Configure base directory and mappings for cloning repositories
- Navigate to cloned repositories

## Support:

You can contribute to the ongoing development and maintenance of **git-site-clone** in various ways:

### Sponsorship

Your support, no matter how big or small, helps sustain the project and ensures its continued improvement. Reach out to explore sponsorship opportunities.

### Feedback

Whether you are a developer, user, or enthusiast, your feedback is invaluable. Share your thoughts, suggestions, and ideas to help shape the future of the library.

### Contribution

If you're passionate about open-source and have skills to share, consider contributing to the project. Every contribution counts!

Thank you for being part of **git-site-clone** community. Together, we are making authentication processes more accessible, reliable, and efficient for everyone.

## Usage

Install the package using Cargo:

```sh
cargo install git-site-clone
```

Configure the base directory and mappings for cloning repositories:

```sh
git-site-clone config base /path/to/base/directory
```

Now you can clone repositories using the following command:

```sh
git-site-clone <url>
```

For example, to clone a repository from GitHub:

```sh
git-site-clone https://github.com/user/repo.git
```

This will clone the repository to `/path/to/base/directory/github.com/user/repo`.

Configure the mappings for cloning repositories:

```sh
git-site-clone config mappings add <source> <destination>
```

For example, to map a GitHub repository to a local directory:

```sh
git-site-clone config mappings add github.com /path/to/local/github.com
```

To remove a mapping:

```sh
git-site-clone config mappings remove <source>
```

For example, to remove the mapping for GitHub:

```sh
git-site-clone config mappings remove github.com
```

Learn more about available options:

```sh
$ git-site-clone --help
git-site-clone
  Allows you to clone repositories from a given URL or clipboard to configured base directory and mappings for cloning repositories. Useful for managing multiple repositories under a single directory related to host name.

ARGS:
    [url]
      Clone a repository from a given URL (or clipboard if not provided)

OPTIONS:
    -v, --verbose
      Silent mode

    -h, --help
      Prints help information.

    --base <base>
      Base directory for cloning repositories

    --no-cwd
      Do not change the current directory after cloning

SUBCOMMANDS:

git-site-clone config
  Configure the base directory and mappings for cloning repositories.


git-site-clone config show
  Show the current configuration


git-site-clone config base
  Set the base directory for cloning repositories.

  ARGS:
    <base>


git-site-clone config mappings
  Configure mappings for cloning repositories.


git-site-clone config mappings add
  Add a mapping for cloning repositories.

  ARGS:
    <host>
      Hostname (key) of the mapping

    <path>
      Path to the mapping


git-site-clone config mappings remove

  ARGS:
    <host>
```

To change to cloned directory, configure the `gsc` function in your shell configuration file like this:

```bash
function gsc() {
    cd $(git-site-clone $1)
}
```

## Configuration

Configuration is done using a TOML file.

Here's an example configuration:

```toml
base = "/path/to/base/directory"

[mappings]
"github.com" = "/path/to/github/mapping"
"bitbucket.org" = "/path/to/bitbucket/mapping"
```

Please note that mappings erase host part of the URL when cloning repositories. This means that if you have a repository URL like `https://github.com/user/repo`, it will be cloned to `/path/to/github/mapping/user/repo` instead of `/path/to/github/mapping/github.com/user/repo`.

If host part of the URL is not mapped, it will be cloned to the base directory with host part of the URL. Like `https://example.com/user/repo` will be cloned to `/path/to/base/directory/example.com/user/repo`.
