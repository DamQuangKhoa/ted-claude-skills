# Ted's Claude Skills Collection

A collection of skills and customizations for Claude AI in VS Code.

## 📦 Quick Installation

Navigate to your project directory and run:

```bash
cd /path/to/your/project
curl -fsSL https://raw.githubusercontent.com/DamQuangKhoa/ted-claude-skills/main/install.sh | bash
```

**Example:**
```bash
cd /Users/ted/company/project/LYCC/console/flava-console/apps/product-lb
curl -fsSL https://raw.githubusercontent.com/DamQuangKhoa/ted-claude-skills/main/install.sh | bash
```

This will create a `.claude` folder in your current directory with all the configurations and skills.

## 📋 Contents

### Claude Configuration

- **claude.md**: Main configuration file with context management guidelines, sub-agents usage, and best practices

### Skills

1. **skill-creator**: Skill for creating, modifying, and evaluating new skills
   - Create skills from scratch
   - Edit existing skills
   - Run evals and benchmarks
   - Optimize descriptions

## 🎯 Usage

After installation, files will be created in your current directory:

- `./.claude/claude.md` - Main configuration
- `./.claude/skills/skill-creator/` - Skill creator

VS Code will automatically detect the `.claude` folder in your workspace.

**Note**: Run the install command from your project root directory where you want to add Claude skills.

### 📂 Adding .claude to .gitignore

The `.claude` folder contains project-specific configurations and typically should not be committed to your repository. Add this to your project's `.gitignore`:

```
# Claude AI configuration
.claude/
```

## 🔄 Updates

To update to the latest version, simply run the install command again:

```bash
curl -fsSL https://raw.githubusercontent.com/DamQuangKhoa/ted-claude-skills/main/install.sh | bash
```

The script will automatically backup old files before updating.

## 📝 Directory Structure

```
.
├── README.md
├── claude.md
├── install.sh
└── skills/
    └── skill-creator/
        ├── SKILL.md
        ├── LICENSE.txt
        ├── agents/
        ├── assets/
        ├── eval-viewer/
        ├── references/
        └── scripts/
```

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

## 👤 Author

**Ted**

---

Made with ❤️ for Claude AI
