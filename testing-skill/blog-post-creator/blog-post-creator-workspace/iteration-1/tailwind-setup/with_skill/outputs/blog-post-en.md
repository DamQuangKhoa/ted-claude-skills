# Complete Guide to Setting Up Tailwind CSS in Next.js 15

> **For developers integrating Tailwind CSS into their Next.js 15 projects**

Starting a new Next.js 15 project and want to use Tailwind CSS for styling? Or struggling with a Tailwind configuration that won't work? This comprehensive guide walks you through the entire process of setting up Tailwind CSS in Next.js 15, from basic installation to best practices and common pitfalls to avoid.

## TL;DR

**Quick Reference:**

- Install: `tailwindcss`, `postcss`, `autoprefixer`
- Initialize config: `npx tailwindcss init -p`
- Configure `content` paths in `tailwind.config.js`
- Add directives to `globals.css`
- Dark mode: use `class` strategy
- Formatting: install `prettier-plugin-tailwindcss`
- **Critical gotcha**: Don't forget to add page paths to the `content` array!

---

## Part 1: Installing Dependencies

### 1.1 Install Required Packages

The first step is installing Tailwind CSS and its related dependencies:

```bash
npm install -D tailwindcss postcss autoprefixer
```

**Package breakdown:**

| Package        | Purpose                                                  |
| :------------- | :------------------------------------------------------- |
| `tailwindcss`  | Core Tailwind CSS framework                              |
| `postcss`      | CSS processor required by Tailwind                       |
| `autoprefixer` | Automatically adds vendor prefixes (-webkit, -moz, etc.) |

> **Note**: Use the `-D` flag (development dependency) because Tailwind is only needed during the build process, not in production runtime.

### 1.2 Initialize Configuration Files

After installation, run the init command to generate config files:

```bash
npx tailwindcss init -p
```

This command creates **two files**:

1. **`tailwind.config.js`** — Tailwind CSS configuration
2. **`postcss.config.js`** — PostCSS configuration (automatically set up correctly)

The `postcss.config.js` will look like this:

```javascript
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

---

## Part 2: Configuring Tailwind Config

### 2.1 Setup Content Paths

**This is the most critical step!** You need to tell Tailwind where to scan for class names.

Open the `tailwind.config.js` file and configure the `content` array:

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

**Content paths explained:**

| Path                                    | Purpose                      |
| :-------------------------------------- | :--------------------------- |
| `./pages/**/*.{js,ts,jsx,tsx,mdx}`      | For Pages Router             |
| `./components/**/*.{js,ts,jsx,tsx,mdx}` | For all components           |
| `./app/**/*.{js,ts,jsx,tsx,mdx}`        | For App Router (Next.js 13+) |

> **Critical**: Tailwind won't load styles for files not included in the `content` array! This is the #1 cause of "Tailwind classes not working" errors.

### 2.2 Choose Your Router Strategy

Next.js 15 supports both routing strategies:

**App Router (recommended):**

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

**Using both:**

```javascript
content: [
  "./pages/**/*.{js,ts,jsx,tsx,mdx}",
  "./app/**/*.{js,ts,jsx,tsx,mdx}",
  "./components/**/*.{js,ts,jsx,tsx,mdx}",
];
```

---

## Part 3: Adding Tailwind Directives

### 3.1 Configure Global CSS

Open your global CSS file (typically `app/globals.css` or `styles/globals.css`) and add the Tailwind directives:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

**Each directive explained:**

| Directive              | Function                                              |
| :--------------------- | :---------------------------------------------------- |
| `@tailwind base`       | Resets browser default CSS (normalize)                |
| `@tailwind components` | Component classes like `.btn`, `.card`                |
| `@tailwind utilities`  | Utility classes like `.flex`, `.pt-4`, `.text-center` |

> **Best practice**: Keep this order to ensure CSS cascade works correctly.

### 3.2 Import Global CSS

Ensure the `globals.css` file is imported in your layout/app component:

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

## Part 4: Dark Mode Configuration

### 4.1 Class Strategy vs Media Strategy

Tailwind supports two strategies for dark mode:

**Class Strategy (recommended):**

```javascript
// tailwind.config.js
module.exports = {
  darkMode: "class",
  // ... rest of config
};
```

With `class` strategy, dark mode activates when a `dark` class is present on a parent element:

```tsx
// Apply dark mode to entire app
<html className="dark">
  <body>{children}</body>
</html>

// Or toggle dynamically
<div className={isDark ? 'dark' : ''}>
  <p className="text-gray-900 dark:text-gray-100">
    This text changes color based on theme
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

With `media` strategy, dark mode automatically follows OS settings:

```tsx
<p className="text-gray-900 dark:text-gray-100">
  Automatically dark if OS is in dark mode
</p>
```

**Comparison:**

| Strategy | Pros                              | Cons                                |
| :------- | :-------------------------------- | :---------------------------------- |
| `class`  | Full control, can toggle manually | Must implement toggle logic         |
| `media`  | Automatic OS sync, no code needed | Can't override, users can't control |

> **Recommendation**: Use `class` strategy as it allows users to toggle dark mode independently of OS settings.

---

## Part 5: Code Formatting & Best Practices

### 5.1 Prettier Plugin for Auto-Sorting

Install the plugin to automatically sort Tailwind classes in the standard order:

```bash
npm install -D prettier prettier-plugin-tailwindcss
```

Create or update `.prettierrc`:

```json
{
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

**Before formatting:**

```tsx
<div className="pt-4 text-center mx-auto flex">
```

**After formatting:**

```tsx
<div className="mx-auto flex pt-4 text-center">
```

> This plugin sorts classes in logical order: layout → spacing → typography → effects, making code easier to read and consistent.

### 5.2 Best Practice: Use @apply Sparingly

Tailwind encourages using utility classes directly instead of `@apply`:

**❌ Avoid doing this:**

```css
.btn-primary {
  @apply px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600;
}
```

**✅ Do this instead:**

```tsx
<button className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">
  Click me
</button>
```

**When should you use @apply:**

- Component is reused many times with exactly the same styles
- Third-party components that can't accept className
- Styles are too complex, making JSX hard to read

**Valid example:**

```css
.wysiwyg-content h1 {
  @apply text-3xl font-bold mt-8 mb-4;
}

.wysiwyg-content p {
  @apply mb-4 leading-relaxed;
}
```

---

## Part 6: Common Gotchas & Troubleshooting

### 6.1 Error #1: Classes Not Working

**Symptom**: You write Tailwind classes but don't see styles applied.

**Cause**: 99% of cases are due to forgetting to add file paths to the `content` array in `tailwind.config.js`.

**Solution:**

```javascript
// ❌ WRONG - missing pages
module.exports = {
  content: ["./components/**/*.{js,ts,jsx,tsx,mdx}"],
  // ...
};

// ✅ CORRECT - complete paths
module.exports = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  // ...
};
```

### 6.2 Error #2: Dynamic Classes Don't Work

**Symptom**: String interpolation in class names doesn't work.

```tsx
// ❌ WRONG - Tailwind can't detect this
<div className={`text-${color}-500`}>

// ✅ CORRECT - Use complete class names
<div className={color === 'red' ? 'text-red-500' : 'text-blue-500'}>
```

**Explanation**: Tailwind's PurgeCSS scans static strings and can't analyze string interpolation. Always use complete class names.

### 6.3 Error #3: Forgot to Import globals.css

**Symptom**: No styles work at all.

**Solution**: Ensure you import `globals.css` in your root layout/app component (see Part 3.2).

### 6.4 Error #4: Wrong PostCSS Config

**Symptom**: Build errors related to PostCSS.

**Solution**: Ensure `postcss.config.js` has the correct format:

```javascript
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

---

## Part 7: Verification & Testing

### 7.1 Test That Tailwind Works

Create a simple component to test:

```tsx
// app/page.tsx or pages/index.tsx
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

Run the dev server:

```bash
npm run dev
```

Open your browser at `http://localhost:3000` and check the result.

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

## Summary and Key Takeaways

### Setup Completion Checklist

- [x] Install `tailwindcss`, `postcss`, `autoprefixer`
- [x] Run `npx tailwindcss init -p`
- [x] Configure `content` paths in `tailwind.config.js`
- [x] Add `@tailwind` directives to `globals.css`
- [x] Import `globals.css` in layout
- [x] Configure dark mode strategy
- [x] Install `prettier-plugin-tailwindcss`
- [x] Verify setup works

### Key Points to Remember

**1. Content Paths Are Most Important**

> No correct content paths = No Tailwind styles. This is the #1 cause of errors.

**2. Class Strategy > Media Strategy**

> Class strategy allows user control of dark mode, better than media strategy.

**3. Use @apply Sparingly**

> Prefer utility classes directly. Only use `@apply` for edge cases.

**4. Complete Class Names Only**

> Don't use string interpolation. Tailwind needs to detect complete class strings.

### What to Do Next

1. **Customize Theme** — Extend colors, fonts, spacing in `theme.extend`
2. **Add Plugins** — Explore Tailwind plugins like `@tailwindcss/forms`, `@tailwindcss/typography`
3. **Setup Components** — Create component library with Headless UI or Shadcn
4. **Optimize Production** — Configure PurgeCSS options for smallest file size

---

## Additional Resources

- [Tailwind CSS Official Docs](https://tailwindcss.com/docs/installation)
- [Next.js with Tailwind Guide](https://nextjs.org/docs/app/building-your-application/styling/tailwind-css)
- [Tailwind Dark Mode Docs](https://tailwindcss.com/docs/dark-mode)
- [Prettier Plugin GitHub](https://github.com/tailwindlabs/prettier-plugin-tailwindcss)

---

**Happy styling!** 🎨 If you run into issues, double-check your content paths and global CSS import — these are the source of 90% of problems.
