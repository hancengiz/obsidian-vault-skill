# ADR-002: Destructive Operation Guardrails

**Status**: Proposed
**Date**: 2025-11-10
**Decision Makers**: Development Team
**Related**: ADR-001 (Skill Architecture)

---

## Context

The Obsidian Local REST API provides 17+ potentially destructive endpoints that can permanently delete files, overwrite content, or modify vault structure. Without proper guardrails, users could lose entire days of journal entries, accidentally delete notes, or corrupt their knowledge base through Claude's actions.

**See**: [`destructive-operation-list.md`](./destructive-operation-list.md) for the complete list of all destructive operations.

### Problem Statement

Users need protection against:
- **Accidental file deletion** via DELETE operations (4 endpoints)
- **Complete content overwrites** via PUT operations (4 endpoints)
- **Unintended section modifications** via PATCH replace operations (4 endpoints)
- **Bulk append operations** that clutter notes (4 endpoints)
- **Dangerous command execution** with unknown side effects (1+ endpoints)

**Note**: All endpoints, risk levels, and special cases are detailed in [`destructive-operation-list.md`](./destructive-operation-list.md).

### Key Risk: Periodic Notes Deletion

The most dangerous scenario: `DELETE /periodic/daily/` automatically calculates today's date and deletes that file. Calling this at 11 PM permanently deletes an entire day's work - all journal entries, tasks, notes, and reflections - in a single API call.

---

## Decision

**We will implement a Simplified Two-Tier Guardrail Strategy**:

### Tier 1: DELETE Permission Control
- **Config-based**: `allowDelete` (default: `false`)
- DELETE operations require explicit opt-in via config
- Even when enabled, DELETE **always requires confirmation** (never skippable)

### Tier 2: Mandatory Confirmations (Default)
- **All confirmations are mandatory by default**:
  - PUT operations (full file replacement)
  - PATCH replace operations (section replacement)
  - Bulk POST operations (>5 files)
  - Risky command execution
- **Environment variable override**: `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true`
  - Inspired by Claude Code's `--dangerously-skip-permissions`
  - Skips Tier 2 confirmations (but NOT DELETE, which is Tier 1)
  - Intended for CI/CD and automation only

**Rationale**: This approach provides maximum safety by default while allowing automation scenarios. DELETE is special-cased because it's irreversible.

---

## Configuration Schema

### Multi-Source Configuration System

The skill uses a **three-tier fallback system** for all configuration settings:

1. **Environment Variables** (Highest Priority) - with `OBSIDIAN_SKILL_` prefix
2. **Project `.env` File** (Second Priority) - without prefix
3. **User Config File** `~/.cc_obsidian/config.json` (Lowest Priority) - without prefix

### Configuration File Examples

**User Config File**: `~/.cc_obsidian/config.json`

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

**Project `.env` File**: `.env` (in project root)

```env
apiKey=your-api-key-here
apiUrl=https://localhost:27124
allowDelete=false
backupEnabled=true
backupDirectory=~/.cc_obsidian/backups
backupKeepLastN=5
DANGEROUSLY_SKIP_CONFIRMATIONS=false
```

**Environment Variables**: (with `OBSIDIAN_SKILL_` prefix)

```bash
export OBSIDIAN_SKILL_API_KEY="your-api-key-here"
export OBSIDIAN_SKILL_API_URL="https://localhost:27124"
export OBSIDIAN_SKILL_ALLOW_DELETE=false
export OBSIDIAN_SKILL_BACKUP_ENABLED=true
export OBSIDIAN_SKILL_BACKUP_DIRECTORY="~/.cc_obsidian/backups"
export OBSIDIAN_SKILL_BACKUP_KEEP_LAST_N=5
export OBSIDIAN_SKILL_DANGEROUSLY_SKIP_CONFIRMATIONS=false
```

### Configuration Settings Reference

| Setting | Env Var (with prefix) | Config/Env File (no prefix) | Type | Default | Description |
|---------|----------------------|----------------------------|------|---------|-------------|
| **API Key** | `OBSIDIAN_SKILL_API_KEY` | `apiKey` | string | *required* | API authentication token from Obsidian Local REST API plugin |
| **API URL** | `OBSIDIAN_SKILL_API_URL` | `apiUrl` | string | `https://localhost:27124` | Base URL for Obsidian Local REST API |
| **Allow DELETE** | `OBSIDIAN_SKILL_ALLOW_DELETE` | `allowDelete` | boolean | `false` | Enable DELETE operations - when `false`, DELETE is blocked entirely. When `true`, DELETE is allowed but **always** requires typing 'DELETE' to confirm |
| **Backup Enabled** | `OBSIDIAN_SKILL_BACKUP_ENABLED` | `backupEnabled` | boolean | `true` | Enable automatic backups before destructive operations (see ADR-003) |
| **Backup Directory** | `OBSIDIAN_SKILL_BACKUP_DIRECTORY` | `backupDirectory` | string | `~/.cc_obsidian/backups` | Directory where backups are stored |
| **Backup Keep Last N** | `OBSIDIAN_SKILL_BACKUP_KEEP_LAST_N` | `backupKeepLastN` | number | `5` | Number of backup copies to retain per file |
| **Skip Confirmations** | `OBSIDIAN_SKILL_DANGEROUSLY_SKIP_CONFIRMATIONS` | `DANGEROUSLY_SKIP_CONFIRMATIONS` | boolean | `false` | **DANGEROUS**: Skip all confirmation prompts except DELETE. Inspired by Claude Code's `--dangerously-skip-permissions`. Only use in CI/CD where you fully trust inputs. When `true`, confirmations are bypassed (except DELETE which still respects `allowDelete`). When `false` or unset, all confirmations are **mandatory**. |

### Configuration Loading Priority

**Example**: How `allowDelete` is resolved:

1. Check `OBSIDIAN_SKILL_ALLOW_DELETE` environment variable first
2. If not found, check `allowDelete` in `.env` file
3. If not found, check `allowDelete` in `~/.cc_obsidian/config.json`
4. If not found, use default value (`false`)

**Important Notes**:

- **Environment variables** require the `OBSIDIAN_SKILL_` prefix for namespacing
- **Config files** (`.env` and JSON) do NOT use the prefix
- `DANGEROUSLY_SKIP_CONFIRMATIONS` is intentionally ALL_CAPS in all formats to emphasize danger
- Confirmations are **always required by default** - the skip setting is only for automation scenarios

### Example Configurations

**Maximum Safety (Default)** - DELETE disabled, all confirmations required:
```json
{
  "allowDelete": false
}
```

**Power User** - DELETE enabled, all confirmations still required:
```json
{
  "allowDelete": true
}
```

**Automation/CI Mode (DANGEROUS - NOT RECOMMENDED)** - Skip confirmations for batch processing:
```bash
# Set environment variable to skip confirmations
export OBSIDIAN_SKILL_DANGEROUSLY_SKIP_CONFIRMATIONS=true

# Now run Claude Code in headless mode with the Obsidian skill
# DELETE operations still respect allowDelete config (never skipped)
# All other confirmations (PUT, PATCH replace, bulk) are bypassed

# Example: Batch update daily notes in CI/CD pipeline
OBSIDIAN_SKILL_DANGEROUSLY_SKIP_CONFIRMATIONS=true claude -p "Update all my daily notes from last week" --output-format json
```

---

## Detailed Design

### 1. DELETE Operations (Critical - Highest Risk)

**Rule**: Blocked by default, requires config opt-in, always requires confirmation

**📋 Managed by**: `allowDelete` in `~/.cc_obsidian/config.json`

**Behavior**:
- If `allowDelete: false` (default), skill refuses DELETE requests entirely
- If `allowDelete: true`, skill allows DELETE but **always requires explicit user confirmation** with preview
- Confirmation is **never skipped**, even when `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true`
- Show affected file path before deletion
- Special warning for current periodic notes (today's daily note, this week's weekly note, etc.)

**Affected Endpoints**:
- `DELETE /active/` - Deletes currently active file
- `DELETE /vault/{filename}` - Deletes specific file
- `DELETE /periodic/{period}/` - Deletes today's/this week's/this month's note
- `DELETE /periodic/{period}/{year}/{month}/{day}/` - Deletes historical periodic note

**Confirmation Template**:
```
⚠️  DESTRUCTIVE OPERATION - FILE DELETION

Operation: DELETE
Target: [file path or "active file: path/to/file.md"]
Current content: [first 200 chars or "X lines, Y words"]

⚠️  This operation CANNOT be undone.
⚠️  [Special warning if periodic note: "This is TODAY'S daily note with all of today's entries"]

Type 'DELETE' (in caps) to confirm, or 'cancel' to abort:
```

### 2. PUT Operations (High Risk - Content Overwrite)

**Rule**: Always require confirmation with file-exists check (mandatory by default)

**📋 Can be skipped by**: `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true` environment variable

**Behavior**:
- **Default**: Always show confirmation prompt
- Check if file exists before PUT
- If file exists: Show warning that ALL content will be replaced
- If creating new file: Proceed with simple confirmation
- Show content preview (first/last 100 chars) for existing files
- Suggest PATCH or POST as safer alternatives
- **Automation mode**: If environment variable is set to `true`, skip confirmation and proceed directly

**Affected Endpoints**:
- `PUT /active/` - Replaces all content in active file
- `PUT /vault/{filename}` - Creates new or replaces existing file
- `PUT /periodic/{period}/` - Replaces current periodic note content
- `PUT /periodic/{period}/{year}/{month}/{day}/` - Replaces historical periodic note

**Confirmation Template (File Exists)**:
```
⚠️  DESTRUCTIVE OPERATION - CONTENT REPLACEMENT

Operation: PUT (Replace All Content)
Target: path/to/file.md
Current size: 1,234 lines (12,456 words)
Current content preview:
  [First 100 chars...]
  ...
  [Last 100 chars...]

New content preview:
  [First 100 chars of new content...]

⚠️  ALL existing content will be PERMANENTLY LOST.

Alternatives:
  - Use POST to append content to the end
  - Use PATCH to modify specific sections

Type 'REPLACE' (in caps) to confirm, or 'cancel' to abort:
```

**Confirmation Template (New File)**:
```
Creating new file: path/to/file.md
Content preview: [First 200 chars...]

Confirm? (yes/no):
```

### 3. PATCH Operations (Medium Risk - Section Replacement)

**Rule**: Require confirmation when `Operation: replace` header is used (mandatory by default)

**📋 Can be skipped by**: `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true` environment variable

**Behavior**:
- If `Operation: append` or `prepend` → Safe, no confirmation needed (always allowed)
- If `Operation: replace` → **Default**: Show target section and require confirmation
- Validate target exists and is unique
- Show current section content before replacement
- Warn if target is ambiguous (e.g., multiple "Tasks" headings)
- **Automation mode**: If environment variable is set to `true`, skip confirmation for replace operations

**Affected Endpoints**:
- `PATCH /active/` - Modifies active file sections
- `PATCH /vault/{filename}` - Modifies specific file sections
- `PATCH /periodic/{period}/` - Modifies current periodic note sections
- `PATCH /periodic/{period}/{year}/{month}/{day}/` - Modifies historical periodic note sections

**Confirmation Template**:
```
⚠️  PARTIAL CONTENT REPLACEMENT

Operation: PATCH with Operation=replace
Target: heading "Tasks"
File: path/to/file.md

Current section content:
---
[Current content under "Tasks" heading]
---

New content:
---
[New content to replace section]
---

⚠️  This section will be completely replaced.

Type 'yes' to confirm, or 'no' to cancel:
```

**Safe Operations (No Confirmation)**:
- `Operation: append` - Adds content after target
- `Operation: prepend` - Adds content before target

### 4. POST Operations (Lower Risk - Append Only)

**Rule**: Confirm only for bulk operations (affecting >5 files, mandatory by default)

**📋 Can be skipped by**: `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true` environment variable

**Behavior**:
- Single file append → No confirmation needed (safe operation)
- Bulk operations (>5 files) → **Default**: Show list and require confirmation
- Show what will be appended and where
- **Automation mode**: If environment variable is set to `true`, skip bulk confirmation

**Affected Endpoints**:
- `POST /active/` - Appends to active file
- `POST /vault/{filename}` - Appends to specific file
- `POST /periodic/{period}/` - Appends to current periodic note
- `POST /periodic/{period}/{year}/{month}/{day}/` - Appends to historical periodic note

**Behavior**:
```
Single file: "Appending [X lines] to path/to/file.md"
Bulk: "Appending to 12 files. Confirm? (yes/no): [list of files]"
```

### 5. Command Execution (Context-Dependent Risk)

**Rule**: Analyze command before execution, warn if risky

**Behavior**:
- Use `GET /commands/` to retrieve command name and description
- Pattern match for dangerous keywords: "delete", "remove", "clear", "erase", "destroy"
- Always show command name and description before executing
- Require confirmation for any matched dangerous patterns

**Affected Endpoint**:
- `POST /commands/{commandId}/` - Executes Obsidian command

**Confirmation Template (Risky Command)**:
```
⚠️  POTENTIALLY DESTRUCTIVE COMMAND

Command: delete-current-file
Description: Delete the currently active file
Impact: Unknown (plugin-specific command)

⚠️  This command may be destructive.

Type 'yes' to execute, or 'no' to cancel:
```

**Confirmation Template (Safe Command)**:
```
Executing command: open-graph-view
Description: Open the graph view

Proceed? (yes/no):
```

---

## Edge Cases & Special Considerations

### 1. Active File Context

**Risk**: User may not know which file is currently open and focused in Obsidian, especially with multiple tabs/panes.

**Mitigation**:
- Always call `GET /active/` first to retrieve the active file path
- Display prominently: "Active file: Projects/meeting.md"
- Ask confirmation: "Is this the file you want to modify?"
- If user is unsure, abort and suggest they check Obsidian

**Example**:
```
The active file is: Projects/client-meeting-notes.md
Is this the file you want to delete? (yes/no):
```

### 2. Batch Operations

**Risk**: User asks to modify multiple files at once (e.g., "delete all notes in Archive folder").

**📋 Can be skipped by**: `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true` environment variable (except DELETE)

**Mitigation**:
- Show complete list of affected files
- Display count prominently: "This will affect 42 files"
- Require confirmation
- Consider max batch size limit (e.g., 50 files) with additional warning
- Option to execute one-by-one with individual confirmations

**Example**:
```
Batch operation: DELETE
Affects: 42 files in Archive/

Files to delete:
  1. Archive/old-note-1.md
  2. Archive/old-note-2.md
  ...
  42. Archive/old-note-42.md

⚠️  This will PERMANENTLY DELETE 42 files.

Type 'DELETE ALL' to confirm, or 'cancel' to abort:
```

### 3. Periodic Notes (Today vs Historical)

**Risk**: Deleting today's daily note loses current work. Deleting historical notes loses past records.

**Mitigation for Current Period**:
- Extra prominent warning: "⚠️⚠️⚠️ THIS IS TODAY'S DAILY NOTE"
- Show content preview (first 500 chars)
- Suggest alternatives: "Consider archiving instead of deleting"
- Require typing "DELETE TODAY" instead of just "yes"

**Mitigation for Historical**:
- Show date clearly: "This is your daily note from October 15, 2025"
- Show content preview
- Confirm date: "Are you sure you want to delete notes from October 15, 2025?"

**Example (Today)**:
```
⚠️⚠️⚠️  DELETING TODAY'S DAILY NOTE ⚠️⚠️⚠️

File: 2025-11-10.md (Today's daily note)
Created: Today at 6:00 AM
Modified: 5 minutes ago
Size: 3,456 words

Content preview:
---
# 2025-11-10 - Sunday

## Morning Review
- Finished project proposal
- Reviewed quarterly goals
...
---

⚠️  This contains ALL of today's journal entries, tasks, and notes.
⚠️  Consider archiving instead of deleting.

Type 'DELETE TODAY' (exactly) to confirm, or 'cancel' to abort:
```

### 4. Template/System Files

**Risk**: Accidentally modifying `.obsidian/` config files or template files could break Obsidian or templates.

**📋 Related to**: `backup.enabled` in config (automatic backups are created if enabled)
**Note**: System files get automatic backup before modification when `backup.enabled: true`

**Mitigation**:
- Detect paths starting with `.obsidian/`
- Extra warning: "⚠️ This is an Obsidian system file"
- Detect common template folder names: "Templates", "templates", "_templates"
- Extra warning: "⚠️ This appears to be a template file"
- Automatic backup created before modification (if `backup.enabled: true`)

**Example**:
```
⚠️  SYSTEM FILE WARNING

File: .obsidian/workspace.json
Type: Obsidian configuration file

Modifying this file may break Obsidian's functionality.

Recommendations:
  1. Automatic backup will be created (if backup.enabled: true)
  2. Close Obsidian before modifying
  3. Consider using Obsidian's settings UI instead

Do you want to proceed? (yes/no):
```

### 5. Large Files

**Risk**: Replacing large files (>1000 lines) with incorrect content is costly.

**📋 Can be skipped by**: `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true` environment variable

**Mitigation**:
- Detect large files (>1000 lines or >50KB)
- Extra warning: "⚠️ This is a large file (2,345 lines)"
- Require stronger confirmation
- Offer to create backup first: "Create backup before replacement?"
- Show more detailed preview (first + last 200 chars)

**Example**:
```
⚠️  LARGE FILE REPLACEMENT

File: Projects/research-notes.md
Size: 2,345 lines (45,678 words)

This is a LARGE file. Replacing it may result in significant data loss.

⚠️  Automatic backup will be created if backup.enabled: true in config

Options:
  1. Use PATCH to modify specific sections instead (safer)
  2. Proceed with replacement (backup created automatically)
  3. Cancel operation

What would you like to do? (patch/proceed/cancel):
```

### 6. Concurrent Access

**Risk**: File might be modified in Obsidian while Claude is operating on it.

**Mitigation**:
- Check file modification time before and after GET
- If changed, warn: "File was modified in Obsidian since read"
- Suggest re-reading file before making changes
- Consider adding etag-style conflict detection

### 7. Network/API Failures

**Risk**: API call fails midway through operation.

**Mitigation**:
- Never assume operation succeeded without checking response
- Verify with GET request after PUT/PATCH/POST
- Report failures clearly: "Operation may have failed. Checking..."
- Suggest manual verification in Obsidian

---

## Implementation Requirements

### Skill Instructions (SKILL.md)

The skill MUST include these explicit rules:

```markdown
## CRITICAL SAFETY RULES - NEVER SKIP

1. **DELETE Operations**:
   - Check config: if `allowDelete` is false, refuse operation
   - If enabled, ALWAYS require explicit user confirmation (use `force_confirm=True`)
   - Confirmation is NEVER skipped, even with `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true`
   - Show file path and content preview
   - Use confirmation template exactly as specified
   - Special handling for periodic notes (today's entries)

2. **PUT Operations**:
   - ALWAYS check if file exists first (GET request)
   - If exists: Show "ALL CONTENT WILL BE LOST" warning
   - Suggest safer alternatives (POST, PATCH)
   - Require explicit confirmation (use `force_confirm=False` - can be skipped with env var)
   - If creating new file: Simple confirmation only

3. **PATCH Replace Operations**:
   - If Operation=replace: Show current section content
   - Require confirmation with preview (use `force_confirm=False` - can be skipped with env var)
   - If Operation=append or prepend: Safe, proceed without confirmation

4. **Bulk Operations**:
   - Count affected files
   - If > 5 files: Show list and require confirmation (use `force_confirm=False` - can be skipped with env var)
   - Display prominent count

5. **Command Execution**:
   - GET command name/description first
   - Check for dangerous keywords
   - Require confirmation with command details (use `force_confirm=False` - can be skipped with env var)

6. **Active File Operations**:
   - GET /active/ first to show file path
   - Display: "Active file: path/to/file.md"
   - Confirm with user before proceeding

7. **Environment Variable Check**:
   - Always check `os.getenv('DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL')` at runtime
   - If set to 'true', skip confirmations where `force_confirm=False`
   - Log when confirmations are skipped for transparency

8. **User Abort**:
   - IMMEDIATELY stop if user says: "no", "cancel", "stop", "abort"
   - Never proceed after negative response
   - Acknowledge: "Operation cancelled"
```

### Code Implementation Pattern

```python
import os
import json
import requests
from typing import Optional, Any
from pathlib import Path

def get_config_value(key: str, default: Any = None) -> Any:
    """
    Load configuration value with fallback priority.

    Priority:
    1. Environment variable: OBSIDIAN_SKILL_{KEY_UPPER}
    2. Project .env file: {key}
    3. User config: ~/.cc_obsidian/config.json
    4. Default value

    Args:
        key: Configuration key (e.g., 'apiKey', 'allowDelete', 'DANGEROUSLY_SKIP_CONFIRMATIONS')
        default: Default value if not found

    Returns:
        Configuration value from highest priority source
    """
    # 1. Check environment variable with prefix
    env_key = f"OBSIDIAN_SKILL_{key.upper()}"
    env_value = os.getenv(env_key)
    if env_value is not None:
        # Convert string booleans to actual booleans
        if env_value.lower() in ('true', 'false'):
            return env_value.lower() == 'true'
        # Convert string numbers to integers
        if env_value.isdigit():
            return int(env_value)
        return env_value

    # 2. Check project .env file (without prefix)
    # Note: Implement proper .env parsing or use python-dotenv
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
                    # Convert booleans and numbers
                    if v.lower() in ('true', 'false'):
                        return v.lower() == 'true'
                    if v.isdigit():
                        return int(v)
                    return v

    # 3. Check user config file (without prefix)
    config_path = Path.home() / '.cc_obsidian' / 'config.json'
    if config_path.exists():
        with open(config_path) as f:
            config = json.load(f)
            if key in config:
                return config[key]

    # 4. Return default
    return default

def should_skip_confirmations() -> bool:
    """
    Check if confirmations should be skipped.

    Checks (in order):
    1. OBSIDIAN_SKILL_DANGEROUSLY_SKIP_CONFIRMATIONS env var
    2. DANGEROUSLY_SKIP_CONFIRMATIONS in .env file
    3. DANGEROUSLY_SKIP_CONFIRMATIONS in config.json

    Returns:
        True if any source is set to true
    """
    return get_config_value('DANGEROUSLY_SKIP_CONFIRMATIONS', False)

def is_delete_allowed() -> bool:
    """
    Check if DELETE operations are allowed.

    Checks (in order):
    1. OBSIDIAN_SKILL_ALLOW_DELETE env var
    2. allowDelete in .env file
    3. allowDelete in config.json

    Returns:
        True if DELETE operations are allowed (default: False)
    """
    return get_config_value('allowDelete', False)

def confirm_with_user(prompt: str, require_exact: Optional[str] = None, force_confirm: bool = False) -> bool:
    """
    Get confirmation from user.

    Args:
        prompt: Confirmation prompt to display
        require_exact: If set, user must type this exactly (case-sensitive)
        force_confirm: If True, always show confirmation (ignores DANGEROUSLY_SKIP_CONFIRMATIONS)

    Returns:
        True if confirmed, False otherwise
    """
    # Skip confirmation if env var is set AND force_confirm is False
    if not force_confirm and should_skip_confirmations():
        print("⚠️  Skipping confirmation (DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true)")
        return True

    print(prompt)
    response = input().strip()

    # Check for abort keywords
    if response.lower() in ["no", "cancel", "stop", "abort"]:
        print("❌ Operation cancelled")
        return False

    # Check exact match if required
    if require_exact:
        return response == require_exact

    return response.lower() in ["yes", "y"]

def delete_file_with_guardrails(file_path: str, api_url: str, headers: dict):
    """
    Delete file with guardrails.

    DELETE operations:
    1. Check if allowed (checks env var, .env, config.json)
    2. ALWAYS require confirmation (never skipped, even with DANGEROUSLY_SKIP_CONFIRMATIONS)
    """

    # Check if DELETE is allowed (uses multi-source config loading)
    if not is_delete_allowed():
        print("❌ DELETE operations are disabled.")
        print("To enable DELETE operations, set one of:")
        print("  - Environment variable: OBSIDIAN_SKILL_ALLOW_DELETE=true")
        print("  - In .env file: allowDelete=true")
        print("  - In ~/.cc_obsidian/config.json: \"allowDelete\": true")
        return False

    # Get file content for preview
    response = requests.get(
        f"{api_url}/vault/{file_path}",
        headers=headers,
        verify=False,
        timeout=10
    )

    if response.status_code == 200:
        content = response.text
        preview = content[:200] + "..." if len(content) > 200 else content
        word_count = len(content.split())
        line_count = len(content.splitlines())
    else:
        preview = "[Could not retrieve preview]"
        word_count = "unknown"
        line_count = "unknown"

    # Build confirmation prompt
    prompt = f"""
⚠️  DESTRUCTIVE OPERATION - FILE DELETION

Operation: DELETE
Target: {file_path}
Current size: {line_count} lines ({word_count} words)
Current content:
---
{preview}
---

⚠️  This operation CANNOT be undone.

Type 'DELETE' (in caps) to confirm, or 'cancel' to abort: """

    # Get confirmation - force_confirm=True means NEVER skip, even with env var
    if not confirm_with_user(prompt, require_exact="DELETE", force_confirm=True):
        return False

    # Execute deletion
    response = requests.delete(
        f"{api_url}/vault/{file_path}",
        headers=headers,
        verify=False,
        timeout=10
    )

    if response.status_code == 204:
        print(f"✅ File deleted: {file_path}")
        return True
    else:
        print(f"❌ Delete failed: {response.status_code}")
        print(f"Error: {response.text}")
        return False

def put_file_with_guardrails(file_path: str, new_content: str, api_url: str, headers: dict):
    """
    Replace file content with guardrails.

    PUT operations:
    1. Check if file exists
    2. Require confirmation (can be skipped with DANGEROUSLY_SKIP_CONFIRMATIONS from any config source)
    """

    # Check if file exists
    response = requests.get(
        f"{api_url}/vault/{file_path}",
        headers=headers,
        verify=False,
        timeout=10
    )

    file_exists = response.status_code == 200

    if file_exists:
        content = response.text
        preview_current = content[:100] + "..." if len(content) > 100 else content
        preview_new = new_content[:100] + "..." if len(new_content) > 100 else new_content

        prompt = f"""
⚠️  DESTRUCTIVE OPERATION - CONTENT REPLACEMENT

Operation: PUT (Replace All Content)
Target: {file_path}
Current size: {len(content.splitlines())} lines ({len(content.split())} words)

Current content preview:
---
{preview_current}
---

New content preview:
---
{preview_new}
---

⚠️  ALL existing content will be PERMANENTLY LOST.

Type 'REPLACE' (in caps) to confirm, or 'cancel' to abort: """

        # force_confirm=False means this CAN be skipped with env var
        if not confirm_with_user(prompt, require_exact="REPLACE", force_confirm=False):
            return False
    else:
        # Creating new file - simple confirmation
        preview_new = new_content[:200] + "..." if len(new_content) > 200 else new_content
        prompt = f"""
Creating new file: {file_path}
Content preview:
---
{preview_new}
---

Confirm? (yes/no): """

        if not confirm_with_user(prompt, force_confirm=False):
            return False

    # Execute PUT
    response = requests.put(
        f"{api_url}/vault/{file_path}",
        headers={**headers, 'Content-Type': 'text/markdown'},
        data=new_content,
        verify=False,
        timeout=10
    )

    if response.status_code in [200, 201, 204]:
        print(f"✅ File {'replaced' if file_exists else 'created'}: {file_path}")
        return True
    else:
        print(f"❌ PUT failed: {response.status_code}")
        print(f"Error: {response.text}")
        return False
```

---

## Testing Checklist

Before deployment, verify:

**Config-based Controls**:
- [ ] DELETE operations blocked when `allowDelete: false` (default)
- [ ] DELETE operations allowed when `allowDelete: true`

**DELETE Operations (Always Require Confirmation)**:
- [ ] DELETE always requires exact "DELETE" confirmation
- [ ] DELETE confirmation NEVER skipped, even with `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true`
- [ ] Special warning for today's periodic notes

**Standard Confirmations (Default Behavior)**:
- [ ] PUT operations detect existing files
- [ ] PUT operations show content preview and require "REPLACE"
- [ ] PATCH replace operations require confirmation
- [ ] PATCH append/prepend proceed without confirmation
- [ ] Bulk operations (>5 files) require confirmation
- [ ] Commands analyzed for dangerous keywords and require confirmation

**Environment Variable Bypass**:
- [ ] `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true` skips PUT confirmations
- [ ] `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true` skips PATCH replace confirmations
- [ ] `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true` skips bulk confirmations
- [ ] `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL=true` does NOT skip DELETE confirmations
- [ ] Confirmation skips are logged for transparency

**User Experience**:
- [ ] Active file path displayed before operations
- [ ] User can cancel with "no", "cancel", "stop"
- [ ] Large file warning (>1000 lines)
- [ ] System file warning (.obsidian/)
- [ ] Template file warning
- [ ] All error messages clear and actionable

---

## Consequences

### Positive

✅ **Maximum Safety**: Users protected from accidental data loss by default
✅ **User Control**: Power users can opt-in to destructive operations
✅ **Transparency**: Always show what will be affected before action
✅ **Flexibility**: Different confirmation levels for different risk levels
✅ **Education**: Users learn what operations are dangerous

### Negative

❌ **Friction**: Extra steps required for destructive operations
❌ **Tedious**: Multiple confirmations can be annoying for power users
❌ **Complexity**: More code to maintain and test
❌ **False Confidence**: Users might become complacent with confirmations

### Mitigations for Negatives

- `DANGEROUSLY_SKIP_CONFIRMATIONS_OBSIDIAN_SKILL` environment variable for automation/CI scenarios
- Clear, concise confirmation prompts (not walls of text)
- Smart defaults (safe operations like POST append, PATCH append/prepend don't need confirmation)
- DELETE still protected even in automation mode (two-tier design)

---

## Alternatives Considered

### Alternative 1: No Guardrails (Rejected)

**Description**: Trust Claude to always do the right thing.

**Rejected Because**:
- Too risky - one mistake loses data permanently
- Claude can misunderstand user intent
- API calls can have unexpected side effects
- No undo mechanism

### Alternative 2: Read-Only Mode (Rejected)

**Description**: Only allow GET operations, block all modifications.

**Rejected Because**:
- Defeats purpose of the skill (users want to modify vault)
- Too restrictive - users would disable it
- Doesn't support key use cases (journaling, note creation)

### Alternative 3: Transaction/Rollback System (Deferred)

**Description**: Create snapshots before operations, allow rollback.

**Deferred Because**:
- Complex to implement (requires snapshot storage)
- File system doesn't natively support transactions
- Obsidian vault might be in git (user's responsibility)
- Could be added in future version if needed

### Alternative 4: Dry-Run Only (Rejected)

**Description**: All operations are dry-run by default, execute requires explicit command.

**Rejected Because**:
- Two-step process for every operation is tedious
- State management between dry-run and execute is complex
- User might forget what they were doing between steps
- Hybrid approach (Option 2 in original proposal) provides better UX

---

## References

- ADR-001: Skill Architecture
- Destructive Operations List: `docs/destructive-operation-list.md`
- Obsidian Local REST API: https://github.com/coddingtonbear/obsidian-local-rest-api
- API Endpoints Documentation: `docs/api-endpoints.md`

---

## Approval

**Status**: Proposed
**Next Steps**:
1. Review with stakeholders
2. Prototype confirmation flow
3. Update SKILL.md with safety rules
4. Implement guardrails in skill code
5. Test thoroughly with checklist
6. Document in README for users

**Decision Date**: TBD
**Approved By**: TBD
