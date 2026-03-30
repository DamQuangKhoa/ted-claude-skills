# Hướng Dẫn Cài Đặt Tailwind CSS trong Next.js 15

Tailwind CSS đã trở thành framework CSS utility-first hàng đầu cho phát triển web hiện đại, và việc tích hợp nó với Next.js 15 khá đơn giản khi bạn biết các bước cần thiết. Trong hướng dẫn này, tôi sẽ đưa bạn qua toàn bộ quá trình thiết lập, chia sẻ một số best practices, và giúp bạn tránh những lỗi phổ biến.

## Cài Đặt

Đầu tiên, hãy cài đặt các dependencies cần thiết. Bạn sẽ cần ba packages để bắt đầu:

```bash
npm install -D tailwindcss postcss autoprefixer
```

Các packages này làm việc cùng nhau để xử lý Tailwind styles của bạn:

- **tailwindcss**: Framework cốt lõi
- **postcss**: Biến đổi CSS của bạn bằng JavaScript plugins
- **autoprefixer**: Tự động thêm vendor prefixes để tương thích trình duyệt

## Cấu Hình

Tiếp theo, khởi tạo Tailwind CSS trong project của bạn:

```bash
npx tailwindcss init -p
```

Lệnh này tạo ra hai files:

- `tailwind.config.js` - Cấu hình Tailwind của bạn
- `postcss.config.js` - Cấu hình PostCSS

Bây giờ, mở `tailwind.config.js` và cấu hình các đường dẫn content. Điều này rất quan trọng - Tailwind cần biết các components của bạn ở đâu để tạo ra CSS phù hợp:

```js
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

**Lỗi Thường Gặp**: Quên thêm đường dẫn pages của bạn vào mảng content là một trong những sai lầm phổ biến nhất. Nếu styles của bạn không hiển thị, hãy kiểm tra lại cấu hình này trước!

## Thêm Tailwind Directives

Thêm các Tailwind directives vào file CSS của bạn. Nếu bạn đang sử dụng app router, đây sẽ là `app/globals.css`. Đối với pages router, thường là `styles/globals.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

Các directives này inject base styles, component classes, và utility classes của Tailwind vào CSS của bạn.

## Tương Thích Router

Tin tốt! Tailwind CSS hoạt động mượt mà với cả hai cách routing của Next.js:

- **App Router** (Next.js 13+): Cách tiếp cận hiện đại, được khuyến nghị
- **Pages Router**: Hệ thống routing truyền thống

Quá trình thiết lập giống hệt nhau cho cả hai - chỉ cần đảm bảo các đường dẫn content trong `tailwind.config.js` khớp với cấu trúc router bạn chọn.

## Thiết Lập Dark Mode

Tailwind cung cấp hai chiến lược dark mode. Tôi khuyên dùng chiến lược `class` thay vì `media`:

```js
// tailwind.config.js
module.exports = {
  darkMode: "class", // Thay vì 'media'
  // ... phần còn lại của config
};
```

Chiến lược `class` cho bạn quyền kiểm soát dark mode theo chương trình, giúp dễ dàng triển khai tùy chọn người dùng và chức năng toggle. Với chiến lược `media`, dark mode được điều khiển bởi tùy chọn hệ thống của người dùng, có ít linh hoạt hơn.

## Định Dạng Code

Cài đặt Prettier plugin cho Tailwind để tự động sắp xếp các utility classes theo thứ tự nhất quán:

```bash
npm install -D prettier prettier-plugin-tailwindcss
```

Tạo hoặc cập nhật `.prettierrc`:

```json
{
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

Điều này đảm bảo tên các classes của bạn luôn được tổ chức logic, cải thiện khả năng đọc code và giảm conflicts khi merge.

## Best Practices

**Sử Dụng @apply Một Cách Tiết Kiệm**: Mặc dù directive `@apply` của Tailwind cho phép bạn trích xuất các patterns utility lặp lại thành custom CSS classes, hãy sử dụng nó một cách tiết kiệm. Sức mạnh của Tailwind đến từ cách tiếp cận utility-first. Nếu bạn thấy mình đang sử dụng `@apply` thường xuyên, có thể bạn đang làm việc ngược lại với triết lý của framework.

Thay vào đó, ưu tiên:

- Component extraction ở cấp độ JavaScript/JSX
- Utility classes trực tiếp trong markup
- Composition thay vì custom CSS

## Kiểm Tra

Để xác minh mọi thứ đang hoạt động, tạo một test page với một số Tailwind classes:

```jsx
export default function Home() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-r from-blue-500 to-purple-600">
      <h1 className="text-4xl font-bold text-white">
        Tailwind CSS + Next.js 15
      </h1>
    </div>
  );
}
```

Nếu bạn thấy nội dung được styled, chúc mừng! Bạn đã thiết lập thành công Tailwind CSS trong project Next.js 15 của mình.

## Kết Luận

Thiết lập Tailwind CSS trong Next.js 15 là một quá trình đơn giản khi bạn biết các bước. Hãy nhớ:

1. Cài đặt các packages cần thiết
2. Cấu hình đường dẫn content một cách chính xác
3. Thêm Tailwind directives vào CSS của bạn
4. Chọn chiến lược `class` cho dark mode
5. Sử dụng prettier-plugin-tailwindcss để định dạng nhất quán
6. Ưu tiên utility classes thay vì `@apply`

Chúc bạn styling vui vẻ! 🎨
