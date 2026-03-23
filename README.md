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

- `./.claude/claude.md` - Configuration reference
- `./.claude/skills/skill-creator/` - Skill creator
- `./.github/copilot-instructions.md` - GitHub Copilot instructions (only if `.github/` folder exists)

**How it works:**

- `.claude/` folder is always created with skills
- **For `.claude/claude.md`:**
  - If doesn't exist → creates it with fresh content
  - If already exists → appends fresh content to it (with backup)
- **For `.github/copilot-instructions.md`** (only if `.github/` folder exists):
  - If doesn't exist → creates it with fresh content
  - If already exists → appends fresh content to it
- GitHub Copilot in VS Code will automatically read instructions from `.github/copilot-instructions.md`

**Note**: Run the install command from your project root directory where you want to add Claude skills.

### 📂 Adding .claude to .gitignore

The `.claude` folder contains configurations and typically should not be committed to your repository. However, `.github/copilot-instructions.md` should be committed so your team can benefit from the instructions.

Add this to your project's `.gitignore`:

```
# Claude AI configuration (local reference)
.claude/

# Keep .github/copilot-instructions.md tracked for the team
```

## 🔄 Updates

To update to the latest version, simply run the install command again:

```bash
curl -fsSL https://raw.githubusercontent.com/DamQuangKhoa/ted-claude-skills/main/install.sh | bash
```

The script will automatically backup old files before updating.

## 📝 Directory Structure

**In your project after installation:**

```
your-project/
├── .claude/                          # Always created
│   ├── claude.md
│   └── skills/
│       └── skill-creator/
│           ├── SKILL.md
│           ├── LICENSE.txt
│           ├── agents/
│           ├── assets/
│           ├── eval-viewer/
│           ├── references/
│           └── scripts/
└── .github/                          # Only if this folder already exists
    └── copilot-instructions.md       # Created or appended
```

**In this repository:**

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
