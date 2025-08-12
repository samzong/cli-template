# Enhanced CLI Template

A comprehensive template project for quickly creating production-ready Go CLI applications with advanced CI/CD, Docker support, and automated Homebrew publishing.

## ✨ Features

### 🚀 Core Framework
- **Command-line framework** based on [Cobra](https://github.com/spf13/cobra)
- **Configuration management** using [Viper](https://github.com/spf13/viper)
- **Cross-platform support** (Linux, macOS, Windows, ARM64)
- **Built-in help and version commands** with build-time variable injection

### 🔧 Enhanced Build System
- **Advanced Makefile** with colored output and comprehensive targets
- **GoReleaser configuration** with Docker and Homebrew support
- **Multi-platform builds** with optimized binaries
- **Code quality tools** (golangci-lint, goimports, race detection)
- **Test coverage reporting** with HTML output

### 🐳 Docker Support
- **Multi-architecture Docker images** (amd64, arm64)
- **GitHub Container Registry** publishing
- **Optimized container builds** with GoReleaser integration
- **Security-focused containers** with non-root users

### 🍺 Advanced Homebrew Integration
- **Automated formula updates** with conflict prevention
- **Multi-branch strategy** for safe updates
- **Comprehensive SHA verification** for all platforms
- **PR-based updates** to homebrew-tap repositories

### 🔄 Comprehensive CI/CD
- **Enhanced GitHub Actions** with matrix builds
- **Security scanning** (Gosec, Trivy, govulncheck)
- **Quality gates** with formatting and linting
- **Cross-platform testing** on multiple Go versions
- **Automated release management** with validation

### 🛠️ Developer Experience
- **Smart customization script** with validation and dry-run mode
- **Colored terminal output** for better visibility
- **Comprehensive help system** with categorized commands
- **Development dependency management** with auto-installation

## 🚀 Quick Start

### 1. Use this Template

Click the "Use this template" button on GitHub or clone the repository:

```bash
git clone https://github.com/samzong/cli-template.git my-cli-project
cd my-cli-project
```

### 2. Customize for Your Project

Use the enhanced customization script with interactive options:

```bash
# Basic customization
chmod +x customize-enhanced.sh
./customize-enhanced.sh github.com/yourusername/yourproject yourcli

# Advanced customization with Docker support
./customize-enhanced.sh github.com/yourusername/yourproject yourcli \
    --enable-docker \
    --description "My awesome CLI tool" \
    --homebrew-tap homebrew-tools

# Dry run to see what would be changed
./customize-enhanced.sh github.com/yourusername/yourproject yourcli --dry-run
```

### 3. Build and Test

```bash
# Install development dependencies
make install-deps

# Run quality checks
make check

# Build for current platform
make build

# Build for all platforms
make build-all

# Run the binary
./bin/yourcli --help
```

## 📋 Available Make Targets

### Development
```bash
make build          # Build binary for current platform
make build-all      # Build for all supported platforms
make install        # Install binary to GOPATH/bin
make run            # Build and run (use ARGS="--help" for arguments)
make clean          # Remove build artifacts
```

### Code Quality
```bash
make fmt            # Format code and tidy modules
make lint           # Run golangci-lint
make lint-fix       # Run linter with auto-fix
make check          # Run all quality checks
make install-deps   # Install development tools
```

### Testing
```bash
make test           # Run all tests
make test-coverage  # Generate coverage report
make test-race      # Run with race detection
make test-bench     # Run benchmark tests
```

### Docker
```bash
make docker-build   # Build Docker image
make docker-run     # Run Docker container
make docker-clean   # Clean Docker artifacts
```

### Release
```bash
make release TAG=v1.0.0  # Create and push release tag
make update-homebrew     # Update Homebrew formula
make version            # Show version information
```

## 🔧 Configuration Options

### Customization Script Options

```bash
./customize-enhanced.sh <MODULE_PATH> <CLI_NAME> [OPTIONS]

Arguments:
  MODULE_PATH     New Go module path (e.g., github.com/you/project)
  CLI_NAME        New CLI binary name (e.g., yourcli)

Options:
  --github-user   GitHub username (default: extracted from module)
  --enable-docker Enable Docker support in GoReleaser
  --homebrew-tap  Homebrew tap repository name (default: homebrew-tap)
  --description   Project description for Homebrew formula
  --homepage      Project homepage URL
  --dry-run       Show changes without applying them
  --help          Show help message
```

### Environment Variables

The Makefile supports several environment variables for customization:

```bash
# Homebrew update testing
DRY_RUN=1 make update-homebrew

# Custom build arguments
ARGS="--config /path/to/config" make run

# Custom build directory
BUILD_DIR=./custom-build make build
```

## 🚀 Release Process

### 1. Automated Release (Recommended)

```bash
# Create and push a version tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

This triggers the automated release workflow that:
- ✅ Validates version format and runs quality checks
- ✅ Builds binaries for all platforms using GoReleaser
- ✅ Creates Docker images and publishes to GHCR
- ✅ Generates release notes and uploads assets
- ✅ Triggers Homebrew formula update
- ✅ Runs security scanning and validation

### 2. Manual Release

```bash
# Create release using Make
make release TAG=v1.0.0

# Update Homebrew formula manually
GH_PAT=your_token make update-homebrew
```

### 3. Required GitHub Secrets

Set these secrets in your GitHub repository settings:

| Secret | Description | Required For |
|--------|-------------|--------------|
| `GH_PAT` | GitHub Personal Access Token | Homebrew updates, cross-repo triggers |
| `HOMEBREW_TAP_GITHUB_TOKEN` | Token for Homebrew tap repo | Automated formula updates |

**Permissions needed for `GH_PAT`:**
- `repo` (full repository access)
- `workflow` (update GitHub Actions workflows)
- `write:packages` (publish Docker images)

## 🐳 Docker Usage

### Building Images

```bash
# Build locally
make docker-build

# Run container
make docker-run

# Clean up
make docker-clean
```

### Using Published Images

```bash
# Pull from GitHub Container Registry
docker pull ghcr.io/yourusername/yourcli:latest

# Run with volume mount
docker run --rm -v $(pwd):/workspace ghcr.io/yourusername/yourcli:latest
```

### Custom Dockerfile

The template includes `Dockerfile.goreleaser` for GoReleaser builds. You can also create a regular `Dockerfile`:

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY . .
RUN make build

FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/bin/yourcli /usr/local/bin/
ENTRYPOINT ["yourcli"]
```

## 🍺 Homebrew Integration

### Automatic Updates

When you create a release, the Homebrew formula is automatically updated:

1. **Release triggers** workflow with version information
2. **Formula updater** downloads binaries and calculates checksums
3. **PR creation** to your homebrew-tap repository
4. **Manual review** and merge of the PR

### Manual Homebrew Setup

```bash
# Install from your tap
brew install yourusername/tap/yourcli

# Update formula manually
GH_PAT=your_token make update-homebrew
```

### Homebrew Tap Structure

Your homebrew-tap repository should have this structure:
```
homebrew-tap/
├── Formula/
│   └── yourcli.rb
└── README.md
```

## 🔍 Quality Assurance

### Code Quality Tools

- **golangci-lint**: Comprehensive linting with 50+ linters
- **goimports**: Automatic import formatting
- **go fmt**: Standard Go formatting
- **go mod tidy**: Dependency management

### Security Scanning

- **Gosec**: Go security scanner for common vulnerabilities
- **govulncheck**: Known vulnerability database checking
- **Trivy**: Container and filesystem vulnerability scanning

### Testing Strategy

- **Unit tests**: Standard Go testing with race detection
- **Benchmark tests**: Performance testing and monitoring
- **Integration tests**: End-to-end functionality validation
- **Cross-platform testing**: Linux, macOS, Windows validation

## 📚 Documentation

### Code Documentation

```bash
# Generate documentation
go doc ./...

# Start documentation server
godoc -http=:6060
```

### Contributing Guidelines

1. **Fork and clone** the repository
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Run quality checks**: `make check`
4. **Commit changes**: `git commit -m 'Add amazing feature'`
5. **Push to branch**: `git push origin feature/amazing-feature`
6. **Open a Pull Request** with description

## 🛠️ Troubleshooting

### Common Issues

**Build failures:**
```bash
# Clean and rebuild
make clean && make build

# Check Go version
go version

# Verify dependencies
go mod verify
```

**Docker issues:**
```bash
# Clean Docker build cache
make docker-clean

# Rebuild without cache
docker build --no-cache -t myapp .
```

**Homebrew update failures:**
```bash
# Test with dry run
DRY_RUN=1 make update-homebrew

# Check token permissions
curl -H "Authorization: token $GH_PAT" https://api.github.com/user
```

### Debug Mode

Enable debug output in the customization script:
```bash
DEBUG=1 ./customize-enhanced.sh ...
```

## 📈 Advanced Features

### Custom Build Variables

Add build-time variables to your application:

```go
// cmd/version.go
var (
    Version   = "dev"
    BuildTime = "unknown"
    Commit    = "unknown"
    BuiltBy   = "manual"
)
```

Update GoReleaser configuration:
```yaml
ldflags:
  - -X main.Version={{.Version}}
  - -X main.BuildTime={{.Date}}
  - -X main.Commit={{.Commit}}
  - -X main.BuiltBy=goreleaser
```

### Multi-Architecture Support

The template supports building for:
- `linux/amd64` and `linux/arm64`
- `darwin/amd64` and `darwin/arm64` (Apple Silicon)
- `windows/amd64`

### Performance Optimization

- **Static linking**: CGO disabled for portable binaries
- **Binary stripping**: Debug info removed for smaller size
- **Trimpath**: Reproducible builds with clean paths
- **Build caching**: Go module and build cache optimization

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/yourcli/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/yourcli/discussions)
- **Security**: Report security issues to security@yourdomain.com

---

## 🎉 Getting Started Examples

### Basic CLI Tool
```bash
./customize-enhanced.sh github.com/johndoe/hello-cli hello
make build
./bin/hello --help
```

### CLI with Docker Support
```bash
./customize-enhanced.sh github.com/johndoe/docker-cli dcli --enable-docker
make docker-build
make docker-run
```

### Enterprise CLI Tool
```bash
./customize-enhanced.sh github.com/company/enterprise-tool etool \
    --description "Enterprise automation tool" \
    --homebrew-tap homebrew-enterprise \
    --homepage "https://company.com/etool"
```

Start building amazing CLI tools! 🚀
