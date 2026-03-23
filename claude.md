# Context Management

Context is your most important resource.
Proactively use subagents (Task tool) to keep exploration, research, and verbose operations out of the main conversation.

## Default to spawning agents for:

• **Codebase exploration** (reading 3+ files to answer a question)
• **Research tasks** (web searches, doc lookups, investigating how something works)
• **Code review or analysis** (produces verbose output)
• **Any investigation** where only the summary matters

## Stay in main context for:

• **Direct file edits** the user requested
• **Short, targeted reads** (1-2 files)
• **Conversations requiring back-and-forth**
• **Tasks where user needs intermediate steps**

## Rule of thumb:
If a task will read more than 3 files or produce output the user doesn't need to see verbatim, delegate it to a subagent and return a summary.

## Sub-Agent Types Available:

### 1. **Explore Agent**
- **Purpose**: Fast codebase exploration and understanding
- **Use for**: Finding files by patterns, searching code for keywords, answering questions about codebase structure
- **Thoroughness levels**: "quick", "medium", "very thorough"

### 2. **General-Purpose Agent**
- **Purpose**: Complex multi-step tasks and research
- **Use for**: Searching for keywords/files when not confident about finding the right match
- **Tools**: Full access to all tools

### 3. **Tech Research Assistant**
- **Purpose**: Research technologies, libraries, frameworks for specific projects
- **Use for**: Authentication solutions, database options, debugging library issues
- **Tools**: Web research, documentation lookup, code examples

### 4. **Plan Agent**
- **Purpose**: Planning complex implementations
- **Use for**: Breaking down large features, architectural decisions
- **Tools**: Full codebase access for planning

## Best Practices:

1. **Always specify thoroughness level** when using Explore agent
2. **Use parallel subagents** when possible for efficiency
3. **Delegate verbose operations** to keep main conversation clean
4. **Return concise summaries** from subagent work
5. **Use appropriate agent type** for the specific task

## Sub-Agent Usage Examples:

### 🔍 **Explore Agent Examples**

```
// Quick codebase overview
Task(subagent_type="Explore", thoroughness="quick",
     prompt="What is the overall structure of this project?")

// Find specific functionality
Task(subagent_type="Explore", thoroughness="medium",
     prompt="Find all authentication-related code in the codebase")

// Deep architectural analysis
Task(subagent_type="Explore", thoroughness="very thorough",
     prompt="Analyze the entire data flow from API to database")
```

### 🔬 **Tech Research Assistant Examples**

```
// Library research
Task(subagent_type="tech-research-assistant",
     prompt="Research the best authentication libraries for React applications")

// Debugging help
Task(subagent_type="tech-research-assistant",
     prompt="I'm getting errors with axios interceptors, help me debug this")

// Technology comparison
Task(subagent_type="tech-research-assistant",
     prompt="Compare database options for a Node.js social media app")
```

### 🎯 **General-Purpose Agent Examples**

```
// Complex multi-step tasks
Task(subagent_type="general-purpose",
     prompt="Search for all instances of 'getCwd' function across the project and analyze its usage patterns")

// Research with multiple sources
Task(subagent_type="general-purpose",
     prompt="Research and document the complete CI/CD pipeline setup for this project")
```

### 📋 **Plan Agent Examples**

```
// Feature planning
Task(subagent_type="Plan",
     prompt="Plan the implementation of a user authentication system for this React app")

// Architecture decisions
Task(subagent_type="Plan",
     prompt="Design an approach for adding real-time notifications to the existing system")
```

## When to Use Each Agent:

| Task Type | Agent | Reasoning |
|-----------|--------|-----------|
| "How does authentication work in this app?" | **Explore** (medium) | Codebase exploration |
| "What are the best JWT libraries for Node.js?" | **Tech Research** | Technology research |
| "Find all TODO comments and categorize them" | **General-Purpose** | Multi-step analysis |
| "Plan implementation of dark mode" | **Plan** | Architecture planning |
| "Debug this specific error message" | Stay in **main context** | Direct problem solving |
| "Edit this single file" | Stay in **main context** | Direct file operation |

## Parallel Sub-Agent Workflow:

```
// Launch multiple agents simultaneously for efficiency
Task(subagent_type="Explore", prompt="Analyze the frontend architecture")
Task(subagent_type="Explore", prompt="Analyze the backend API structure")
Task(subagent_type="tech-research-assistant", prompt="Research state management options")
```
