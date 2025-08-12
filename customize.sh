#!/bin/bash

set -e

ORIGINAL_MODULE_PATH="github.com/samzong/cli-template"
ORIGINAL_CLI_NAME="mycli"

die() { echo "Error: $1" >&2; exit 1; }

show_usage() {
    cat << 'EOF'
Usage: ./customize.sh <MODULE_PATH> <CLI_NAME> [OPTIONS]
       ./customize.sh --rollback [BACKUP_DIR]
       ./customize.sh --list-backups

Arguments:
  MODULE_PATH    New Go module path (e.g., github.com/user/project)
  CLI_NAME       New CLI binary name (e.g., mycli)

Options:
  --github-user USER     GitHub username (default: from module path)
  --enable-docker        Enable Docker support in GoReleaser
  --homebrew-tap TAP     Homebrew tap name (default: homebrew-tap)
  --description DESC     Project description
  --homepage URL         Project homepage URL
  --dry-run             Show changes without applying
  --rollback [DIR]      Rollback to backup (latest if DIR not specified)
  --list-backups        List available backups
  --help                Show this help

Examples:
  ./customize.sh github.com/user/project myapp
  ./customize.sh github.com/user/project myapp --enable-docker
  ./customize.sh --rollback
  ./customize.sh --rollback .customize-backup-20240812-141500
  ./customize.sh --list-backups
EOF
}

parse_args() {
    # Handle rollback and list-backups modes
    case "${1:-}" in
        --rollback)
            ROLLBACK_MODE=true
            BACKUP_DIR="${2:-}"
            return
            ;;
        --list-backups)
            list_backups
            exit 0
            ;;
        --help)
            show_usage
            exit 0
            ;;
    esac
    
    [ $# -lt 2 ] && { show_usage; exit 1; }
    NEW_MODULE_PATH="$1"
    CLI_NAME="$2"
    shift 2
    GITHUB_USER=""
    ENABLE_DOCKER=false
    HOMEBREW_TAP="homebrew-tap"
    DESCRIPTION="A CLI application built with Go"
    HOMEPAGE=""
    DRY_RUN=false
    ROLLBACK_MODE=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --github-user) GITHUB_USER="$2"; shift 2 ;;
            --enable-docker) ENABLE_DOCKER=true; shift ;;
            --homebrew-tap) HOMEBREW_TAP="$2"; shift 2 ;;
            --description) DESCRIPTION="$2"; shift 2 ;;
            --homepage) HOMEPAGE="$2"; shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;;
            --help) show_usage; exit 0 ;;
            *) die "Unknown option: $1" ;;
        esac
    done
    [ -z "$GITHUB_USER" ] && GITHUB_USER=$(echo "$NEW_MODULE_PATH" | cut -d'/' -f2)
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

backup_files() {
    [ "$DRY_RUN" = true ] && { echo "Would create backup"; return; }
    local backup_dir=".customize-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    cp go.mod Makefile "$backup_dir/"
    cp .goreleaser.yaml "$backup_dir/" 2>/dev/null || true
    cp -r cmd "$backup_dir/" 2>/dev/null || true
    [ -d ".github" ] && cp -r .github "$backup_dir/" 2>/dev/null || true
    [ -f ".gitignore" ] && cp .gitignore "$backup_dir/" 2>/dev/null || true
    [ -f "Dockerfile.goreleaser" ] && cp Dockerfile.goreleaser "$backup_dir/" 2>/dev/null || true
    echo "Backup created: $backup_dir"
}

list_backups() {
    echo "Available backups:"
    local backups=($(ls -d .customize-backup-* 2>/dev/null | sort -r))
    if [ ${#backups[@]} -eq 0 ]; then
        echo "  No backups found"
        return
    fi
    
    for backup in "${backups[@]}"; do
        local timestamp=$(echo "$backup" | grep -o '[0-9]\{8\}-[0-9]\{6\}')
        local date_formatted=$(date -j -f "%Y%m%d-%H%M%S" "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
        echo "  $backup (created: $date_formatted)"
    done
}

find_latest_backup() {
    local latest=$(ls -d .customize-backup-* 2>/dev/null | sort -r | head -n1)
    echo "$latest"
}

validate_backup() {
    local backup_dir="$1"
    [ -z "$backup_dir" ] && die "Backup directory not specified"
    [ ! -d "$backup_dir" ] && die "Backup directory not found: $backup_dir"
    [ ! -f "$backup_dir/go.mod" ] && die "Invalid backup: missing go.mod"
    [ ! -f "$backup_dir/Makefile" ] && die "Invalid backup: missing Makefile"
    [ ! -d "$backup_dir/cmd" ] && die "Invalid backup: missing cmd directory"
}

rollback_files() {
    local backup_dir="$1"
    
    echo "Rolling back from backup: $backup_dir"
    
    # Restore main files
    cp "$backup_dir/go.mod" .
    cp "$backup_dir/Makefile" .
    [ -f "$backup_dir/.goreleaser.yaml" ] && cp "$backup_dir/.goreleaser.yaml" .
    [ -f "$backup_dir/.gitignore" ] && cp "$backup_dir/.gitignore" .
    [ -f "$backup_dir/Dockerfile.goreleaser" ] && cp "$backup_dir/Dockerfile.goreleaser" .
    
    # Restore directories
    rm -rf cmd
    cp -r "$backup_dir/cmd" .
    
    if [ -d "$backup_dir/.github" ]; then
        rm -rf .github
        cp -r "$backup_dir/.github" .
    fi
    
    # Clean up Go modules
    go mod tidy
    
    echo "✓ Rollback completed successfully"
    echo
    echo "Files restored from backup created at:"
    local timestamp=$(echo "$backup_dir" | grep -o '[0-9]\{8\}-[0-9]\{6\}')
    date -j -f "%Y%m%d-%H%M%S" "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp"
}

perform_rollback() {
    local backup_dir="$BACKUP_DIR"
    
    if [ -z "$backup_dir" ]; then
        backup_dir=$(find_latest_backup)
        [ -z "$backup_dir" ] && die "No backups found. Use --list-backups to see available backups."
        echo "Using latest backup: $backup_dir"
    fi
    
    validate_backup "$backup_dir"
    
    echo "This will restore files from backup and overwrite current changes."
    read -p "Are you sure you want to rollback? [y/N]: " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && { echo "Rollback cancelled"; exit 0; }
    
    rollback_files "$backup_dir"
}

apply_sed() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    [ "$DRY_RUN" = true ] && { echo "Would update $file: $pattern -> $replacement"; return; }
    sed -i '' "s|$pattern|$replacement|g" "$file"
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
    local exclude_path="$4"
    if [ "$DRY_RUN" = true ]; then
        echo "Would update all $file_pattern files: $pattern -> $replacement"
        return
    fi
    find . -type f -name "$file_pattern" -not -path "$exclude_path" \
        -exec sed -i '' "s|$pattern|$replacement|g" {} \;
}

update_go_files() {
    apply_sed "go.mod" "module $ORIGINAL_MODULE_PATH" "module $NEW_MODULE_PATH"
    find_and_replace "$ORIGINAL_MODULE_PATH" "$NEW_MODULE_PATH" "*.go" "./.customize-backup-*"
    apply_sed "cmd/root.go" "CLI_NAME  = \"$ORIGINAL_CLI_NAME\"" "CLI_NAME  = \"$CLI_NAME\""
}

update_makefile() {
    bulk_replace "BINARY_NAME=$ORIGINAL_CLI_NAME" "BINARY_NAME=$CLI_NAME" Makefile
    bulk_replace "github.com/samzong/$ORIGINAL_CLI_NAME" "github.com/$GITHUB_USER/$CLI_NAME" Makefile
    bulk_replace "samzong/$ORIGINAL_CLI_NAME" "$GITHUB_USER/$CLI_NAME" Makefile
    bulk_replace "$ORIGINAL_MODULE_PATH" "$NEW_MODULE_PATH" Makefile
    [ "$HOMEBREW_TAP" != "homebrew-tap" ] && 
        apply_sed "Makefile" "HOMEBREW_TAP_REPO=homebrew-tap" "HOMEBREW_TAP_REPO=$HOMEBREW_TAP"
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
    bulk_replace "owner: samzong" "owner: $GITHUB_USER" "$file"
    bulk_replace "name: homebrew-tap" "name: $HOMEBREW_TAP" "$file"
    bulk_replace "description: \"A CLI application built with Go\"" "description: \"$DESCRIPTION\"" "$file"
    bulk_replace "homepage: \"https://github.com/samzong/mycli\"" "homepage: \"$HOMEPAGE\"" "$file"
    if [ "$ENABLE_DOCKER" = false ]; then
        [ "$DRY_RUN" = false ] && 
            sed -i '' '/^# Enhanced Docker support/,/^# Enhanced release configuration/s/^/# /' "$file"
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
    find_and_replace "samzong/$ORIGINAL_CLI_NAME" "$GITHUB_USER/$CLI_NAME" "*.yml" ""
    find_and_replace "samzong/mycli" "$GITHUB_USER/$CLI_NAME" "*.yml" ""
    find_and_replace "samzong/homebrew-tap" "$GITHUB_USER/$HOMEBREW_TAP" "*.yml" ""
}

update_config_files() {
    find_and_replace "\\.$ORIGINAL_CLI_NAME\\.yaml" ".$CLI_NAME.yaml" "*.go" "./.customize-backup-*"
    find_and_replace "\\.$ORIGINAL_CLI_NAME\\.yml" ".$CLI_NAME.yml" "*.go" "./.customize-backup-*"
    find_and_replace "\\.$ORIGINAL_CLI_NAME\\.json" ".$CLI_NAME.json" "*.go" "./.customize-backup-*"
    
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
  User:   $GITHUB_USER
  Tap:    $HOMEBREW_TAP
  Docker: $ENABLE_DOCKER
  Dry:    $DRY_RUN

EOF
}

main() {
    parse_args "$@"
    
    # Handle rollback mode
    if [ "$ROLLBACK_MODE" = true ]; then
        perform_rollback
        exit 0
    fi
    
    validate_inputs
    show_summary
    
    if [ "$DRY_RUN" = false ]; then
        read -p "Proceed? [y/N]: " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && { echo "Cancelled"; exit 0; }
    fi
    
    backup_files
    update_go_files
    update_makefile
    update_goreleaser
    update_workflows
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