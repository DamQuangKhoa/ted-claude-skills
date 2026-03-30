# Setting Up Tailwind CSS in Next.js 15: A Complete Guide

Tailwind CSS has become the go-to utility-first CSS framework for modern web development, and integrating it with Next.js 15 is straightforward when you know the steps. In this guide, I'll walk you through the entire setup process, share some best practices, and help you avoid common pitfalls.

## Installation

First, let's install the necessary dependencies. You'll need three packages to get started:

```bash
npm install -D tailwindcss postcss autoprefixer
```

These packages work together to process your Tailwind styles:

- **tailwindcss**: The core framework
- **postcss**: Transforms your CSS with JavaScript plugins
- **autoprefixer**: Automatically adds vendor prefixes for browser compatibility

## Configuration

Next, initialize Tailwind CSS in your project:

```bash
npx tailwindcss init -p
```

This command creates two files:

- `tailwind.config.js` - Your Tailwind configuration
- `postcss.config.js` - PostCSS configuration

Now, open `tailwind.config.js` and configure the content paths. This is crucial - Tailwind needs to know where your components are to generate the appropriate CSS:

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

**Common Gotcha**: Forgetting to add your page paths to the content array is one of the most frequent mistakes. If your styles aren't showing up, double-check this configuration first!

## Adding Tailwind Directives

Add the Tailwind directives to your CSS file. If you're using the app router, this will be `app/globals.css`. For the pages router, it's typically `styles/globals.css`:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

These directives inject Tailwind's base styles, component classes, and utility classes into your CSS.

## Router Compatibility

Good news! Tailwind CSS works seamlessly with both Next.js routing approaches:

- **App Router** (Next.js 13+): The modern, recommended approach
- **Pages Router**: The traditional routing system

The setup process is identical for both - just ensure your content paths in `tailwind.config.js` match your chosen router structure.

## Dark Mode Setup

Tailwind offers two dark mode strategies. I recommend using the `class` strategy over `media`:

```js
// tailwind.config.js
module.exports = {
  darkMode: "class", // Instead of 'media'
  // ... rest of config
};
```

The `class` strategy gives you programmatic control over dark mode, making it easier to implement user preferences and toggle functionality. With the `media` strategy, dark mode is controlled by the user's system preferences, which offers less flexibility.

## Code Formatting

Install the Prettier plugin for Tailwind to automatically sort your utility classes in a consistent order:

```bash
npm install -D prettier prettier-plugin-tailwindcss
```

Create or update `.prettierrc`:

```json
{
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

This ensures your class names are always organized logically, improving code readability and reducing merge conflicts.

## Best Practices

**Use @apply Sparingly**: While Tailwind's `@apply` directive lets you extract repeated utility patterns into custom CSS classes, use it sparingly. The power of Tailwind comes from its utility-first approach. If you find yourself using `@apply` frequently, you might be working against the framework's philosophy.

Instead, prefer:

- Component extraction at the JavaScript/JSX level
- Direct utility classes in your markup
- Composition over custom CSS

## Verification

To verify everything is working, create a test page with some Tailwind classes:

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

If you see styled content, congratulations! You've successfully set up Tailwind CSS in your Next.js 15 project.

## Conclusion

Setting up Tailwind CSS in Next.js 15 is a straightforward process once you know the steps. Remember to:

1. Install the required packages
2. Configure your content paths correctly
3. Add the Tailwind directives to your CSS
4. Choose the `class` strategy for dark mode
5. Use prettier-plugin-tailwindcss for consistent formatting
6. Embrace utility classes over `@apply`

Happy styling! 🎨
