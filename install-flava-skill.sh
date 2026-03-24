#!/bin/bash

# Flava Skills Installer
# Installs claude.md, skill-creator-v2, and flava-specific skills
# Usage: curl -fsSL https://raw.githubusercontent.com/DamQuangKhoa/ted-claude-skills/main/install-flava-skill.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
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
    echo "║     Flava Skills Installer            ║"
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
            echo "<!-- Added by Flava Skills installer -->" >> "$CLAUDE_DIR/claude.md"
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
            echo "<!-- Added by Flava Skills installer -->" >> "$COPILOT_INSTRUCTIONS"
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
    
    # Install skills
    print_info "Installing skills..."
    echo ""
    
    # Skill 1: skill-creator-v2
    print_info "  Installing skill-creator-v2..."
    mkdir -p "$SKILLS_DIR/skill-creator-v2"
    mkdir -p "$SKILLS_DIR/skill-creator-v2/agents"
    mkdir -p "$SKILLS_DIR/skill-creator-v2/assets"
    mkdir -p "$SKILLS_DIR/skill-creator-v2/eval-viewer"
    mkdir -p "$SKILLS_DIR/skill-creator-v2/references"
    mkdir -p "$SKILLS_DIR/skill-creator-v2/scripts"
    
    # Download skill-creator files
    local skill_creator_files=(
        "skills/skill-creator-v2/SKILL.md"
        "skills/skill-creator-v2/LICENSE.txt"
        "skills/skill-creator-v2/agents/analyzer.md"
        "skills/skill-creator-v2/agents/comparator.md"
        "skills/skill-creator-v2/agents/grader.md"
        "skills/skill-creator-v2/assets/eval_review.html"
        "skills/skill-creator-v2/eval-viewer/generate_review.py"
        "skills/skill-creator-v2/eval-viewer/viewer.html"
        "skills/skill-creator-v2/references/schemas.md"
        "skills/skill-creator-v2/scripts/__init__.py"
        "skills/skill-creator-v2/scripts/aggregate_benchmark.py"
        "skills/skill-creator-v2/scripts/generate_report.py"
        "skills/skill-creator-v2/scripts/improve_description.py"
        "skills/skill-creator-v2/scripts/package_skill.py"
        "skills/skill-creator-v2/scripts/quick_validate.py"
        "skills/skill-creator-v2/scripts/run_eval.py"
        "skills/skill-creator-v2/scripts/run_loop.py"
        "skills/skill-creator-v2/scripts/utils.py"
    )
    
    for file in "${skill_creator_files[@]}"; do
        dest="$CLAUDE_DIR/$file"
        if download_file "$REPO_BASE_URL/$file" "$dest"; then
            print_success "    ✓ $(basename $file)"
        else
            print_warning "    ⚠ Failed to download $(basename $file)"
        fi
    done
    
    echo ""
    
    # Skill 2: flava-commit-skill
    print_info "  Installing flava-commit-skill..."
    mkdir -p "$SKILLS_DIR/flava-commit-skill"
    mkdir -p "$SKILLS_DIR/flava-commit-skill/evals"
    
    local flava_commit_files=(
        "testing-skill/flava/flava-commit-skill/SKILL.md"
        "testing-skill/flava/flava-commit-skill/evals/evals.json"
    )
    
    for file in "${flava_commit_files[@]}"; do
        dest="$SKILLS_DIR/flava-commit-skill/$(basename $file)"
        if [[ "$file" == *"/evals/"* ]]; then
            dest="$SKILLS_DIR/flava-commit-skill/evals/$(basename $file)"
        fi
        if download_file "$REPO_BASE_URL/$file" "$dest"; then
            print_success "    ✓ $(basename $file)"
        else
            print_warning "    ⚠ Failed to download $(basename $file)"
        fi
    done
    
    # Skill 3: flava-jira-check
    print_info "  Installing flava-jira-check..."
    mkdir -p "$SKILLS_DIR/flava-jira-check"
    
    if download_file "$REPO_BASE_URL/testing-skill/flava/flava-jira-check/SKILL.md" "$SKILLS_DIR/flava-jira-check/SKILL.md"; then
        print_success "    ✓ SKILL.md"
    else
        print_warning "    ⚠ Failed to download SKILL.md"
    fi
    
    # Skill 4: flava-jira-create-sre-ticket
    print_info "  Installing flava-jira-create-sre-ticket..."
    mkdir -p "$SKILLS_DIR/flava-jira-create-sre-ticket"
    mkdir -p "$SKILLS_DIR/flava-jira-create-sre-ticket/evals"
    
    local flava_sre_files=(
        "testing-skill/flava/flava-jira-create-sre-ticket/SKILL.md"
        "testing-skill/flava/flava-jira-create-sre-ticket/evals/evals.json"
    )
    
    for file in "${flava_sre_files[@]}"; do
        dest="$SKILLS_DIR/flava-jira-create-sre-ticket/$(basename $file)"
        if [[ "$file" == *"/evals/"* ]]; then
            dest="$SKILLS_DIR/flava-jira-create-sre-ticket/evals/$(basename $file)"
        fi
        if download_file "$REPO_BASE_URL/$file" "$dest"; then
            print_success "    ✓ $(basename $file)"
        else
            print_warning "    ⚠ Failed to download $(basename $file)"
        fi
    done
    
    # Skill 5: flava-pr-skill
    print_info "  Installing flava-pr-skill..."
    mkdir -p "$SKILLS_DIR/flava-pr-skill"
    mkdir -p "$SKILLS_DIR/flava-pr-skill/evals"
    
    local flava_pr_files=(
        "testing-skill/flava/flava-pr-skill/SKILL.md"
        "testing-skill/flava/flava-pr-skill/evals/evals.json"
    )
    
    for file in "${flava_pr_files[@]}"; do
        dest="$SKILLS_DIR/flava-pr-skill/$(basename $file)"
        if [[ "$file" == *"/evals/"* ]]; then
            dest="$SKILLS_DIR/flava-pr-skill/evals/$(basename $file)"
        fi
        if download_file "$REPO_BASE_URL/$file" "$dest"; then
            print_success "    ✓ $(basename $file)"
        else
            print_warning "    ⚠ Failed to download $(basename $file)"
        fi
    done
    
    echo ""
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
    print_success "Flava configuration installed to: $CLAUDE_DIR"
    echo ""
    echo "Installed components:"
    echo "  • .claude/claude.md configuration"
    echo "  • .claude/skills/skill-creator-v2/"
    echo "  • .claude/skills/flava-commit-skill/"
    echo "  • .claude/skills/flava-jira-check/"
    echo "  • .claude/skills/flava-jira-create-sre-ticket/"
    echo "  • .claude/skills/flava-pr-skill/"
    if [ -d "$GITHUB_DIR" ] && [ -f "$COPILOT_INSTRUCTIONS" ]; then
        echo "  • .github/copilot-instructions.md (for GitHub Copilot)"
    fi
    echo ""
    echo "Next steps:"
    echo "  1. Restart your editor/IDE to load the new skills"
    echo "  2. Use the skills in Claude or GitHub Copilot"
    echo ""
    echo "For usage instructions, see:"
    echo "  https://github.com/DamQuangKhoa/ted-claude-skills"
    echo ""
}

# Run main installation
main
