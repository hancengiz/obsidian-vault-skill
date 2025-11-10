---
description: Capture an idea to the Ideas vault folder
argument-hint: [idea content]
allowed-tools:
  - Task(*)
  - Read(*)
  - Write(*)
  - Bash(*)
---

## Context

- **Today's Date:** `date "+%Y-%m-%d"`
- **Idea Content:** `$ARGUMENTS`
- **Vault Folder:** `Ideas/`
- **File Format:** Markdown with YAML frontmatter
- **Obsidian Skill:** Available for API operations

## Your Task

Capture an idea to your Obsidian vault with proper formatting and metadata.

### Process

1. **Generate Filename**
   - Extract 2-4 keywords from the idea content
   - Create slug format: `keyword-keyword-keyword.md`
   - Example: "I had an insight about using Claude Code for Obsidian automation" → `Claude-Code-Obsidian-Automation.md`

2. **Create Structured Note**
   - Add YAML frontmatter with:
     - `title`: Concise title from content
     - `date`: Today's date
     - `tags`: Relevant tags (e.g., #idea, #concept, #brainstorm)
     - `status`: `active` (for tracking)
   - Add main content
   - Include timestamp at the bottom

3. **Save to Vault**
   - Use the Obsidian skill to create the file
   - Location: `Ideas/[filename].md`
   - Full path: `Ideas/Claude-Code-Obsidian-Automation.md`

4. **Confirm Success**
   - Show the user the file was created
   - Provide the path and filename
   - Offer a link to open it in Obsidian

---

## Example Note Structure

```markdown
---
title: Claude Code Obsidian Automation
date: 2024-11-11
tags:
  - idea
  - claude-code
  - obsidian
  - automation
status: active
---

# Claude Code Obsidian Automation

I had an insight about using Claude Code for Obsidian automation. This could enable:
- Automated note creation and updates
- Smart content routing
- Batch operations on vault files
- Integration with external data sources

## Related Ideas
- [[Obsidian Skill Development]]
- [[Claude Code Integration]]

---
*Created: 2024-11-11 at 14:30*
```

---

## Implementation Details

### Using Obsidian Skill

When you have the note content ready, use the Obsidian skill to create it:

```python
import os
import requests

api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
base_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')
headers = {'Authorization': f'Bearer {api_key}'}

# Create idea note
response = requests.put(
    f'{base_url}/vault/Ideas/Claude-Code-Obsidian-Automation.md',
    headers=headers,
    data=note_content,
    verify=False,
    timeout=10
)

if response.status_code == 201:
    print("✓ Idea captured successfully!")
else:
    print(f"✗ Error: {response.status_code}")
```

---

## Tips

- **Keep ideas concise** but include enough context to revisit later
- **Use wikilinks** `[[related-note]]` to connect ideas
- **Tag systematically** for easy searching and filtering
- **Review weekly** to identify actionable insights
- **Archive old ideas** by changing status to `archived`

---

## Quick Examples

### Example 1: Simple Concept
```
Input: "idea about using JSON queries for advanced Obsidian searches"
Generated: Ideas/JSON-Queries-Obsidian-Search.md
```

### Example 2: Complex Insight
```
Input: "insight that Claude Code skills could handle multi-step Obsidian workflows with approval gates"
Generated: Ideas/Claude-Skills-Multi-Step-Workflows.md
```
