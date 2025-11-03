# CLI Template

[![Stars](https://img.shields.io/github/stars/samzong/cli-template.svg)](https://github.com/samzong/cli-template/stargazers)
[![Go Report Card](https://goreportcard.com/badge/github.com/samzong/cli-template)](https://goreportcard.com/report/github.com/samzong/cli-template)
[![Go Version](https://img.shields.io/github/go-mod/go-version/samzong/cli-template)](https://go.dev/)
[![Release](https://img.shields.io/github/release/samzong/cli-template.svg)](https://github.com/samzong/cli-template/releases)
[![Downloads](https://img.shields.io/github/downloads/samzong/cli-template/total.svg)](https://github.com/samzong/cli-template/releases)
[![Go Reference](https://pkg.go.dev/badge/github.com/samzong/cli-template.svg)](https://pkg.go.dev/github.com/samzong/cli-template)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI Status](https://img.shields.io/github/actions/workflow/status/samzong/cli-template/ci.yml?branch=main)](https://github.com/samzong/cli-template/actions)

A production-ready template for creating Go CLI applications with Cobra/Viper, automated CI/CD, Docker support, and Homebrew publishing.

## Quick Start

**Option 1: Use GitHub Actions (No Git Clone Required)**

1. Fork this repository
2. Go to **Actions** → **Setup Project** → **Run workflow**
3. Fill in the form (all fields are optional - defaults are auto-detected from your repository):
   - Module path: Optional (defaults to `github.com/{owner}/{repo}`)
   - CLI name: Optional (defaults to repository name)
   - GitHub user: Optional (defaults to repository owner)
   - Enable Docker (optional)
   - Other options as needed
4. Click **Run workflow**
5. Review and merge the created PR

**Option 2: Local Setup**

```bash
git clone https://github.com/samzong/cli-template.git my-cli-project
cd my-cli-project
chmod +x customize.sh
./customize.sh github.com/yourusername/yourproject yourcli

# With Docker support
./customize.sh github.com/yourusername/yourproject yourcli \
    --enable-docker --description "My CLI tool"
```

**Build and test:**

```bash
make check         # Run quality checks
make build         # Build binary
./build/yourcli --help
```

## Common Commands

| Command                   | Description                                |
| ------------------------- | ------------------------------------------ |
| `make build`              | Build binary for current platform          |
| `make build-all`          | Build for all platforms                    |
| `make check`              | Run all quality checks (fmt + lint + test) |
| `make test`               | Run tests                                  |
| `make test-coverage`      | Generate coverage report                   |
| `make docker-build`       | Build Docker image                         |
| `make release TAG=v1.0.0` | Create release tag                         |

## Release

Tag a release and push to trigger automated builds:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

This automatically:

- Builds binaries for all platforms
- Creates Docker images for amd64 and arm64 and publishes to GHCR
- Generates release notes and uploads assets
- Updates Homebrew formula

**Required GitHub Secrets:**

- `GH_PAT` - GitHub Personal Access Token (repo, workflow, write:packages)
- `HOMEBREW_TAP_GITHUB_TOKEN` - For Homebrew tap updates

## Docker & Homebrew

**Docker:**

Multi-architecture support (amd64 + arm64) with automatic platform detection:

```bash
make docker-build                                    # Build image
make docker-run                                      # Run container
docker pull ghcr.io/yourusername/yourcli:latest     # Automatically selects correct architecture
```

The Docker image automatically adapts to your platform - pull `latest` or `v1.0.0` and Docker will use the correct architecture (amd64 or arm64).

**Homebrew:**

Flexible tap configuration with `owner/repo` format:

```bash
# Default: uses yourusername/homebrew-tap
./customize.sh github.com/yourusername/yourproject yourcli

# Custom tap name (uses github-user as owner)
./customize.sh github.com/yourusername/yourproject yourcli \
    --homebrew-tap homebrew-cli
# Result: yourusername/homebrew-cli

# Different owner/organization (e.g., homebrew/core)
./customize.sh github.com/yourusername/yourproject yourcli \
    --homebrew-tap homebrew/core
# Result: homebrew/homebrew-core
```

Installation:

```bash
brew tap yourusername/tap           # Default tap name
# or
brew tap yourusername/cli            # Custom tap name
# or
brew install yourcli                 # From homebrew/core (official tap)
```

**Docker (GHCR):**

Docker registry owner is optional - defaults to your GitHub username:

```bash
# Default: Docker images use same owner as GitHub project
./customize.sh github.com/yourusername/yourproject yourcli --enable-docker
# Result: ghcr.io/yourusername/yourcli

# Only specify if different from GitHub user
./customize.sh github.com/yourusername/yourproject yourcli \
    --enable-docker \
    --docker-registry-owner different-owner
# Result: ghcr.io/different-owner/yourcli (while GitHub project is yourusername/yourproject)
```

Releases automatically update the Homebrew formula via PR to your homebrew-tap repository (e.g., `github.com/yourusername/homebrew-tap` or `github.com/homebrew/homebrew-core`).

## Troubleshooting

- **Build issues:** `make clean && make build`
- **Docker issues:** `make docker-clean`
- **Debug mode:** `DEBUG=1 ./customize.sh ...`

## License

MIT License - see [LICENSE](LICENSE) file for details.
