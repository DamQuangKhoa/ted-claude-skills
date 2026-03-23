#!/bin/bash

# Ted's Claude Skills Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/DamQuangKhoa/ted-claude-skills/main/install.sh | bash -s [profile]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROFILE="${1:-default}"
CLAUDE_DIR="$(pwd)/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
REPO_BASE_URL="https://raw.githubusercontent.com/DamQuangKhoa/ted-claude-skills/main"

# Function to print colored messages
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to download file
download_file() {
    local url=$1
    local dest=$2
    
    if curl -fsSL "$url" -o "$dest"; then
        return 0
    else
        return 1
    fi
}

# Function to backup existing files
backup_if_exists() {
    local file=$1
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Backing up existing file to: $backup"
        cp "$file" "$backup"
    fi
}

# Main installation
main() {
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║   Ted's Claude Skills Installer       ║"
    echo "║   Profile: ${PROFILE}                 ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    print_info "Installing to: $(pwd)/.claude"
    echo ""
    
    # Create directory structure
    print_info "Creating directory structure..."
    mkdir -p "$CLAUDE_DIR"
    mkdir -p "$SKILLS_DIR"
    print_success "Directories created"
    
    # Download claude.md
    print_info "Downloading claude.md..."
    backup_if_exists "$CLAUDE_DIR/claude.md"
    if download_file "$REPO_BASE_URL/claude.md" "$CLAUDE_DIR/claude.md"; then
        print_success "claude.md downloaded"
    else
        print_error "Failed to download claude.md"
        exit 1
    fi
    
    # Download skills
    print_info "Installing skills..."
    
    # Skill 1: skill-creator
    print_info "  → Installing skill-creator..."
    mkdir -p "$SKILLS_DIR/skill-creator"
    mkdir -p "$SKILLS_DIR/skill-creator/agents"
    mkdir -p "$SKILLS_DIR/skill-creator/assets"
    mkdir -p "$SKILLS_DIR/skill-creator/eval-viewer"
    mkdir -p "$SKILLS_DIR/skill-creator/references"
    mkdir -p "$SKILLS_DIR/skill-creator/scripts"
    
    # Download skill-creator files
    local skill_creator_files=(
        "skills/skill-creator/SKILL.md"
        "skills/skill-creator/LICENSE.txt"
        "skills/skill-creator/agents/analyzer.md"
        "skills/skill-creator/agents/comparator.md"
        "skills/skill-creator/agents/grader.md"
        "skills/skill-creator/assets/eval_review.html"
        "skills/skill-creator/eval-viewer/generate_review.py"
        "skills/skill-creator/eval-viewer/viewer.html"
        "skills/skill-creator/references/schemas.md"
        "skills/skill-creator/scripts/__init__.py"
        "skills/skill-creator/scripts/aggregate_benchmark.py"
        "skills/skill-creator/scripts/generate_report.py"
        "skills/skill-creator/scripts/improve_description.py"
        "skills/skill-creator/scripts/package_skill.py"
        "skills/skill-creator/scripts/quick_validate.py"
        "skills/skill-creator/scripts/run_eval.py"
        "skills/skill-creator/scripts/run_loop.py"
        "skills/skill-creator/scripts/utils.py"
    )
    
    for file in "${skill_creator_files[@]}"; do
        dest="$CLAUDE_DIR/$file"
        if download_file "$REPO_BASE_URL/$file" "$dest"; then
            print_success "    ✓ $(basename $file)"
        else
            print_warning "    ⚠ Failed to download $(basename $file)"
        fi
    done
    
    print_success "Skills installation completed"
    
    # Set proper permissions
    print_info "Setting permissions..."
    chmod -R 755 "$CLAUDE_DIR"
    print_success "Permissions set"
    
    # Summary
    echo ""
    echo "╔════════════════════════════════════════╗"
    echo "║          Installation Complete         ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    print_success "Claude configuration installed to: $CLAUDE_DIR"
    echo ""
    echo "Installed components:"
    echo "  • .claude/claude.md configuration"
    echo "  • .claude/skills/skill-creator/ skill"
    echo ""
    print_info "VS Code will automatically detect .claude folder in your workspace"
    echo ""
}

# Run main installation
main
