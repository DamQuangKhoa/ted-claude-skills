---
name: blog-post-creator
description: Transform raw technical content (notes, ideas, outlines) into polished, engaging blog posts in both Vietnamese and English. Use when the user has technical content, educational material, developer guides, or concept explanations they want to turn into shareable blog posts. Automatically selects the best writing style (guide/tutorial vs. concept explanation) based on content structure. This skill excels at creating content for technical blogs, documentation sites, developer communities, or educational platforms. Always invoke this skill when users mention "blog post", "article", "write up", "share", "publish content", or have raw notes they want to transform into readable posts.
---

# Blog Post Creator

Transform raw technical content into polished, engaging blog posts with proper structure, examples, and formatting.

## Overview

This skill takes unstructured technical content (notes, bullet points, ideas, outlines) and transforms it into publication-ready blog posts in both **Vietnamese** and **English**. It intelligently selects between two proven writing styles based on content type:

- **Guide/Tutorial Style** — Step-by-step instructions, comprehensive coverage, feature comparisons
- **Concept Explanation Style** — First-principles understanding, progressive disclosure, problem-solution narrative

## When to Use

Invoke this skill when the user:

- Has raw notes or ideas they want to turn into a blog post
- Mentions creating an article, tutorial, or guide
- Wants to share technical knowledge with a community
- Has educational content that needs structure and polish
- Says "write this up", "make this into a post", "publish this"

## Input Requirements

The user should provide:

- **Content**: Raw notes, bullet points, ideas, or an outline
- **Topic**: What the post is about (if not obvious from content)
- **Optional**: Target audience, specific style preference, or key points to emphasize

## Output Format

Always produce **TWO complete blog posts**:

1. **Vietnamese version** (`blog-post-vi.md`)
2. **English version** (`blog-post-en.md`)

Both versions should:

- Follow the same structure and organization
- Use culturally appropriate examples and references
- Maintain the same level of technical depth
- Include all diagrams, code blocks, and tables

## Style Selection Logic

Analyze the content to determine which style fits best:

### Guide/Tutorial Style

**Use when content:**

- Explains how to do something step-by-step
- Compares multiple tools, frameworks, or approaches
- Covers a comprehensive topic with multiple aspects
- Includes setup instructions or configurations
- Has a "feature tour" or "getting started" nature

**Characteristics:**

- TL;DR summary section at the top
- Numbered main sections (Phần 1, Phần 2... / Part 1, Part 2...)
- Heavy use of tables for comparisons
- Research citations and links
- Blockquotes for key insights
- Clear hierarchical structure

**Example topics**: "Complete Guide to Claude Code", "Docker Best Practices", "Next.js 15 Features"

### Concept Explanation Style

**Use when content:**

- Explains fundamental concepts or theory
- Answers "why" or "how it works" questions
- Progresses from problem to solution
- Builds understanding from first principles
- Addresses common misconceptions

**Characteristics:**

- Problem statement before solution
- Subsection numbering (1.1, 1.2, 2.1...)
- ASCII diagrams in code blocks
- Conversational, teaching tone
- Heavy use of rhetorical questions
- Progressive concept building

**Example topics**: "Understanding Microservices", "Why Beads Solves Agent Memory", "How React Hooks Work"

## Blog Post Structure

### Required Components

Every blog post must include:

1. **Title** — Clear, descriptive, SEO-friendly
2. **Subtitle/Context** — Target audience or key context (in blockquote)
3. **Opening Hook** — Why this matters, what problem it solves
4. **Main Sections** — 3-7 major sections with clear headers
5. **Code Examples** — Real, runnable code when relevant
6. **Visual Aids** — Tables, diagrams, comparisons
7. **Key Takeaways** — Summary of important points
8. **Conclusion** — Next steps or call to action

### Markdown Formatting Standards

Use these consistently:

```markdown
# Main Title

> **Context or Target Audience**

## Section (Phần/Part)

### Subsection

**Bold for emphasis** — Description follows

| Column 1     | Column 2 |
| :----------- | :------- |
| Left-aligned | Content  |

`code blocks with syntax highlighting`

> Blockquote for important insights or research citations

---

Horizontal rule between major sections
```

## Vietnamese Writing Guidelines

When creating the Vietnamese version:

### Language Style

- Use formal but accessible Vietnamese
- Mix Vietnamese terms with English technical terms where standard (e.g., "AI Agent", "Context Window")
- Translate conceptual terms (e.g., "người gác cổng" for "gatekeeper")
- Keep code terms in English (variable names, commands, etc.)

### Cultural Adaptation

- Use Vietnamese-appropriate examples and scenarios
- Reference Vietnamese tech communities when relevant
- Maintain the educational, respectful tone common in Vietnamese technical writing
- Use parenthetical translations for important English terms: "Gatekeeper (người gác cổng)"

### Formatting

- Section headers: "Phần 1:", "Phần 2:" for main sections
- Subsections: "1.1", "1.2" or "### Subsection Name"
- Use Vietnamese punctuation rules
- Maintain all code blocks, URLs, and technical terms in original form

### Common Translations

- Guide → Hướng dẫn
- Best Practices → Phương pháp tốt nhất / Best practices
- Setup → Thiết lập / Setup
- Example → Ví dụ
- Note → Lưu ý
- Important → Quan trọng
- Comparison → So sánh

## English Writing Guidelines

When creating the English version:

### Writing Style

- Clear, direct, professional tone
- Short paragraphs (3-5 sentences max)
- Active voice preferred
- Technical but accessible
- Use analogies and metaphors to explain complex concepts

### Structure

- Strong topic sentences for each paragraph
- Smooth transitions between sections
- Clear signposting ("First", "However", "As a result")
- Bullet points for lists, tables for comparisons

### Technical Accuracy

- Use correct terminology consistently
- Verify code examples are syntactically correct
- Include version numbers for tools/frameworks
- Link to official documentation where relevant

## Content Enhancement

Beyond just translating/structuring the raw content, actively enhance it:

### Add Context

- Explain why this topic matters
- Provide background for complex concepts
- Connect to broader ecosystem or trends

### Add Examples

- Real-world code snippets
- Before/after comparisons
- Common use cases and edge cases

### Add Visual Structure

- Tables comparing approaches
- ASCII diagrams for architecture
- Code blocks with comments
- Blockquotes for research citations

### Add Value

- Link to authoritative sources
- Cite relevant research or data
- Include performance metrics if applicable
- Suggest next steps or related topics

## Quality Checklist

Before finalizing output, verify:

- [ ] Both Vietnamese and English versions created
- [ ] Same structure and content depth in both languages
- [ ] Appropriate style (guide vs. concept) selected and applied
- [ ] All code blocks have syntax highlighting
- [ ] Tables properly formatted
- [ ] Headers create clear hierarchy
- [ ] Engaging opening hook present
- [ ] Clear takeaways or conclusion
- [ ] No grammar or spelling errors
- [ ] Technical accuracy verified
- [ ] Links work and point to correct resources

## Workflow

1. **Analyze Input**
   - Understand the core topic
   - Identify the type of content (guide vs. concept)
   - Note the target audience level
   - Extract key points and structure

2. **Plan Structure**
   - Outline main sections
   - Decide on guide vs. concept style
   - Plan comparisons, examples, diagrams
   - Identify gaps that need filling

3. **Create Vietnamese Version**
   - Write complete blog post in Vietnamese
   - Follow selected style template
   - Enhance with examples and context
   - Save as `blog-post-vi.md`

4. **Create English Version**
   - Adapt content for English audience
   - Maintain same structure and depth
   - Culturally appropriate examples
   - Save as `blog-post-en.md`

5. **Quality Review**
   - Check both versions against quality checklist
   - Ensure consistency between versions
   - Verify all formatting is correct
   - Confirm technical accuracy

## Common Patterns

### Opening Hook Patterns

**Problem-Solution:**

```markdown
Many developers struggle with [problem]. This leads to [consequences].
In this guide, we'll explore [solution] and why it matters.
```

**Context-Setting:**

```markdown
[Technology/Concept] has changed how we [do something].
But understanding [key aspect] remains challenging for many developers.
```

**Story-Based:**

```markdown
Imagine you're building [scenario]. You encounter [problem].
This is where [topic] becomes essential.
```

### Section Transition Patterns

**Continuation:**

```markdown
Now that we understand [previous concept], let's explore [next concept].
```

**Contrast:**

```markdown
While [approach A] works for [scenario], [approach B] excels when [different scenario].
```

**Deep Dive:**

```markdown
This raises an important question: [question]?
Let's break this down.
```

## Examples

### Example 1: Guide Style

**Input (raw notes):**

```
Docker best practices
- Use multi-stage builds
- Don't run as root
- Minimize layers
- Use .dockerignore
- Health checks
```

**Output Structure:**

```markdown
# Docker Best Practices for Production

> **For developers deploying containerized applications**

## TL;DR

Quick reference for production-ready Docker configurations...

## Part 1: Security Fundamentals

### 1.1 Never Run as Root

[Explanation with example]

### 1.2 Multi-Stage Builds

[Explanation with before/after code]

## Part 2: Performance Optimization

...
```

### Example 2: Concept Style

**Input (raw notes):**

```
Why GraphQL?
- REST has over-fetching problem
- Multiple endpoints = multiple requests
- GraphQL solves this
- Single endpoint, query what you need
```

**Output Structure:**

```markdown
# Understanding GraphQL - From REST Problems to Solutions

> **For developers questioning if GraphQL is right for their project**

## Part 1: The REST API Problem

### 1.1 What is Over-Fetching?

Imagine you're building a user profile page...

[ASCII diagram showing REST calls]

### 1.2 The N+1 Query Problem

When you fetch a list of items...

## Part 2: How GraphQL Solves This

...
```

## Tips for Success

1. **Start with Understanding** — Make sure you understand the core concept before writing. If unclear, ask the user clarifying questions.

2. **Show, Don't Just Tell** — Use code examples, diagrams, and scenarios to illustrate points, not just describe them.

3. **Balance Detail and Accessibility** — Technical depth is important, but explain complex concepts progressively.

4. **Maintain Parallel Structure** — Vietnamese and English versions should mirror each other in organization.

5. **Enhance, Don't Just Format** — Add context, examples, and transitions that make the content more valuable.

6. **Use Voice Appropriately** — Guides can be more prescriptive; concept explanations more exploratory.

## Output Files

Always create these two files in the current directory:

- `blog-post-vi.md` — Vietnamese version
- `blog-post-en.md` — English version

If the user specifies a different naming preference, use that instead.
