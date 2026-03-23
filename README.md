# Ted's Claude Skills Collection

Bộ sưu tập các skills và customization cho Claude AI trong VS Code.

## 📦 Cài đặt nhanh

Chạy lệnh sau để tự động cài đặt:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install.sh | bash
```

## 📋 Nội dung

### Claude Configuration
- **claude.md**: File cấu hình chính với hướng dẫn context management, sub-agents, và best practices

### Skills

1. **skill-creator**: Skill để tạo, sửa đổi và đánh giá các skills mới
   - Tạo skills từ đầu
   - Chỉnh sửa skills hiện có  
   - Chạy evals và benchmarks
   - Tối ưu hóa descriptions

2. **weekly-report**: Skill để tạo báo cáo tuần

## 🚀 Hướng dẫn publish lên GitHub

### Bước 1: Tạo GitHub Repository

```bash
# Tại thư mục ted-skill, khởi tạo git repository
cd /Users/ted/learn/ted-skill
git init
```

### Bước 2: Tạo repository trên GitHub
1. Truy cập https://github.com/new
2. Đặt tên repository (ví dụ: `ted-claude-skills`)
3. Để public để có thể dùng raw URL
4. Không tạo README (vì đã có rồi)

### Bước 3: Push code lên GitHub

```bash
# Thêm các files
git add .
git commit -m "Initial commit: Claude skills collection"

# Kết nối với GitHub repository (thay YOUR_USERNAME và YOUR_REPO)
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git branch -M main
git push -u origin main
```

### Bước 4: Cập nhật URLs trong install.sh

Sau khi push lên GitHub, cập nhật 2 chỗ trong file `install.sh`:

1. Line 2: Hướng dẫn sử dụng
```bash
# Usage: curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install.sh | bash -s [profile]
```

2. Line 16: Base URL
```bash
REPO_BASE_URL="https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main"
```

Thay `YOUR_USERNAME` bằng username GitHub của bạn và `YOUR_REPO` bằng tên repository.

### Bước 5: Test installation

Sau khi cập nhật, test bằng cách chạy:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install.sh | bash
```

## 🎯 Cách sử dụng sau khi cài đặt

Sau khi cài đặt, các files sẽ được đặt tại:
- `~/.claude/claude.md` - Main configuration
- `~/.claude/skills/skill-creator/` - Skill creator
- `~/.claude/skills/weekly-report/` - Weekly report skill

VS Code sẽ tự động load các configurations này khi khởi động lại.

## 🔄 Cập nhật

Để cập nhật lên phiên bản mới nhất, chỉ cần chạy lại lệnh install:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/install.sh | bash
```

Script sẽ tự động backup các file cũ trước khi cập nhật.

## 📝 Cấu trúc thư mục

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

MIT License - xem file LICENSE để biết thêm chi tiết.

## 🤝 Contributing

Contributions, issues và feature requests đều được chào đón!

## 👤 Author

**Ted**

---

Made with ❤️ for Claude AI
