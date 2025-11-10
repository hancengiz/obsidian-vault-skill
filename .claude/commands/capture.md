---
description: Smart capture to Obsidian vault with automatic routing
argument-hint: [content to capture]
allowed-tools:
  - Task(*)
  - Read(*)
  - Write(*)
  - Bash(*)
---

## Context

- **Today's Date:** `date "+%Y-%m-%d"`
- **User Input:** `$ARGUMENTS`
- **Helper Commands:**
  - `.claude/commands/idea.md` - For capturing ideas and concepts
  - `.claude/commands/quick-note.md` - For capturing quick notes to daily note

## Your Task

Create a smart capture item that automatically routes to the appropriate location in your Obsidian vault using intelligent categorization. All notes include proper frontmatter with date and tags.

### Detection Rules

#### Mode 1: Idea Capture
**Trigger when input contains idea-related keywords:**
- "idea", "concept", "thought", "insight", "brainstorm", "theory", "hypothesis"

**Action:**
- Route to `.claude/commands/idea.md`
- Creates/appends to `Ideas/` folder with structured frontmatter
- Format: Title, tags, and content with metadata

#### Mode 2: Quick Note Capture (Default)
**Trigger for everything else, or when explicitly requested**

**Action:**
- Route to `.claude/commands/quick-note.md`
- Appends to today's daily note in `Daily/` folder
- Format: Timestamped entry in daily note

---

## Implementation

### Step 1: Analyze Input
Examine the user input for keyword matches:
- Convert to lowercase
- Check against idea keywords
- Determine capture type

### Step 2: Route to Helper Command
Based on analysis, execute the appropriate helper command with the content.

### Step 3: Confirm Action
Show the user where the note was saved and provide a link to access it.

---

## Example Usage

**Example 1 - Idea Capture:**
```
/capture I had an insight about using Claude Code for Obsidian automation
→ Routes to idea.md
→ Creates: Ideas/Claude-Obsidian-Automation.md
```

**Example 2 - Quick Note Capture:**
```
/capture Remember to update the documentation
→ Routes to quick-note.md
→ Appends to: Daily/2024-11-11.md
```

**Example 3 - Smart Detection:**
```
/capture Just thought of a new feature for the skill
→ Detects "thought" keyword
→ Routes to idea.md
```
