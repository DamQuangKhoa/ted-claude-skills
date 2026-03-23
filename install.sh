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
GITHUB_DIR="$(pwd)/.github"
COPILOT_INSTRUCTIONS="$GITHUB_DIR/copilot-instructions.md"
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
    
    # Download to temp file first
    TEMP_CLAUDE_MD="/tmp/claude_installer_$$.md"
    if download_file "$REPO_BASE_URL/claude.md" "$TEMP_CLAUDE_MD"; then
        if [ -f "$CLAUDE_DIR/claude.md" ]; then
            # File exists, append content
            print_info "  → Existing claude.md found, appending content..."
            backup_if_exists "$CLAUDE_DIR/claude.md"
            echo "" >> "$CLAUDE_DIR/claude.md"
            echo "" >> "$CLAUDE_DIR/claude.md"
            echo "<!-- Added by Ted's Claude Skills installer -->" >> "$CLAUDE_DIR/claude.md"
            cat "$TEMP_CLAUDE_MD" >> "$CLAUDE_DIR/claude.md"
            print_success "  → Content appended to existing claude.md"
        else
            # File doesn't exist, create it
            cp "$TEMP_CLAUDE_MD" "$CLAUDE_DIR/claude.md"
            print_success "claude.md created"
        fi
    else
        print_error "Failed to download claude.md"
        rm -f "$TEMP_CLAUDE_MD"
        exit 1
    fi
    
    # Setup GitHub Copilot instructions
    print_info "Setting up GitHub Copilot instructions..."
    
    if [ -d "$GITHUB_DIR" ]; then
        # .github folder exists
        print_success "  → .github folder found"
        
        if [ -f "$COPILOT_INSTRUCTIONS" ]; then
            # File exists, append content
            print_info "  → Existing copilot-instructions.md found, appending content..."
            echo "" >> "$COPILOT_INSTRUCTIONS"
            echo "" >> "$COPILOT_INSTRUCTIONS"
            echo "<!-- Added by Ted's Claude Skills installer -->" >> "$COPILOT_INSTRUCTIONS"
            cat "$TEMP_CLAUDE_MD" >> "$COPILOT_INSTRUCTIONS"
            print_success "  → Content appended to existing copilot-instructions.md"
        else
            # File doesn't exist, create it
            print_info "  → Creating new copilot-instructions.md..."
            cp "$TEMP_CLAUDE_MD" "$COPILOT_INSTRUCTIONS"
            print_success "  → copilot-instructions.md created"
        fi
    else
        # .github folder doesn't exist
        print_warning "  → .github folder not found"
        print_info "  → Skipping GitHub Copilot instructions setup"
        print_info "  → To enable: create .github folder and run installer again"
    fi
    
    # Clean up temp file
    rm -f "$TEMP_CLAUDE_MD"
    
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
    if [ -d "$GITHUB_DIR" ] && [ -f "$COPILOT_INSTRUCTIONS" ]; then
        echo "  • .github/copilot-instructions.md (for GitHub Copilot)"
    fi
    echo ""
    if [ -d "$GITHUB_DIR" ] && [ -f "$COPILOT_INSTRUCTIONS" ]; then
        print_info "GitHub Copilot will now read instructions from .github/copilot-instructions.md"
    else
        print_info "GitHub Copilot instructions not installed (.github folder not found)"
        print_info "To enable: mkdir .github && run installer again"
    fi
    echo ""
}

# Run main installation
main
