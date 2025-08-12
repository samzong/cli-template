# CLI Template

A production-ready template for creating Go CLI applications with Cobra/Viper, automated CI/CD, Docker support, and Homebrew publishing.

## Key Features

- **Cobra/Viper framework** with cross-platform support (Linux, macOS, Windows, ARM64)
- **Advanced Makefile** with quality tools (golangci-lint, goimports, race detection)
- **GoReleaser** with multi-platform builds and automated releases
- **Docker support** with multi-architecture images and GHCR publishing
- **Homebrew integration** with automated formula updates
- **GitHub Actions CI/CD** with security scanning and quality gates
- **Smart customization script** with dry-run mode

## Quick Start

**1. Clone and customize:**

```bash
git clone https://github.com/samzong/cli-template.git my-cli-project
cd my-cli-project

# Basic setup
chmod +x customize.sh
./customize.sh github.com/yourusername/yourproject yourcli

# With Docker support
./customize.sh github.com/yourusername/yourproject yourcli \
    --enable-docker --description "My CLI tool"
```

**2. Build and test:**

```bash
make install-deps   # Install dev tools
make check         # Run quality checks
make build         # Build binary
./bin/yourcli --help
```

## Make Commands

| Command                   | Description                                |
| ------------------------- | ------------------------------------------ |
| `make build`              | Build binary for current platform          |
| `make build-all`          | Build for all platforms                    |
| `make check`              | Run all quality checks (fmt + lint + test) |
| `make test`               | Run tests                                  |
| `make test-coverage`      | Generate coverage report                   |
| `make docker-build`       | Build Docker image                         |
| `make release TAG=v1.0.0` | Create release tag                         |

## Customization Options

```bash
./customize.sh <MODULE_PATH> <CLI_NAME> [OPTIONS]

# Key options:
--enable-docker    # Add Docker support
--description      # Project description
--homebrew-tap     # Homebrew repository name
--dry-run          # Preview changes
```

## Release Process

**Automated (recommended):**

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

This automatically:

- Builds binaries for all platforms
- Creates Docker images and publishes to GHCR and DockerHub
- Generates release notes and uploads assets
- Updates Homebrew formula

**Required GitHub Secrets:**

- `GH_PAT` - GitHub Personal Access Token (repo, workflow, write:packages)
- `HOMEBREW_TAP_GITHUB_TOKEN` - For Homebrew tap updates

## Docker & Homebrew

**Docker usage:**

```bash
make docker-build                                    # Build image
make docker-run                                      # Run container
docker pull ghcr.io/yourusername/yourcli:latest     # Use published image
```

**Homebrew installation:**

```bash
brew tap samzong/tap
brew install yourcli               # Install from tap
```

Releases automatically update the Homebrew formula via PR to your homebrew-tap repository.

## Built-in Quality Tools

- **Code Quality**: golangci-lint, goimports, go fmt, race detection
- **Security**: Gosec, govulncheck, Trivy container scanning
- **Testing**: Unit tests, benchmarks, cross-platform validation
- **CI/CD**: GitHub Actions with matrix builds and automated releases

## roubleshooting

**Build issues:** `make clean && make build`
**Docker issues:** `make docker-clean`  
**Debug mode:** `DEBUG=1 ./customize.sh ...`

## Architecture

- **Multi-platform**: Linux, macOS, Windows (amd64/arm64)
- **Static linking**: CGO disabled for portable binaries
- **Build variables**: Version, commit, build time injection via ldflags

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Ready to build your CLI?** Start with the Quick Start section above! 🚀
