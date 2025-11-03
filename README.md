# CLI Template

A production-ready template for creating Go CLI applications with Cobra/Viper, automated CI/CD, Docker support, and Homebrew publishing.

## Quick Start

**1. Clone and customize:**

```bash
git clone https://github.com/samzong/cli-template.git my-cli-project
cd my-cli-project
chmod +x customize.sh
./customize.sh github.com/yourusername/yourproject yourcli

# With Docker support
./customize.sh github.com/yourusername/yourproject yourcli \
    --enable-docker --description "My CLI tool"
```

**2. Build and test:**

```bash
make check         # Run quality checks
make build         # Build binary
./build/yourcli --help
```

## Common Commands

| Command                   | Description                                           |
| ------------------------- | ----------------------------------------------------- |
| `make build`              | Build binary for current platform                    |
| `make build-all`          | Build for all platforms                               |
| `make check`              | Run all quality checks (fmt + lint + test)           |
| `make test`               | Run tests                                              |
| `make test-coverage`      | Generate coverage report                               |
| `make docker-build`       | Build Docker image                                     |
| `make release TAG=v1.0.0` | Create release tag                                     |

## Release

Tag a release and push to trigger automated builds:

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

**Docker:**

```bash
make docker-build                                    # Build image
make docker-run                                      # Run container
docker pull ghcr.io/yourusername/yourcli:latest     # Use published image
```

**Homebrew:**

```bash
brew tap samzong/tap
brew install yourcli               # Install from tap
```

Releases automatically update the Homebrew formula via PR to your homebrew-tap repository.

## Troubleshooting

- **Build issues:** `make clean && make build`
- **Docker issues:** `make docker-clean`
- **Debug mode:** `DEBUG=1 ./customize.sh ...`

## License

MIT License - see [LICENSE](LICENSE) file for details.
