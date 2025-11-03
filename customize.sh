#!/bin/bash

set -e

ORIGINAL_MODULE_PATH="github.com/samzong/cli-template"
ORIGINAL_CLI_NAME="mycli"

die() { echo "Error: $1" >&2; exit 1; }

show_usage() {
    cat << 'EOF'
Usage: ./customize.sh <MODULE_PATH> <CLI_NAME> [OPTIONS]

Arguments:
  MODULE_PATH           New Go module path (e.g., github.com/user/project)
  CLI_NAME              New CLI binary name (e.g., mycli)

Options:
  --github-user USER         GitHub username (default: from module path)
  --enable-docker            Enable Docker support in GoReleaser
  --docker-registry-owner    Docker registry owner for GHCR (optional, default: github-user)
  --homebrew-tap TAP         Homebrew tap repository (default: homebrew-tap, format: owner/repo or repo)
  --description DESC         Project description
  --homepage URL             Project homepage URL
  --dry-run                  Show changes without applying
  -y, --yes                  Skip confirmation prompt (non-interactive mode)
  -h, --help                 Show this help

Examples:
  ./customize.sh github.com/user/project myapp
  ./customize.sh github.com/user/project myapp --enable-docker
  ./customize.sh github.com/user/project myapp --homebrew-tap owner/repo
EOF
}

parse_args() {
    if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
        show_usage
        exit 0
    fi
    
    [ $# -lt 2 ] && { show_usage; exit 1; }
    NEW_MODULE_PATH="$1"
    CLI_NAME="$2"
    shift 2
    GITHUB_USER=""
    ENABLE_DOCKER=false
    DOCKER_REGISTRY_OWNER=""
    HOMEBREW_TAP=""
    DESCRIPTION="A CLI application built with Go"
    HOMEPAGE=""
    DRY_RUN=false
    SKIP_CONFIRM=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --github-user) GITHUB_USER="$2"; shift 2 ;;
            --enable-docker) ENABLE_DOCKER=true; shift ;;
            --docker-registry-owner) DOCKER_REGISTRY_OWNER="$2"; shift 2 ;;
            --homebrew-tap) HOMEBREW_TAP="$2"; shift 2 ;;
            --description) DESCRIPTION="$2"; shift 2 ;;
            --homepage) HOMEPAGE="$2"; shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;;
            -y|--yes) SKIP_CONFIRM=true; shift ;;
            -h|--help) show_usage; exit 0 ;;
            *) die "Unknown option: $1" ;;
        esac
    done
    [ -z "$GITHUB_USER" ] && GITHUB_USER=$(echo "$NEW_MODULE_PATH" | cut -d'/' -f2)
    [ -z "$DOCKER_REGISTRY_OWNER" ] && DOCKER_REGISTRY_OWNER="$GITHUB_USER"
    
    # Parse homebrew-tap: support owner/repo format or just repo name
    if [ -z "$HOMEBREW_TAP" ]; then
        # Default: use homebrew-tap with github-user as owner
        HOMEBREW_OWNER="$GITHUB_USER"
        HOMEBREW_TAP_NAME="homebrew-tap"
    elif [[ "$HOMEBREW_TAP" == *"/"* ]]; then
        # Format: owner/repo
        HOMEBREW_OWNER=$(echo "$HOMEBREW_TAP" | cut -d'/' -f1)
        HOMEBREW_TAP_NAME=$(echo "$HOMEBREW_TAP" | cut -d'/' -f2)
    else
        # Format: repo only, use github-user as owner
        HOMEBREW_OWNER="$GITHUB_USER"
        HOMEBREW_TAP_NAME="$HOMEBREW_TAP"
    fi
    
    [ -z "$HOMEPAGE" ] && HOMEPAGE="https://github.com/$GITHUB_USER/$CLI_NAME"
}

validate_inputs() {
    git rev-parse --git-dir >/dev/null 2>&1 || die "Must be run in a Git repository"
    
    [[ "$NEW_MODULE_PATH" =~ ^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$ ]] || 
        die "Invalid module path format. Expected: domain.com/username/project"
    
    [[ "$CLI_NAME" =~ ^[a-zA-Z0-9_-]+$ ]] || 
        die "Invalid CLI name. Use letters, numbers, underscores, hyphens only"
    
    for file in go.mod cmd/root.go Makefile; do
        [ -f "$file" ] || die "Required file not found: $file"
    done
}

apply_sed() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    [ "$DRY_RUN" = true ] && { echo "Would update $file: $pattern -> $replacement"; return; }
    # macOS requires empty string after -i, Linux doesn't
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|$pattern|$replacement|g" "$file"
    else
        sed -i "s|$pattern|$replacement|g" "$file"
    fi
}

bulk_replace() {
    local pattern="$1"
    local replacement="$2"
    shift 2
    for file in "$@"; do
        [ -f "$file" ] && apply_sed "$file" "$pattern" "$replacement"
    done
}

find_and_replace() {
    local pattern="$1"
    local replacement="$2"
    local file_pattern="$3"
    if [ "$DRY_RUN" = true ]; then
        echo "Would update all $file_pattern files: $pattern -> $replacement"
        return
    fi
    # macOS requires empty string after -i, Linux doesn't
    if [[ "$OSTYPE" == "darwin"* ]]; then
        find . -type f -name "$file_pattern" \
            -exec sed -i '' "s|$pattern|$replacement|g" {} \;
    else
        find . -type f -name "$file_pattern" \
            -exec sed -i "s|$pattern|$replacement|g" {} \;
    fi
}

update_go_files() {
    apply_sed "go.mod" "module $ORIGINAL_MODULE_PATH" "module $NEW_MODULE_PATH"
    find_and_replace "$ORIGINAL_MODULE_PATH" "$NEW_MODULE_PATH" "*.go"
    apply_sed "cmd/root.go" "CLI_NAME  = \"$ORIGINAL_CLI_NAME\"" "CLI_NAME  = \"$CLI_NAME\""
}

update_makefile() {
    bulk_replace "BINARY_NAME=$ORIGINAL_CLI_NAME" "BINARY_NAME=$CLI_NAME" Makefile
    bulk_replace "github.com/samzong/$ORIGINAL_CLI_NAME" "github.com/$GITHUB_USER/$CLI_NAME" Makefile
    bulk_replace "samzong/$ORIGINAL_CLI_NAME" "$GITHUB_USER/$CLI_NAME" Makefile
    bulk_replace "$ORIGINAL_MODULE_PATH" "$NEW_MODULE_PATH" Makefile
    [ "$HOMEBREW_TAP_NAME" != "homebrew-tap" ] && 
        apply_sed "Makefile" "HOMEBREW_TAP_REPO=homebrew-tap" "HOMEBREW_TAP_REPO=$HOMEBREW_TAP_NAME"
}

update_goreleaser() {
    local file=".goreleaser.yaml"
    [ -f ".goreleaser.yaml.enhanced" ] && cp ".goreleaser.yaml.enhanced" "$file"
    bulk_replace "project_name: mycli" "project_name: $CLI_NAME" "$file"
    bulk_replace "id: mycli" "id: $CLI_NAME" "$file"
    bulk_replace "binary: mycli" "binary: $CLI_NAME" "$file"
    bulk_replace "$ORIGINAL_MODULE_PATH" "$NEW_MODULE_PATH" "$file"
    bulk_replace "samzong/mycli" "$GITHUB_USER/$CLI_NAME" "$file"
    bulk_replace "samzong/{{ .ProjectName }}" "$GITHUB_USER/{{ .ProjectName }}" "$file"
    bulk_replace "name: mycli" "name: $CLI_NAME" "$file"
    
    # Docker registry owner for GHCR (can be different from GitHub user)
    bulk_replace "ghcr.io/samzong" "ghcr.io/$DOCKER_REGISTRY_OWNER" "$file"
    
    # Homebrew configuration (can be different from GitHub user)
    bulk_replace "owner: samzong" "owner: $HOMEBREW_OWNER" "$file"
    bulk_replace "name: homebrew-tap" "name: $HOMEBREW_TAP_NAME" "$file"
    
    bulk_replace "description: \"A CLI application built with Go\"" "description: \"$DESCRIPTION\"" "$file"
    bulk_replace "homepage: \"https://github.com/samzong/mycli\"" "homepage: \"$HOMEPAGE\"" "$file"
    if [ "$ENABLE_DOCKER" = false ]; then
        if [ "$DRY_RUN" = false ]; then
            # macOS requires empty string after -i, Linux doesn't
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' '/^# Enhanced Docker support/,/^# Enhanced release configuration/s/^/# /' "$file"
            else
                sed -i '/^# Enhanced Docker support/,/^# Enhanced release configuration/s/^/# /' "$file"
            fi
        fi
    else
        create_dockerfile
    fi
}

create_dockerfile() {
    [ "$DRY_RUN" = true ] && { echo "Would create Dockerfile.goreleaser"; return; }
    [ -f "Dockerfile.goreleaser" ] && return
    cat > Dockerfile.goreleaser << 'EOF'
FROM alpine:latest
RUN apk --no-cache add ca-certificates
RUN addgroup -g 1001 appgroup && adduser -D -u 1001 -G appgroup appuser
WORKDIR /app
COPY mycli /app/mycli
RUN chown -R appuser:appgroup /app
USER appuser
EXPOSE 8080
ENTRYPOINT ["/app/mycli"]
EOF
    apply_sed "Dockerfile.goreleaser" "mycli" "$CLI_NAME"
}

update_workflows() {
    find_and_replace "samzong/$ORIGINAL_CLI_NAME" "$GITHUB_USER/$CLI_NAME" "*.yml"
    find_and_replace "samzong/mycli" "$GITHUB_USER/$CLI_NAME" "*.yml"
    find_and_replace "samzong/homebrew-tap" "$HOMEBREW_OWNER/$HOMEBREW_TAP_NAME" "*.yml"
}

update_readme() {
    local file="README.md"
    [ ! -f "$file" ] && return
    
    # Replace repository references in badges
    bulk_replace "samzong/cli-template" "$GITHUB_USER/$CLI_NAME" "$file"
}

update_config_files() {
    find_and_replace "\\.$ORIGINAL_CLI_NAME\\.yaml" ".$CLI_NAME.yaml" "*.go"
    find_and_replace "\\.$ORIGINAL_CLI_NAME\\.yml" ".$CLI_NAME.yml" "*.go"
    find_and_replace "\\.$ORIGINAL_CLI_NAME\\.json" ".$CLI_NAME.json" "*.go"
    
    if [ -f ".gitignore" ]; then
        bulk_replace "\\.$ORIGINAL_CLI_NAME\\.yaml" ".$CLI_NAME.yaml" .gitignore
        bulk_replace "\\.$ORIGINAL_CLI_NAME\\.yml" ".$CLI_NAME.yml" .gitignore
        bulk_replace "\\.$ORIGINAL_CLI_NAME\\.json" ".$CLI_NAME.json" .gitignore
    fi
}

finalize() {
    [ "$DRY_RUN" = true ] && { echo "Would run go mod tidy"; return; }
    go mod tidy
    rm -f .goreleaser.yaml.enhanced 2>/dev/null || true
}

show_summary() {
    cat << EOF
Configuration:
  Module: $ORIGINAL_MODULE_PATH -> $NEW_MODULE_PATH
  CLI:    $ORIGINAL_CLI_NAME -> $CLI_NAME
  GitHub User:   $GITHUB_USER
  Docker Registry Owner (GHCR): $DOCKER_REGISTRY_OWNER
  Homebrew: $HOMEBREW_OWNER/$HOMEBREW_TAP_NAME
  Docker: $ENABLE_DOCKER
  Dry:    $DRY_RUN

EOF
}

main() {
    parse_args "$@"
    
    validate_inputs
    show_summary
    
    if [ "$DRY_RUN" = false ] && [ "$SKIP_CONFIRM" = false ]; then
        read -p "Proceed? [y/N]: " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && { echo "Cancelled"; exit 0; }
    fi
    
    update_go_files
    update_makefile
    update_goreleaser
    update_workflows
    update_readme
    update_config_files
    finalize
    
    echo "✓ Customization complete"
    
    [ "$DRY_RUN" = false ] && cat << EOF

Next steps:
1. git diff
2. make build
3. git add . && git commit -m "Initial setup"
4. git remote add origin https://github.com/$GITHUB_USER/$CLI_NAME.git
5. git push -u origin main

EOF
}

main "$@"