# Ted's Claude Skills Collection

A collection of skills and customizations for Claude AI in VS Code.

## 📦 Quick Installation

Run the following command to automatically install:

```bash
curl -fsSL https://raw.githubusercontent.com/DamQuangKhoa/ted-claude-skills/main/install.sh | bash
```

## 📋 Contents

### Claude Configuration

- **claude.md**: Main configuration file with context management guidelines, sub-agents usage, and best practices

### Skills

1. **skill-creator**: Skill for creating, modifying, and evaluating new skills
   - Create skills from scratch
   - Edit existing skills
   - Run evals and benchmarks
   - Optimize descriptions

2. **weekly-report**: Skill for creating weekly reports

## 🎯 Usage

After installation, files will be located at:

- `~/.claude/claude.md` - Main configuration
- `~/.claude/skills/skill-creator/` - Skill creator
- `~/.claude/skills/weekly-report/` - Weekly report skill

VS Code will automatically load these configurations on next restart.

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
    ├── skill-creator/
    │   ├── SKILL.md
    │   ├── LICENSE.txt
    │   ├── agents/
    │   ├── assets/
    │   ├── eval-viewer/
    │   ├── references/
    │   └── scripts/
    └── weekly-report/
        └── SKILL.md
```

## 📄 License

MIT License - see LICENSE file for details.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

## 👤 Author

**Ted**

---

Made with ❤️ for Claude AI
