# ADR-004: SKILL.md Design and Structure

**Status**: Draft
**Date**: 2025-11-10
**Decision Makers**: Development Team
**Related**: ADR-001 (Skill Architecture), ADR-002 (Destructive Operation Guardrails), ADR-003 (Automatic Backup System)

---

## Context

The SKILL.md file is the core deliverable - it's what users install and what Claude Code/Claude Desktop executes. This file must contain all instructions, safety rules, API knowledge, and operational guidelines in a format that Claude can understand and follow reliably.

### Key Challenges

1. **Skill Behavior Consistency**: Claude must interpret instructions the same way every time
2. **Safety-Critical**: Destructive operations must never bypass guardrails due to unclear instructions
3. **API Complexity**: 31 endpoints with different behaviors, content types, and error cases
4. **User Experience**: Natural language interaction while maintaining strict safety
5. **Platform Compatibility**: Must work identically on Claude Code (CLI) and Claude Desktop
6. **Token Efficiency**: Comprehensive but not bloated - avoid hitting context limits

### Requirements

**Must Have**:
- ✅ Clear YAML frontmatter (name, description, tool access)
- ✅ Complete API endpoint reference (all 31 endpoints)
- ✅ Explicit safety rules that cannot be misinterpreted
- ✅ Configuration loading logic (multi-source fallback)
- ✅ Error handling patterns
- ✅ Path format rules
- ✅ Content-Type specifications
- ✅ Obsidian syntax preservation rules

**Should Have**:
- ✅ Code examples for common operations
- ✅ Troubleshooting guidance
- ✅ Best practices and patterns
- ✅ Natural language interaction guidelines

**Could Have**:
- Workflow examples
- Advanced usage patterns
- Performance optimization tips

---

## Decision

**We will structure SKILL.md with a modular, hierarchical architecture** that prioritizes:

1. **Safety-First Design**: Critical safety rules at the top, repeated where needed
2. **Reference-Style API Docs**: Concise endpoint reference with all 31 endpoints
3. **Operational Patterns**: Reusable code patterns for common operations
4. **Configuration Clarity**: Multi-source config loading with explicit priority
5. **Error-First Thinking**: Comprehensive error handling before success cases

### High-Level Structure

```markdown
---
name: obsidian-vault
description: |
  Integrate with Obsidian vaults via Local REST API.
  Use when user wants to search, read, create, or modify Obsidian notes.
tools: [Bash, Read, Write]
---

# 1. GUARDRAIL DEFINITIONS (Reusable Safety Patterns)
# 2. Configuration & Setup
# 3. API Endpoint Reference
# 4. Operational Patterns
# 5. Error Handling
# 6. Obsidian Syntax & Conventions
# 7. User Interaction Guidelines
```

---

## Detailed Design

### Section 1: GUARDRAIL DEFINITIONS

**Purpose**: Define reusable safety patterns that endpoints reference

**Design Principles**:
- **Single Responsibility**: Each guardrail handles one type of risk
- **Reusable**: Multiple endpoints can reference the same guardrail
- **Unambiguous**: Clear triggers, conditions, and confirmation requirements
- **ID-based References**: APIs reference guardrails by ID (G1, G2, etc.)

**Example Structure**:

```markdown
# GUARDRAIL DEFINITIONS

Each guardrail defines WHEN it applies, WHAT it checks, and HOW to confirm.

---

## G1: DELETE Permission Check
**ID**: `G1`
**Type**: Config-based blocking
**Applies to**: All DELETE operations
**Risk Level**: 🔴 CRITICAL - Permanent data loss

**Logic**:
1. Load `allowDelete` from config (see Configuration section)
2. If `allowDelete` is `false` (default) → **BLOCK operation entirely**
3. If `allowDelete` is `true` → Proceed to G2 (DELETE Confirmation)

**User Message (when blocked)**:
```text
❌ DELETE operations are disabled

To enable DELETE operations, set:
  - Environment: OBSIDIAN_SKILL_ALLOW_DELETE=true
  - .env file: allowDelete=true
  - Config file: ~/.cc_obsidian/config.json → "allowDelete": true

⚠️  Enabling DELETE is permanent. Consider using backups.
```

**Affected Endpoints**:
- `DELETE /active/`
- `DELETE /vault/{filename}`
- `DELETE /periodic/{period}/`
- `DELETE /periodic/{period}/{year}/{month}/{day}/`

---

## G2: DELETE Confirmation
**ID**: `G2`
**Type**: Mandatory user confirmation
**Applies to**: All DELETE operations (after G1 passes)
**Risk Level**: 🔴 CRITICAL - Irreversible

**Logic**:
1. Get file content for preview (if accessible)
2. Calculate file stats (lines, words, size)
3. Show confirmation prompt with:
   - Operation type (DELETE)
   - Target path
   - Content preview (first 200 chars)
   - File stats
4. Require exact text match: user MUST type `DELETE` (all caps)
5. If current periodic note (today's daily, this week's weekly):
   - Extra warning: "⚠️⚠️⚠️ THIS IS TODAY'S DAILY NOTE"
   - Require typing: `DELETE TODAY` instead

**Can be skipped?** NO - NEVER (even with `DANGEROUSLY_SKIP_CONFIRMATIONS=true`)

**Confirmation Template**:
```text
⚠️  DESTRUCTIVE OPERATION - FILE DELETION

Operation: DELETE
Target: Projects/meeting-notes.md
Current size: 234 lines (1,456 words)

--- Content preview ---
Meeting Notes - Q4 Planning
[first 200 chars of content]
--- End preview ---

⚠️  This operation CANNOT be undone.
⚠️  A backup will be created (if backup.enabled: true)

Type 'DELETE' (in caps) to confirm, or 'cancel' to abort: _
```

**For Current Period Notes**:
```text
⚠️⚠️⚠️  DELETING TODAY'S DAILY NOTE ⚠️⚠️⚠️

File: 2025-11-10.md (TODAY'S daily note)
Created: Today at 6:00 AM
Modified: 5 minutes ago
Size: 1,234 lines (5,678 words)

--- Content preview ---
2025-11-10 - Sunday
Morning Review
[content...]
--- End preview ---

⚠️  This contains ALL of today's entries, tasks, and notes.
⚠️  Consider archiving instead of deleting.

Type 'DELETE TODAY' (exactly) to confirm, or 'cancel' to abort: _
```

---

## G3: PUT Confirmation (File Exists)
**ID**: `G3`
**Type**: User confirmation with existence check
**Applies to**: PUT operations on existing files
**Risk Level**: 🟠 HIGH - Complete content replacement

**Logic**:
1. **Check if file exists** (GET request)
2. If file doesn't exist → Skip to simple "yes/no" confirmation (creating new file)
3. If file exists:
   - Get current content
   - Calculate stats (lines, words)
   - Show content preview (first 100 + last 100 chars)
   - Suggest safer alternatives (POST for append, PATCH for sections)
   - Require exact text match: `REPLACE` (all caps)

**Can be skipped?** YES (with `DANGEROUSLY_SKIP_CONFIRMATIONS=true`)

**Confirmation Template (File Exists)**:
```text
⚠️  DESTRUCTIVE OPERATION - CONTENT REPLACEMENT

Operation: PUT (Replace All Content)
Target: Projects/meeting-notes.md
Current size: 234 lines (1,456 words)

--- Current content preview ---
[First 100 chars...]
...
[Last 100 chars...]
--- End current content ---

--- New content preview ---
[First 100 chars of new content...]
--- End new content ---

⚠️  ALL existing content will be PERMANENTLY LOST.
⚠️  A backup will be created (if backup.enabled: true)

Safer alternatives:
  - POST /vault/Projects/meeting-notes.md → Append to end
  - PATCH /vault/Projects/meeting-notes.md → Modify specific section

Type 'REPLACE' (in caps) to confirm, or 'cancel' to abort: _
```

**Confirmation Template (New File)**:
```text
Creating new file: Projects/new-note.md

--- Content preview ---
[First 200 chars...]
--- End preview ---

Confirm? (yes/no): _
```

**Affected Endpoints**:
- `PUT /active/`
- `PUT /vault/{filename}`
- `PUT /periodic/{period}/`
- `PUT /periodic/{period}/{year}/{month}/{day}/`

---

## G4: PATCH Replace Confirmation
**ID**: `G4`
**Type**: Operation-conditional confirmation
**Applies to**: PATCH operations with `Operation: replace` header
**Risk Level**: 🟡 MEDIUM - Section replacement

**Logic**:
1. Check `Operation` header value
2. If `Operation: append` or `Operation: prepend` → **Skip guardrail** (safe, additive)
3. If `Operation: replace`:
   - Get current file content
   - Parse and extract target section (if possible)
   - Show current section content
   - Show new section content
   - Require confirmation: type `yes`

**Can be skipped?** YES (with `DANGEROUSLY_SKIP_CONFIRMATIONS=true`)

**Confirmation Template**:
```text
⚠️  PARTIAL CONTENT REPLACEMENT

Operation: PATCH with Operation=replace
Target Type: heading
Target: "Tasks"
File: Projects/meeting-notes.md

--- Current section content ---
Tasks section:
- [ ] Review Q4 goals
- [ ] Schedule team sync
--- End current section ---

--- New section content ---
Tasks section:
- [ ] Complete project proposal
--- End new section ---

⚠️  This section will be completely replaced.
⚠️  A backup will be created (if backup.enabled: true)

Type 'yes' to confirm, or 'no' to cancel: _
```

**Affected Endpoints**:
- `PATCH /active/` (only when `Operation: replace`)
- `PATCH /vault/{filename}` (only when `Operation: replace`)
- `PATCH /periodic/{period}/` (only when `Operation: replace`)
- `PATCH /periodic/{period}/{year}/{month}/{day}/` (only when `Operation: replace`)

---

## G5: Bulk Operation Confirmation
**ID**: `G5`
**Type**: Count-based confirmation
**Applies to**: Operations affecting >5 files
**Risk Level**: 🟡 MEDIUM - Multiple file modification

**Logic**:
1. Count total files affected by operation
2. If count ≤ 5 → **Skip guardrail** (small batch, proceed)
3. If count > 5:
   - Show complete list of affected files
   - Display count prominently: "This will affect N files"
   - Require confirmation: type `yes`

**Can be skipped?** YES (with `DANGEROUSLY_SKIP_CONFIRMATIONS=true`)

**Confirmation Template**:
```text
⚠️  BULK OPERATION

Operation: POST (Append)
Affected files: 12

Files to be modified:
  1. Archive/2025-01-01.md
  2. Archive/2025-01-02.md
  3. Archive/2025-01-03.md
  [...]
 12. Archive/2025-01-12.md

--- Content to append ---
[Preview of content being appended]
--- End content ---

Type 'yes' to proceed, or 'no' to cancel: _
```

**Affected Operations**:
- Any POST operation affecting >5 files
- Any batch PUT/PATCH/DELETE (though DELETE has G1+G2)

---

## G6: Active File Context Check
**ID**: `G6`
**Type**: Pre-operation context verification
**Applies to**: All operations on `/active/` endpoints
**Risk Level**: 🟡 MEDIUM - User may not know active file

**Logic**:
1. Call `GET /active/` to retrieve current active file path
2. Display prominently: "Active file: path/to/file.md"
3. Ask user: "Is this the file you want to [operation]?"
4. If user unsure or says no → **ABORT operation**
5. Suggest user check Obsidian window first

**Can be skipped?** NO (always show active file path)

**Confirmation Template**:
```text
The currently active file in Obsidian is:
📄 Projects/meeting-notes.md

Is this the file you want to [DELETE/modify/append to]? (yes/no): _

(If unsure, check your Obsidian window first)
```

**Affected Endpoints**:
- `PUT /active/`
- `POST /active/`
- `PATCH /active/`
- `DELETE /active/`

---

## G7: User Abort Keywords
**ID**: `G7`
**Type**: Global abort pattern
**Applies to**: All confirmation prompts
**Risk Level**: N/A (safety mechanism)

**Logic**:
1. Accept any of these keywords as immediate abort:
   - "no"
   - "cancel"
   - "stop"
   - "abort"
2. Acknowledge: "❌ Operation cancelled"
3. Stop execution immediately
4. Do NOT proceed with any part of the operation

**Can be skipped?** NO (always active)

**Response**:
```text
❌ Operation cancelled

No changes were made.
```

---

### Section 2: Configuration & Setup

**Purpose**: Define all configuration options with clear examples

**Contents**:
- Configuration sources (env vars, .env, config.json)
- All settings with types and defaults
- Example configurations for different use cases
- API key setup instructions
- Base URL configuration (HTTP vs HTTPS)

**Design Principle**: Users should be able to copy-paste examples directly

**Example Structure**:

```markdown
# Configuration & Setup

## Configuration Sources

The skill uses a **three-tier fallback system**:

1. **Environment Variables** (Highest Priority)
   - Prefix: `OBSIDIAN_SKILL_`
   - Example: `OBSIDIAN_SKILL_API_KEY="your-key"`

2. **Project .env File** (Second Priority)
   - Location: `.env` in project root
   - No prefix required
   - Example: `apiKey=your-key`

3. **User Config File** (Lowest Priority)
   - Location: `~/.cc_obsidian/config.json`
   - No prefix required
   - Example: `{"apiKey": "your-key"}`

## Available Settings

| Setting | Env Var | Config Key | Type | Default | Description |
|---------|---------|------------|------|---------|-------------|
| API Key | `OBSIDIAN_SKILL_API_KEY` | `apiKey` | string | *required* | Authentication token |
| API URL | `OBSIDIAN_SKILL_API_URL` | `apiUrl` | string | `https://localhost:27124` | Base URL |
| Allow DELETE | `OBSIDIAN_SKILL_ALLOW_DELETE` | `allowDelete` | boolean | `false` | Enable DELETE operations |
| Backup Enabled | `OBSIDIAN_SKILL_BACKUP_ENABLED` | `backupEnabled` | boolean | `true` | Auto-backup before destructive ops |
| Backup Directory | `OBSIDIAN_SKILL_BACKUP_DIRECTORY` | `backupDirectory` | string | `~/.cc_obsidian/backups` | Where to store backups |
| Backup Keep N | `OBSIDIAN_SKILL_BACKUP_KEEP_LAST_N` | `backupKeepLastN` | number | `5` | Number of backups to keep |
| Skip Confirmations | `OBSIDIAN_SKILL_DANGEROUSLY_SKIP_CONFIRMATIONS` | `DANGEROUSLY_SKIP_CONFIRMATIONS` | boolean | `false` | Skip confirmations (except DELETE) |

## Example Configurations

### User Config (~/.cc_obsidian/config.json)

```json
{
  "apiKey": "your-api-key-here",
  "apiUrl": "https://localhost:27124",
  "allowDelete": false,
  "backupEnabled": true,
  "backupDirectory": "~/.cc_obsidian/backups",
  "backupKeepLastN": 5,
  "DANGEROUSLY_SKIP_CONFIRMATIONS": false
}
```

### Environment Variables

```bash
export OBSIDIAN_SKILL_API_KEY="your-key"
export OBSIDIAN_SKILL_API_URL="https://localhost:27124"
export OBSIDIAN_SKILL_ALLOW_DELETE=false
```

## Configuration Loading Implementation

[Code example showing multi-source loading]
```

### Section 3: API Endpoint Reference

**Purpose**: Concise, scannable reference for all 31 endpoints

**Design Principles**:
- **Categorize logically**: Group by resource (vault, active, periodic, search, commands)
- **Essential info only**: Method, endpoint, purpose, key headers, response
- **Risk indicators**: Mark destructive operations clearly
- **Link to examples**: Reference Section 4 for usage patterns

**Example Structure**:

```markdown
# API Endpoint Reference

Each endpoint is formatted with:
- **Human Name**: Descriptive operation name
- **HTTP Endpoint**: Method + path
- **Purpose**: What this operation does
- **Content-Type / Body / Headers**: Technical requirements
- **Risk**: Safety classification
- **Guardrails**: Which guardrails apply (by ID)

---

Base URL: `https://localhost:27124` (default)
Auth: `Authorization: Bearer {API_KEY}`
SSL: Use `verify=False` for self-signed localhost certs
Timeout: Always include `timeout=10`

---

## Vault Operations

### Read Vault File
**HTTP**: `GET /vault/{filename}`
**Purpose**: Read file content
**Returns**: `text/markdown` or `application/vnd.olrapi.note+json` (with metadata)
**Path Format**: `folder/subfolder/note.md` (no leading slash)
**Risk**: 🟢 None (read-only)
**Guardrails**: None

---

### Create or Replace Vault File
**HTTP**: `PUT /vault/{filename}`
**Purpose**: Create new file or completely replace existing file content
**Body**: Markdown content
**Content-Type**: `text/markdown`
**Risk**: 🟠 HIGH - Overwrites ALL content if file exists
**Guardrails**: **G3** (PUT Confirmation)
**See Also**: Use `POST` to append, `PATCH` to modify sections

---

### Append to Vault File
**HTTP**: `POST /vault/{filename}`
**Purpose**: Append content to end of file (creates if doesn't exist)
**Body**: Markdown content to append
**Content-Type**: `text/markdown`
**Risk**: 🟢 Low (append-only, additive)
**Guardrails**: **G5** (only if bulk >5 files)

---

### Modify Vault File Section
**HTTP**: `PATCH /vault/{filename}`
**Purpose**: Surgical content modification of specific sections
**Headers**:
- `Operation`: `append` | `prepend` | `replace` (required)
- `Target-Type`: `heading` | `block` | `frontmatter` (required)
- `Target`: Identifier - e.g., `Tasks`, `^block-id`, `fieldName` (required)
- `Content-Type`: `text/markdown` or `application/json`
**Body**: Content to insert/replace
**Risk**: 🟡 MEDIUM if `Operation: replace`, 🟢 Low if append/prepend
**Guardrails**: **G4** (only when `Operation: replace`)
**Note**: Append/prepend operations are safe and skip guardrails

---

### Delete Vault File
**HTTP**: `DELETE /vault/{filename}`
**Purpose**: Permanently delete file from vault
**Risk**: 🔴 CRITICAL - Irreversible, permanent data loss
**Guardrails**: **G1** (Permission Check) → **G2** (DELETE Confirmation)
**Backup**: Automatic (if `backup.enabled: true`)

## Active File Operations

### GET /active/
**Purpose**: Get path and content of currently active file in Obsidian
**Returns**: File path and content
**Risk**: None (read-only)
**Use Case**: Identify active file before destructive operations

### PUT /active/
**Purpose**: Replace content of active file
**Risk**: ⚠️ HIGH - Overwrites all content
**Guardrails**: See Rule 4 (Active File) + Rule 2 (PUT)

### POST /active/
**Purpose**: Append to active file
**Risk**: Low (append-only)

### PATCH /active/
**Purpose**: Modify section of active file
**Risk**: Medium if `Operation: replace`
**Guardrails**: See Rule 4 (Active File) + Rule 3 (PATCH)

### DELETE /active/
**Purpose**: Delete currently active file
**Risk**: ⚠️⚠️⚠️ CRITICAL - Irreversible
**Guardrails**: See Rule 4 (Active File) + Rule 1 (DELETE)

## Periodic Notes Operations

### GET /periodic/{period}/
**Purpose**: Get current period note (today's daily, this week's weekly, etc.)
**Periods**: `daily`, `weekly`, `monthly`, `quarterly`, `yearly`
**Returns**: Note content
**Risk**: None (read-only)

### GET /periodic/{period}/{year}/{month}/{day}/
**Purpose**: Get specific date's periodic note
**Path Params**: Year (YYYY), month (MM), day (DD) - omit irrelevant parts for weekly/monthly
**Returns**: Note content
**Risk**: None (read-only)

### PUT /periodic/{period}/
**Purpose**: Replace current period note
**Risk**: ⚠️ HIGH - Overwrites current note (e.g., today's daily)
**Guardrails**: Extra warning for current period notes

### PUT /periodic/{period}/{year}/{month}/{day}/
**Purpose**: Replace historical period note
**Risk**: ⚠️ HIGH - Overwrites historical note
**Guardrails**: Show date clearly

### POST /periodic/{period}/
**Purpose**: Append to current period note
**Risk**: Low (append-only)

### POST /periodic/{period}/{year}/{month}/{day}/
**Purpose**: Append to historical period note
**Risk**: Low (append-only)

### PATCH /periodic/{period}/
**Purpose**: Modify section of current period note
**Risk**: Medium if `Operation: replace`

### PATCH /periodic/{period}/{year}/{month}/{day}/
**Purpose**: Modify section of historical period note
**Risk**: Medium if `Operation: replace`

### DELETE /periodic/{period}/
**Purpose**: Delete current period note
**Risk**: ⚠️⚠️⚠️ CRITICAL - Deletes today's/this week's/this month's note
**Guardrails**: Extra prominent warning "THIS IS TODAY'S DAILY NOTE"

### DELETE /periodic/{period}/{year}/{month}/{day}/
**Purpose**: Delete historical period note
**Risk**: ⚠️⚠️⚠️ CRITICAL - Irreversible
**Guardrails**: Show date clearly in confirmation

## Search Operations

### POST /search/simple/
**Purpose**: Simple text search across vault
**Body**: `{"query": "search term", "contextLength": 100}`
**Content-Type**: `application/json`
**Returns**: Array of matches with context
**Risk**: None (read-only)

### POST /search/
**Purpose**: Advanced search (Dataview DQL or JsonLogic)
**Content-Type**:
  - `application/vnd.olrapi.dataview.dql+txt` for Dataview queries
  - `application/vnd.olrapi.jsonlogic+json` for JsonLogic queries
**Body**: Query string or JSON
**Returns**: Search results
**Risk**: None (read-only)

## Commands Operations

### GET /commands/
**Purpose**: List all available Obsidian commands
**Returns**: Array of `{id, name, description}`
**Risk**: None (read-only)

### POST /commands/{commandId}/
**Purpose**: Execute Obsidian command
**Risk**: Variable - analyze command description for dangerous keywords
**Guardrails**: See Rule 5 (Command Execution)

## Directory Operations

### GET /vault/
**Purpose**: List all files and folders in vault
**Returns**: Directory tree
**Risk**: None (read-only)
```

### Section 4: Operational Patterns

**Purpose**: Reusable code examples for common operations

**Design Principles**:
- **Copy-paste ready**: Complete, working code
- **Error handling included**: Always show how to handle failures
- **Guardrails integrated**: Show confirmation prompts in examples
- **Comments explain why**: Not just what the code does

**Example Structure**:

```markdown
# Operational Patterns

## Pattern 1: Read a Note

```python
import os
import requests

api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
api_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')

response = requests.get(
    f'{api_url}/vault/Projects/meeting-notes.md',
    headers={'Authorization': f'Bearer {api_key}'},
    verify=False,  # Required for self-signed localhost cert
    timeout=10     # Always include timeout
)

if response.status_code == 200:
    content = response.text
    print(f"✅ File read successfully ({len(content)} chars)")
    print(content)
elif response.status_code == 404:
    print(f"❌ File not found: Projects/meeting-notes.md")
else:
    print(f"❌ Error {response.status_code}: {response.text}")
```

## Pattern 2: Create New Note (with Confirmation)

```python
import os
import requests

def create_note(file_path: str, content: str):
    """Create new note with confirmation"""

    api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
    api_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')

    # Check if file exists
    check = requests.get(
        f'{api_url}/vault/{file_path}',
        headers={'Authorization': f'Bearer {api_key}'},
        verify=False,
        timeout=10
    )

    if check.status_code == 200:
        # File exists - show warning (PUT would overwrite)
        print(f"⚠️  File already exists: {file_path}")
        print("Use PUT to replace or POST to append")
        return False

    # File doesn't exist - safe to create
    preview = content[:200] + "..." if len(content) > 200 else content
    print(f"Creating new file: {file_path}")
    print(f"Content preview:\n{preview}\n")

    confirm = input("Confirm? (yes/no): ").strip().lower()
    if confirm not in ['yes', 'y']:
        print("❌ Operation cancelled")
        return False

    # Create file
    response = requests.put(
        f'{api_url}/vault/{file_path}',
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'text/markdown'
        },
        data=content,
        verify=False,
        timeout=10
    )

    if response.status_code in [200, 201, 204]:
        print(f"✅ File created: {file_path}")
        return True
    else:
        print(f"❌ Create failed: {response.status_code}")
        print(f"Error: {response.text}")
        return False
```

## Pattern 3: Search Notes

```python
def search_notes(query: str, context_length: int = 100):
    """Search notes with context"""

    api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
    api_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')

    response = requests.post(
        f'{api_url}/search/simple/',
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        },
        json={
            'query': query,
            'contextLength': context_length
        },
        verify=False,
        timeout=10
    )

    if response.status_code == 200:
        results = response.json()
        print(f"✅ Found {len(results)} matches for '{query}'")

        for i, result in enumerate(results, 1):
            filename = result.get('filename', 'unknown')
            context = result.get('context', '')
            print(f"\n{i}. {filename}")
            print(f"   {context}")

        return results
    else:
        print(f"❌ Search failed: {response.status_code}")
        print(f"Error: {response.text}")
        return []
```

## Pattern 4: Update Note Section (PATCH)

```python
def update_note_section(file_path: str, heading: str, new_content: str, operation: str = 'replace'):
    """Update specific section of note using PATCH"""

    api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
    api_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')

    # If operation is 'replace', show current content and confirm
    if operation == 'replace':
        # Get current content
        response = requests.get(
            f'{api_url}/vault/{file_path}',
            headers={'Authorization': f'Bearer {api_key}'},
            verify=False,
            timeout=10
        )

        if response.status_code == 200:
            # Show current section (simplified - would need parsing)
            print(f"⚠️  PARTIAL CONTENT REPLACEMENT")
            print(f"Target: heading '{heading}' in {file_path}")
            print(f"New content:\n{new_content}\n")

            confirm = input("Type 'yes' to confirm: ").strip().lower()
            if confirm != 'yes':
                print("❌ Operation cancelled")
                return False

    # Execute PATCH
    response = requests.patch(
        f'{api_url}/vault/{file_path}',
        headers={
            'Authorization': f'Bearer {api_key}',
            'Operation': operation,  # append, prepend, or replace
            'Target-Type': 'heading',
            'Target': heading,
            'Content-Type': 'text/markdown'
        },
        data=new_content,
        verify=False,
        timeout=10
    )

    if response.status_code in [200, 204]:
        print(f"✅ Section updated: {heading}")
        return True
    else:
        print(f"❌ PATCH failed: {response.status_code}")
        print(f"Error: {response.text}")
        return False
```

## Pattern 5: Daily Note Append

```python
def append_to_daily_note(content: str, date: str = None):
    """
    Append content to daily note

    Args:
        content: Content to append
        date: Optional date (YYYY-MM-DD), defaults to today
    """

    api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
    api_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')

    if date is None:
        # Use current date endpoint
        endpoint = f'{api_url}/periodic/daily/'
    else:
        # Use specific date endpoint
        year, month, day = date.split('-')
        endpoint = f'{api_url}/periodic/daily/{year}/{month}/{day}/'

    response = requests.post(
        endpoint,
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'text/markdown'
        },
        data=content,
        verify=False,
        timeout=10
    )

    if response.status_code in [200, 204]:
        date_str = date or "today"
        print(f"✅ Appended to daily note ({date_str})")
        return True
    else:
        print(f"❌ Append failed: {response.status_code}")
        print(f"Error: {response.text}")
        return False
```

## Pattern 6: Configuration Loading

```python
import os
import json
from pathlib import Path
from typing import Any

def get_config_value(key: str, default: Any = None) -> Any:
    """
    Load configuration value with fallback priority.

    Priority:
    1. Environment variable: OBSIDIAN_SKILL_{KEY_UPPER}
    2. Project .env file: {key}
    3. User config: ~/.cc_obsidian/config.json
    4. Default value
    """

    # 1. Check environment variable with prefix
    env_key = f"OBSIDIAN_SKILL_{key.upper()}"
    env_value = os.getenv(env_key)
    if env_value is not None:
        # Convert string booleans
        if env_value.lower() in ('true', 'false'):
            return env_value.lower() == 'true'
        # Convert numbers
        if env_value.isdigit():
            return int(env_value)
        return env_value

    # 2. Check project .env file (simplified - use python-dotenv in production)
    dotenv_path = Path('.env')
    if dotenv_path.exists():
        with open(dotenv_path) as f:
            for line in f:
                line = line.strip()
                if line.startswith('#') or '=' not in line:
                    continue
                k, v = line.split('=', 1)
                if k.strip() == key:
                    v = v.strip()
                    if v.lower() in ('true', 'false'):
                        return v.lower() == 'true'
                    if v.isdigit():
                        return int(v)
                    return v

    # 3. Check user config file
    config_path = Path.home() / '.cc_obsidian' / 'config.json'
    if config_path.exists():
        with open(config_path) as f:
            config = json.load(f)
            if key in config:
                return config[key]

    # 4. Return default
    return default

# Usage
api_key = get_config_value('apiKey')  # Checks all sources
api_url = get_config_value('apiUrl', 'https://localhost:27124')
allow_delete = get_config_value('allowDelete', False)
```
```

### Section 5: Error Handling

**Purpose**: Comprehensive error handling patterns

**Contents**:
- Connection errors (API unavailable)
- Authentication errors (invalid API key)
- Not found errors (file doesn't exist)
- Validation errors (malformed content)
- Conflict errors (file modified since read)
- Network timeouts

**Example Entry**:

```markdown
# Error Handling

## Error 1: API Unavailable (Connection Refused)

**Symptoms**:
- `requests.exceptions.ConnectionError`
- "Connection refused" or "Connection reset"

**Cause**: Obsidian Local REST API plugin not running

**Resolution**:
1. Check if Obsidian is running
2. Verify Local REST API plugin is enabled:
   - Settings → Community Plugins → Local REST API
3. Confirm correct port:
   - HTTPS: 27124 (default)
   - HTTP: 27123
4. Test: `curl -k -H "Authorization: Bearer $OBSIDIAN_SKILL_API_KEY" https://localhost:27124/`

**User Message**:
```
❌ Cannot connect to Obsidian Local REST API

Troubleshooting:
1. Is Obsidian running?
2. Is the Local REST API plugin enabled?
3. Check Settings → Community Plugins → Local REST API
4. Verify port: https://localhost:27124

Test connection:
curl -k -H "Authorization: Bearer $OBSIDIAN_SKILL_API_KEY" https://localhost:27124/
```

## Error 2: Authentication Failed (401 Unauthorized)

**Symptoms**:
- HTTP 401 status code
- "Unauthorized" or "Invalid API key"

**Cause**: Missing or incorrect API key

**Resolution**:
1. Check API key in Obsidian: Settings → Local REST API → Show API Key
2. Verify configuration (check all sources in order):
   - `echo $OBSIDIAN_SKILL_API_KEY`
   - `.env` file in project
   - `~/.cc_obsidian/config.json`
3. Regenerate API key if needed

**User Message**:
```
❌ API key authentication failed

Your API key may be missing or incorrect.

To fix:
1. Get your API key from Obsidian:
   Settings → Community Plugins → Local REST API → Show API Key

2. Set in one of these locations:
   - Environment variable: export OBSIDIAN_SKILL_API_KEY="your-key"
   - Project .env: apiKey=your-key
   - User config: ~/.cc_obsidian/config.json

Currently checking:
  - OBSIDIAN_SKILL_API_KEY env var: [not set]
  - .env file: [not found]
  - config.json: [not found]
```

[Continue with other error patterns...]
```

### Section 6: Obsidian Syntax & Conventions

**Purpose**: Preserve Obsidian-specific formatting

**Contents**:
- Path format rules
- Wikilink syntax
- Tag syntax
- Frontmatter format
- Callout syntax
- Block references
- Embeds

### Section 7: User Interaction Guidelines

**Purpose**: Define how the skill communicates with users

**Contents**:
- Tone and language (concise, technical, helpful)
- When to ask for clarification
- How to present options
- Progress indicators
- Success/failure messages
- When to abort operations

### Section 8: Context Optimization with Sub-Agents

**Purpose**: Define when and how to delegate tasks to general-purpose sub-agents for context efficiency

**Design Principles**:
- **Token Efficiency**: Offload file search, multi-file operations, and bulk tasks to sub-agents
- **Clear Delegation**: Specify exactly what the sub-agent should do and return
- **Skill Maintains Control**: Sub-agent handles search/discovery, skill handles API calls and confirmations

**Example Structure**:

```markdown
# Context Optimization Guidelines

## When to Use General-Purpose Sub-Agents

Use the `Task` tool with `subagent_type: general-purpose` for these scenarios:

### 1. File Discovery (Multiple Rounds of Search)
**Scenario**: User asks "Find all notes about project X" but you don't know exact file names
**Reason**: Searching vault may require multiple API calls, grepping results, filtering
**Solution**: Delegate to sub-agent
**Example**:
```python
# Instead of doing this yourself (uses your context):
# - Call /vault/ to list all files
# - Filter by pattern
# - Call GET on each file
# - Search content
# - Build results list

# Do this (uses sub-agent context):
Task(
    subagent_type="general-purpose",
    description="Search Obsidian vault for notes",
    prompt="""
    Search the Obsidian vault for all notes related to "project X".

    Steps:
    1. Use POST /search/simple/ endpoint with query "project X"
    2. Review results and extract relevant file paths
    3. Return a list of file paths that match

    API Config:
    - Base URL: {api_url}
    - Headers: Authorization: Bearer {api_key}
    - Verify: False (self-signed cert)

    Return format:
    {{
        "matching_files": ["path/to/note1.md", "path/to/note2.md"],
        "total_matches": 2
    }}
    """
)
```

### 2. Bulk Read Operations (>5 Files)
**Scenario**: User asks "Summarize all my meeting notes from last month"
**Reason**: Reading many files consumes your context window
**Solution**: Delegate reading and initial processing to sub-agent, get summary back
**Example**:
```python
Task(
    subagent_type="general-purpose",
    description="Read and summarize meeting notes",
    prompt="""
    Read all meeting notes from the following paths and create a summary:
    {file_paths}

    For each file:
    1. GET /vault/{{filename}} to read content
    2. Extract key points, decisions, and action items
    3. Aggregate into a single summary

    Return a structured summary with:
    - Total meetings: count
    - Key decisions: list
    - Action items: list
    - Notable topics: list

    API Config:
    - Base URL: {api_url}
    - Headers: Authorization: Bearer {api_key}
    - Verify: False
    """
)
```

### 3. Dataview Query Analysis
**Scenario**: User asks "What's the best Dataview query to find X?"
**Reason**: May require trial-and-error with different query syntax
**Solution**: Let sub-agent experiment with queries, return working query
**Example**:
```python
Task(
    subagent_type="general-purpose",
    description="Build Dataview query for task tracking",
    prompt="""
    Create a Dataview DQL query to find all incomplete tasks across the vault.

    1. Start with basic query
    2. Test using POST /search/ with Content-Type: application/vnd.olrapi.dataview.dql+txt
    3. Refine until it returns expected results
    4. Return the working query

    Return:
    {{
        "query": "the working DQL query",
        "example_results": "sample of what it returns"
    }}
    """
)
```

### 4. Complex File Analysis (Large Files)
**Scenario**: User asks "Analyze my entire research note (5000 lines) and extract insights"
**Reason**: Large file content would consume significant context
**Solution**: Sub-agent reads and processes, returns condensed insights
**Example**:
```python
Task(
    subagent_type="general-purpose",
    description="Analyze large research note",
    prompt="""
    Read the research note at: Research/quantum-computing.md

    1. GET /vault/Research/quantum-computing.md
    2. Analyze the content for:
       - Main themes and topics
       - Key findings or insights
       - Open questions or TODOs
       - Related concepts mentioned
    3. Return structured analysis (NOT the full content)

    Return condensed insights only, not the raw file content.
    """
)
```

## What NOT to Delegate

**DO NOT use sub-agents for**:
- ❌ Single file operations (just do it directly)
- ❌ Destructive operations (DELETE, PUT, PATCH replace) - skill must handle confirmations
- ❌ Configuration loading (skill handles this)
- ❌ Simple searches (<5 results expected)
- ❌ Operations requiring user confirmation (skill must show prompts)

## Sub-Agent Response Handling

When sub-agent returns, you (the skill) must:
1. **Validate results** - Check that sub-agent completed task successfully
2. **Apply guardrails** - If sub-agent found files to delete/modify, show confirmations
3. **Execute final operations** - Sub-agent does discovery, skill does API calls with safety checks
4. **Report to user** - Present results in user-friendly format

**Example Flow**:
```python
# User asks: "Delete all draft notes from 2023"

# Step 1: Delegate search to sub-agent
result = Task(
    subagent_type="general-purpose",
    description="Find draft notes from 2023",
    prompt="Search vault for files with 'draft' in name and created in 2023, return list of paths"
)

# Step 2: Skill validates and shows confirmation (NOT delegated)
draft_files = result['files']  # ['drafts/2023-01-01.md', 'drafts/2023-01-15.md']

print(f"Found {len(draft_files)} draft files from 2023:")
for f in draft_files:
    print(f"  - {f}")

# Step 3: Skill applies G1 + G2 guardrails (DELETE confirmation)
confirm = confirm_delete_batch(draft_files)  # Uses G1, G2

# Step 4: Skill executes DELETE (NOT delegated)
if confirm:
    for file_path in draft_files:
        delete_file(file_path)  # Skill executes with backups
```

## Token Budget Benefit

**Without sub-agent** (all in main context):
- List 100 files: ~2000 tokens
- Read 10 files: ~5000 tokens
- Process and filter: ~1000 tokens
- Total: ~8000 tokens consumed from main context

**With sub-agent** (offloaded):
- Task prompt: ~200 tokens
- Sub-agent result: ~500 tokens (summary only)
- Total: ~700 tokens consumed from main context

**Savings**: ~7300 tokens (10x reduction)
```

---

## SKILL.md YAML Frontmatter

```yaml
---
name: obsidian-vault
description: |
  Integrate with Obsidian vaults through the Local REST API plugin.

  Use this skill when the user wants to:
  - Search notes in their Obsidian vault
  - Read specific notes
  - Create new notes
  - Modify existing notes
  - Manage daily/periodic notes
  - Execute Dataview queries

  IMPORTANT: This skill performs destructive operations (create, modify, delete).
  Always follow safety rules and confirmation requirements.

  Activates when user mentions:
  - "Obsidian", "my vault", "my notes"
  - "daily note", "journal entry"
  - "search my notes", "find in Obsidian"
  - Creating, updating, or deleting notes

tools:
  - Bash    # For running curl commands and testing connectivity
  - Read    # For reading local config files
  - Write   # For creating backup files
---
```

**Key Points**:
- **name**: Lowercase, hyphenated identifier
- **description**: When to use this skill (activation triggers)
- **tools**: Only what's needed (Bash for API calls, Read/Write for config/backups)

---

## Testing & Validation

**Before Release**:
- [ ] YAML frontmatter parses correctly
- [ ] All 31 endpoints documented
- [ ] Safety rules are unambiguous
- [ ] Code examples are copy-paste ready
- [ ] Error messages are actionable
- [ ] Configuration examples work
- [ ] Path format rules are clear
- [ ] Token count under 10,000

**User Testing**:
- [ ] New users can set up from SKILL.md alone
- [ ] Destructive operations always prompt
- [ ] DELETE operations blocked when `allowDelete: false`
- [ ] Configuration loading works from all sources
- [ ] Error messages lead to successful resolution

---

## Implementation Plan

1. **Phase 1: Structure & Safety** (This ADR)
   - Define SKILL.md structure
   - Write safety rules section
   - Document configuration

2. **Phase 2: API Reference** (Next)
   - Document all 31 endpoints
   - Add risk indicators
   - Include key headers/params

3. **Phase 3: Patterns & Examples** (Next)
   - Write 5-10 operational patterns
   - Add error handling examples
   - Include confirmation prompts

4. **Phase 4: Polish & Optimize** (Final)
   - Token count optimization
   - User testing feedback
   - Final review

---

## Open Questions

1. **Q**: Should we include Dataview query examples?
   - **A**: Yes, but keep simple (1-2 examples max)

2. **Q**: How much Obsidian syntax detail?
   - **A**: Essentials only - wikilinks, tags, frontmatter, callouts

3. **Q**: Include troubleshooting flowchart?
   - **A**: No - takes too many tokens, use bullet lists instead

4. **Q**: Reference OpenAPI spec explicitly?
   - **A**: Yes - mention it exists for completeness, but don't rely on it

---

## Success Criteria

**SKILL.md is successful if**:
- ✅ Users can install and use without additional documentation
- ✅ No accidental data loss occurs in testing
- ✅ All safety rules are followed consistently
- ✅ Error messages resolve 90%+ of user issues
- ✅ Configuration works from all three sources
- ✅ Works identically on Claude Code and Claude Desktop

---

## Consequences

### Positive

✅ **Self-Contained**: SKILL.md is the single source of truth
✅ **Safety-First**: Explicit rules prevent data loss
✅ **Comprehensive**: Covers all 31 endpoints
✅ **Practical**: Code examples users can copy-paste
✅ **Maintainable**: Clear structure makes updates easy

### Negative

❌ **Token Heavy**: ~9,000 tokens is substantial
❌ **Repetition**: Safety rules repeated in multiple sections
❌ **Maintenance**: Updates need to propagate to multiple sections

### Mitigations

- Optimize wording to reduce tokens
- Accept some repetition for safety-critical rules
- Use clear section headers to simplify updates

---

## References

- ADR-001: Skill Architecture
- ADR-002: Destructive Operation Guardrails
- ADR-003: Automatic Backup System
- Claude Code Skills Documentation: https://docs.claude.com/docs/claude-code/skills
- Obsidian Local REST API: https://github.com/coddingtonbear/obsidian-local-rest-api
- OpenAPI Spec: `docs/openapi.yaml`

---

## Approval

**Status**: Draft
**Next Steps**:
1. Review this ADR structure and approach
2. Discuss any changes or concerns
3. Begin implementing SKILL.md following this design
4. Create first draft for review

**Decision Date**: TBD
**Approved By**: TBD
