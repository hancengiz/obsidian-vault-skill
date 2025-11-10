---
description: Capture a quick note to today's daily note
argument-hint: [note content]
allowed-tools:
  - Task(*)
  - Read(*)
  - Write(*)
  - Bash(*)
---

## Context

- **Today's Date:** `date "+%Y-%m-%d"`
- **Note Content:** `$ARGUMENTS`
- **Vault Folder:** `Daily/`
- **File Format:** Markdown (appended to existing daily note)
- **Obsidian Skill:** Available for API operations

## Your Task

Capture a quick note to today's daily note with timestamp and clean formatting.

### Process

1. **Get or Create Daily Note**
   - Check if daily note exists for today
   - Path: `Daily/YYYY-MM-DD.md`
   - If not exists, create with header
   - If exists, append to it

2. **Format the Quick Note**
   - Add timestamp (HH:MM)
   - Clean up the content
   - Add to appropriate section (or create "Quick Notes" section)
   - Maintain Obsidian formatting (wikilinks, markdown, etc.)

3. **Append to Daily Note**
   - Use Obsidian skill PATCH operation to append
   - Target: Today's daily note
   - Operation: `append`
   - Content: Formatted quick note entry

4. **Confirm Success**
   - Show the user the note was captured
   - Display timestamp and content preview
   - Offer link to today's daily note

---

## Example Daily Note Structure

```markdown
---
title: Daily Note - 2024-11-11
date: 2024-11-11
tags:
  - daily
  - 2024-11
type: daily
---

# 2024-11-11

## Quick Notes

- **14:30** - Remember to update the documentation
- **15:45** - Need to review the installation script changes
- **16:20** - Idea: Add capture command to the skill

## Tasks
- [ ] Test the capture workflow
- [ ] Review pull requests

## Events
- Team standup at 10:00
- Code review session at 14:00

## Reflections
Good progress on the installer script fixes today.
```

---

## Implementation Details

### Creating Daily Note (if needed)

```python
import os
import requests
from datetime import datetime

api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
base_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')
headers = {'Authorization': f'Bearer {api_key}'}

today = datetime.now().strftime("%Y-%m-%d")
year_month = datetime.now().strftime("%Y-%m")
daily_note_content = f"""---
title: Daily Note - {today}
date: {today}
tags:
  - daily
  - {year_month}
type: daily
---

# {today}

## Quick Notes

## Tasks

## Events

## Reflections
"""

# Create daily note if it doesn't exist
response = requests.put(
    f'{base_url}/vault/Daily/{today}.md',
    headers=headers,
    data=daily_note_content,
    verify=False,
    timeout=10
)
```

### Appending Quick Note (PATCH)

```python
timestamp = datetime.now().strftime("%H:%M")
note_text = f"- **{timestamp}** - {content}"

# Append to Quick Notes section
response = requests.patch(
    f'{base_url}/vault/Daily/{today}.md',
    headers={
        **headers,
        'Operation': 'append',
        'Target-Type': 'heading',
        'Target': 'Quick Notes',
        'Content-Type': 'text/markdown'
    },
    data=note_text,
    verify=False,
    timeout=10
)

if response.status_code == 200:
    print(f"✓ Quick note captured at {timestamp}")
else:
    print(f"✗ Error: {response.status_code}")
```

---

## Tips

- **Quick captures are for temporary thoughts** that might be developed later
- **Use timestamps** to track when you captured the thought
- **Review daily** to process and organize quick notes
- **Move important items** to dedicated notes or projects
- **Archive old daily notes** when no longer needed

---

## Quick Examples

### Example 1: Simple Reminder
```
Input: "Remember to update the documentation"
Output: Added to Daily/2024-11-11.md
         - **14:30** - Remember to update the documentation
```

### Example 2: Follow-up Task
```
Input: "Need to review the installation script changes"
Output: Added to Daily/2024-11-11.md
         - **15:45** - Need to review the installation script changes
```

### Example 3: Quick Idea
```
Input: "Add capture command to the skill"
Output: Added to Daily/2024-11-11.md
         - **16:20** - Add capture command to the skill
```
