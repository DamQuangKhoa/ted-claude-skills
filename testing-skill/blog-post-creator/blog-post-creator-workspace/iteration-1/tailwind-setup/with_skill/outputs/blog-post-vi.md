# Hướng Dẫn Thiết Lập Tailwind CSS trong Next.js 15

> **Dành cho developers muốn tích hợp Tailwind CSS vào dự án Next.js 15 của mình**

Bạn đang bắt đầu một dự án Next.js 15 mới và muốn sử dụng Tailwind CSS cho styling? Hay bạn đang gặp khó khăn khi cấu hình Tailwind không hoạt động đúng cách? Hướng dẫn này sẽ dẫn bạn qua toàn bộ quá trình setup Tailwind CSS trong Next.js 15, từ cài đặt cơ bản đến các best practices và những lỗi thường gặp cần tránh.

## TL;DR

**Quick Reference:**

- Cài đặt: `tailwindcss`, `postcss`, `autoprefixer`
- Init config: `npx tailwindcss init -p`
- Cấu hình `content` paths trong `tailwind.config.js`
- Thêm directives vào `globals.css`
- Dark mode: dùng `class` strategy
- Formatting: cài `prettier-plugin-tailwindcss`
- **Lưu ý quan trọng**: Nhớ thêm đường dẫn pages vào `content` array!

---

## Phần 1: Cài Đặt Dependencies

### 1.1 Cài Đặt Packages Cần Thiết

Bước đầu tiên là cài đặt Tailwind CSS và các dependencies liên quan:

```bash
npm install -D tailwindcss postcss autoprefixer
```

**Giải thích các packages:**

| Package        | Vai trò                                            |
| :------------- | :------------------------------------------------- |
| `tailwindcss`  | Core framework của Tailwind CSS                    |
| `postcss`      | CSS processor cần thiết cho Tailwind               |
| `autoprefixer` | Tự động thêm vendor prefixes (-webkit, -moz, etc.) |

> **Lưu ý**: Dùng flag `-D` (development dependency) vì Tailwind chỉ cần trong quá trình build, không cần trong production runtime.

### 1.2 Khởi Tạo Configuration Files

Sau khi cài đặt xong, chạy lệnh init để tạo các file config:

```bash
npx tailwindcss init -p
```

Lệnh này sẽ tạo ra **hai files**:

1. **`tailwind.config.js`** — Cấu hình Tailwind CSS
2. **`postcss.config.js`** — Cấu hình PostCSS (tự động được setup đúng)

File `postcss.config.js` sẽ trông như thế này:

```javascript
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

---

## Phần 2: Cấu Hình Tailwind Config

### 2.1 Setup Content Paths

**Đây là bước quan trọng nhất!** Bạn cần chỉ định cho Tailwind biết nơi nào cần scan để tìm class names.

Mở file `tailwind.config.js` và cấu hình `content` array:

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};
```

**Giải thích content paths:**

| Path                                    | Ý nghĩa                      |
| :-------------------------------------- | :--------------------------- |
| `./pages/**/*.{js,ts,jsx,tsx,mdx}`      | Cho Pages Router             |
| `./components/**/*.{js,ts,jsx,tsx,mdx}` | Cho tất cả components        |
| `./app/**/*.{js,ts,jsx,tsx,mdx}`        | Cho App Router (Next.js 13+) |

> **Quan trọng**: Tailwind sẽ không load styles cho files không nằm trong `content` array! Đây là nguyên nhân #1 gây ra lỗi "Tailwind classes không hoạt động".

### 2.2 Chọn Router Strategy

Next.js 15 hỗ trợ cả hai routing strategies:

**App Router (khuyến nghị):**

```javascript
content: [
  "./app/**/*.{js,ts,jsx,tsx,mdx}",
  "./components/**/*.{js,ts,jsx,tsx,mdx}",
];
```

**Pages Router (legacy):**

```javascript
content: [
  "./pages/**/*.{js,ts,jsx,tsx,mdx}",
  "./components/**/*.{js,ts,jsx,tsx,mdx}",
];
```

**Dùng cả hai:**

```javascript
content: [
  "./pages/**/*.{js,ts,jsx,tsx,mdx}",
  "./app/**/*.{js,ts,jsx,tsx,mdx}",
  "./components/**/*.{js,ts,jsx,tsx,mdx}",
];
```

---

## Phần 3: Thêm Tailwind Directives

### 3.1 Cấu Hình Global CSS

Mở file CSS global của bạn (thường là `app/globals.css` hoặc `styles/globals.css`) và thêm các Tailwind directives:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

**Giải thích từng directive:**

| Directive              | Chức năng                                            |
| :--------------------- | :--------------------------------------------------- |
| `@tailwind base`       | Reset CSS mặc định của browser (normalize)           |
| `@tailwind components` | Component classes như `.btn`, `.card`                |
| `@tailwind utilities`  | Utility classes như `.flex`, `.pt-4`, `.text-center` |

> **Best practice**: Giữ thứ tự này để đảm bảo CSS cascade hoạt động đúng.

### 3.2 Import Global CSS

Đảm bảo file `globals.css` được import trong layout/app component:

**App Router (`app/layout.tsx`):**

```typescript
import './globals.css'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
```

**Pages Router (`pages/_app.tsx`):**

```typescript
import '../styles/globals.css'
import type { AppProps } from 'next/app'

export default function App({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />
}
```

---

## Phần 4: Dark Mode Configuration

### 4.1 Class Strategy vs Media Strategy

Tailwind hỗ trợ hai strategies cho dark mode:

**Class Strategy (khuyến nghị):**

```javascript
// tailwind.config.js
module.exports = {
  darkMode: "class",
  // ... rest of config
};
```

Với `class` strategy, dark mode được kích hoạt khi có class `dark` trên element cha:

```tsx
// Áp dụng dark mode cho toàn app
<html className="dark">
  <body>{children}</body>
</html>

// Hoặc toggle động
<div className={isDark ? 'dark' : ''}>
  <p className="text-gray-900 dark:text-gray-100">
    Text này sẽ đổi màu theo theme
  </p>
</div>
```

**Media Strategy:**

```javascript
// tailwind.config.js
module.exports = {
  darkMode: "media",
  // ... rest of config
};
```

Với `media` strategy, dark mode tự động theo OS setting:

```tsx
<p className="text-gray-900 dark:text-gray-100">
  Tự động dark nếu OS đang ở dark mode
</p>
```

**So sánh:**

| Strategy | Ưu điểm                            | Nhược điểm                                  |
| :------- | :--------------------------------- | :------------------------------------------ |
| `class`  | Kiểm soát hoàn toàn, có thể toggle | Phải implement toggle logic                 |
| `media`  | Tự động theo OS, không cần code    | Không thể override, user không control được |

> **Khuyến nghị**: Dùng `class` strategy vì nó cho phép user toggle dark mode độc lập với OS setting.

---

## Phần 5: Code Formatting & Best Practices

### 5.1 Prettier Plugin cho Auto-Sorting

Cài đặt plugin để tự động sắp xếp Tailwind classes theo thứ tự chuẩn:

```bash
npm install -D prettier prettier-plugin-tailwindcss
```

Tạo hoặc cập nhật `.prettierrc`:

```json
{
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

**Trước khi format:**

```tsx
<div className="pt-4 text-center mx-auto flex">
```

**Sau khi format:**

```tsx
<div className="mx-auto flex pt-4 text-center">
```

> Plugin này sắp xếp classes theo thứ tự logic: layout → spacing → typography → effects, giúp code dễ đọc và consistent.

### 5.2 Best Practice: Sử Dụng @apply Cẩn Thận

Tailwind khuyến khích dùng utility classes trực tiếp thay vì `@apply`:

**❌ Tránh làm như này:**

```css
.btn-primary {
  @apply px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600;
}
```

**✅ Nên làm thế này:**

```tsx
<button className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
  Click me
</button>
```

**Khi nào nên dùng @apply:**

- Component được reuse nhiều lần với chính xác cùng styles
- Third-party components không thể truyền className
- Styles phức tạp quá, làm JSX khó đọc

**Ví dụ hợp lý:**

```css
.wysiwyg-content h1 {
  @apply text-3xl font-bold mt-8 mb-4;
}

.wysiwyg-content p {
  @apply mb-4 leading-relaxed;
}
```

---

## Phần 6: Common Gotchas & Troubleshooting

### 6.1 Lỗi #1: Classes Không Hoạt Động

**Triệu chứng**: Bạn viết Tailwind classes nhưng không thấy styles áp dụng.

**Nguyên nhân**: 99% trường hợp là do quên thêm file paths vào `content` array trong `tailwind.config.js`.

**Giải pháp:**

```javascript
// ❌ SAI - thiếu pages
module.exports = {
  content: ["./components/**/*.{js,ts,jsx,tsx,mdx}"],
  // ...
};

// ✅ ĐÚNG - đầy đủ paths
module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  // ...
};
```

### 6.2 Lỗi #2: Dynamic Classes Không Work

**Triệu chứng**: String interpolation trong class names không hoạt động.

```tsx
// ❌ SAI - Tailwind không thể detect
<div className={`text-${color}-500`}>

// ✅ ĐÚNG - Dùng complete class names
<div className={color === 'red' ? 'text-red-500' : 'text-blue-500'}>
```

**Giải thích**: Tailwind's PurgeCSS scan static strings, không thể phân tích string interpolation. Luôn dùng complete class names.

### 6.3 Lỗi #3: Quên Import globals.css

**Triệu chứng**: Không có styles nào hoạt động cả.

**Giải pháp**: Đảm bảo import `globals.css` trong root layout/app component (xem Phần 3.2).

### 6.4 Lỗi #4: PostCSS Config Sai

**Triệu chứng**: Build bị lỗi về PostCSS.

**Giải pháp**: Đảm bảo `postcss.config.js` có đúng format:

```javascript
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

---

## Phần 7: Verification & Testing

### 7.1 Test Tailwind Hoạt Động

Tạo một component đơn giản để test:

```tsx
// app/page.tsx hoặc pages/index.tsx
export default function Home() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-r from-blue-500 to-purple-600">
      <div className="bg-white p-8 rounded-lg shadow-2xl">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">
          Tailwind CSS is Working! 🎉
        </h1>
        <p className="text-gray-600">
          If you see styled text, your setup is correct.
        </p>
      </div>
    </div>
  );
}
```

Chạy dev server:

```bash
npm run dev
```

Mở trình duyệt ở `http://localhost:3000` và xem kết quả.

### 7.2 Test Dark Mode

```tsx
export default function Home() {
  return (
    <html className="dark">
      <body className="bg-white dark:bg-gray-900">
        <div className="p-8">
          <h1 className="text-gray-900 dark:text-white">Dark mode test</h1>
        </div>
      </body>
    </html>
  );
}
```

---

## Tổng Kết và Key Takeaways

### Checklist Hoàn Thành Setup

- [x] Cài đặt `tailwindcss`, `postcss`, `autoprefixer`
- [x] Chạy `npx tailwindcss init -p`
- [x] Cấu hình `content` paths trong `tailwind.config.js`
- [x] Thêm `@tailwind` directives vào `globals.css`
- [x] Import `globals.css` trong layout
- [x] Cấu hình dark mode strategy
- [x] Cài đặt `prettier-plugin-tailwindcss`
- [x] Verify setup hoạt động

### Key Points Cần Nhớ

**1. Content Paths Là Quan Trọng Nhất**

> Không có đúng content paths = Không có Tailwind styles. Đây là nguyên nhân #1 gây lỗi.

**2. Class Strategy > Media Strategy**

> Class strategy cho phép user control dark mode, tốt hơn media strategy.

**3. Ít Dùng @apply**

> Ưu tiên utility classes trực tiếp. Chỉ dùng `@apply` cho edge cases.

**4. Complete Class Names Only**

> Không dùng string interpolation. Tailwind cần detect complete class strings.

### Những Điều Nên Làm Tiếp Theo

1. **Customize Theme** — Extend colors, fonts, spacing trong `theme.extend`
2. **Add Plugins** — Explore Tailwind plugins như `@tailwindcss/forms`, `@tailwindcss/typography`
3. **Setup Components** — Tạo component library với Headless UI hoặc Shadcn
4. **Optimize Production** — Configure PurgeCSS options cho file size nhỏ nhất

---

## Tài Liệu Tham Khảo

- [Tailwind CSS Official Docs](https://tailwindcss.com/docs/installation)
- [Next.js with Tailwind Guide](https://nextjs.org/docs/app/building-your-application/styling/tailwind-css)
- [Tailwind Dark Mode Docs](https://tailwindcss.com/docs/dark-mode)
- [Prettier Plugin GitHub](https://github.com/tailwindlabs/prettier-plugin-tailwindcss)

---

**Happy styling!** 🎨 Nếu bạn gặp vấn đề, hãy double-check lại content paths và global CSS import — đó là nguồn gốc của 90% các vấn đề.
