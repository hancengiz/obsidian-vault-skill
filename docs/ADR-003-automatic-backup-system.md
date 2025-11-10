# ADR-003: Automatic Backup System for Destructive Operations

**Status**: Proposed
**Date**: 2025-11-10
**Decision Makers**: Development Team
**Related**: ADR-002 (Destructive Operation Guardrails)

---

## Context

When users enable destructive operations (DELETE, PUT, PATCH replace), there's still risk of accidental data loss even with confirmation prompts. Users may:
- Confirm operations too quickly without reading carefully
- Make mistakes in understanding what will be changed
- Realize later they needed the original content

Currently, once a destructive operation executes, there's no way to recover the original content unless:
- The user has their vault in git (manual recovery)
- Obsidian's sync creates cloud backups (not immediate, requires subscription)
- The user manually creates backups (rarely done)

### Problem Statement

We need a simple safety net that:
- Creates backups before destructive operations
- Works even when guardrails are disabled
- Doesn't require user action
- Makes recovery simple
- Doesn't consume excessive disk space

---

## Decision

**We will implement a Simple File-Based Backup System** that:

1. **Copies files before destructive operations** to `~/.cc_obsidian/backups/`
2. **Uses simple naming**: `{filename}.{timestamp}.backup`
3. **Keeps last N backups per file** (default: 5 most recent)
4. **Automatic cleanup**: Deletes oldest backups when limit exceeded

**No metadata, no sessions, no compression, no diffs** - just simple file copies.

---

## Detailed Design

### Backup Directory Structure

```
~/.cc_obsidian/
├── config.json
└── backups/
    ├── Projects_meeting-notes.md.2025-11-10_143052.backup
    ├── Projects_meeting-notes.md.2025-11-10_150234.backup
    ├── Projects_meeting-notes.md.2025-11-09_091523.backup
    ├── daily_2025-11-10.md.2025-11-10_140000.backup
    └── ...
```

### Backup Naming Convention

**Format**: `{safe-filename}.{timestamp}.backup`

- **safe-filename**: Original path with `/` replaced by `_`
  - Example: `Projects/meeting-notes.md` → `Projects_meeting-notes.md`
- **timestamp**: `YYYY-MM-DD_HHMMSS` (sortable, readable)
  - Example: `2025-11-10_143052`
- **extension**: `.backup`

**Full Example**: `Projects_meeting-notes.md.2025-11-10_143052.backup`

### Operations That Trigger Backups

**See**: [`destructive-operation-list.md`](./destructive-operation-list.md) for the complete list.

**Backed up before execution**:
1. All DELETE operations (4 endpoints)
2. All PUT operations when file exists (4 endpoints)
3. All PATCH operations with `Operation: replace` (4 endpoints)

**Not backed up** (safe operations):
- GET operations (read-only)
- POST operations (append-only)
- PATCH with `Operation: append` or `prepend`

---

## Configuration

**File**: `~/.cc_obsidian/config.json`

```json
{
  "apiKey": "your-api-key-here",
  "apiUrl": "https://localhost:27124",

  "backup": {
    "enabled": true,
    "directory": "~/.cc_obsidian/backups",
    "keepLastN": 5
  }
}
```

### Configuration Options

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `backup.enabled` | boolean | `true` | Enable/disable automatic backups |
| `backup.directory` | string | `~/.cc_obsidian/backups` | Backup storage location |
| `backup.keepLastN` | number | `5` | Keep last N backups per file (0 = keep all) |

---

## Implementation

### Backup Creation

```python
import os
from datetime import datetime
from pathlib import Path

def create_backup(file_path: str, content: str, config: dict) -> bool:
    """
    Create a simple backup of file content

    Args:
        file_path: Vault path (e.g., "Projects/meeting-notes.md")
        content: Current file content to backup
        config: Configuration dictionary

    Returns:
        True if backup created successfully
    """

    # Check if backups enabled
    if not config.get("backup", {}).get("enabled", True):
        return True  # Disabled, but don't block operation

    # Get backup directory
    backup_dir = Path(config.get("backup", {}).get("directory", "~/.cc_obsidian/backups"))
    backup_dir = backup_dir.expanduser()
    backup_dir.mkdir(parents=True, exist_ok=True)

    # Create backup filename
    safe_filename = file_path.replace("/", "_")
    timestamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    backup_filename = f"{safe_filename}.{timestamp}.backup"
    backup_file = backup_dir / backup_filename

    # Write backup
    try:
        with open(backup_file, "w", encoding="utf-8") as f:
            f.write(content)

        # Cleanup old backups for this file
        cleanup_old_backups(safe_filename, config)

        return True
    except Exception as e:
        print(f"⚠️  Backup failed: {e}")
        # Don't block the operation if backup fails
        return True


def cleanup_old_backups(safe_filename: str, config: dict):
    """
    Keep only last N backups for a specific file

    Args:
        safe_filename: The safe filename (with underscores)
        config: Configuration dictionary
    """

    keep_last_n = config.get("backup", {}).get("keepLastN", 5)

    if keep_last_n == 0:
        return  # Keep all backups

    backup_dir = Path(config.get("backup", {}).get("directory", "~/.cc_obsidian/backups"))
    backup_dir = backup_dir.expanduser()

    # Find all backups for this file
    pattern = f"{safe_filename}.*.backup"
    backups = sorted(backup_dir.glob(pattern), key=lambda p: p.name)

    # Delete oldest backups if we have more than keepLastN
    if len(backups) > keep_last_n:
        for old_backup in backups[:-keep_last_n]:
            old_backup.unlink()
```

### Integration with Destructive Operations

```python
def execute_destructive_operation(operation: str, target: str, new_content=None):
    """
    Execute destructive operation with automatic backup

    Flow:
    1. Get current file content
    2. Create backup (if enabled)
    3. Execute operation
    4. Return result
    """

    config = load_config()

    # Step 1: Get current content (for DELETE, PUT, PATCH replace)
    current_content = get_file_content(target)

    if current_content is None:
        print(f"⚠️  Cannot backup: file not found: {target}")
        # For DELETE operations on non-existent files, that's expected
        # For PUT/PATCH, continue anyway (creating new file)
    else:
        # Step 2: Create backup
        create_backup(target, current_content, config)

    # Step 3: Execute operation
    success = execute_api_call(operation, target, new_content)

    if success:
        print(f"✅ Operation successful")
    else:
        print(f"❌ Operation failed")

    return success
```

### Recovery

Recovery is manual - users browse `~/.cc_obsidian/backups/` and copy back the file they need.

**Example**:
```bash
# List backups for a specific file
ls ~/.cc_obsidian/backups/Projects_meeting-notes.md.*.backup

# View a backup
cat ~/.cc_obsidian/backups/Projects_meeting-notes.md.2025-11-10_143052.backup

# Restore manually via Obsidian (copy content) or:
# Copy backup back to vault (requires manual paste into Obsidian)
```

---

## Testing Checklist

- [ ] Backup directory created automatically
- [ ] Backup created before DELETE operation
- [ ] Backup created before PUT operation (file exists)
- [ ] Backup created before PATCH replace operation
- [ ] No backup for POST operations
- [ ] Backup filename format correct
- [ ] Old backups cleaned up (keeps last N)
- [ ] Backup works when enabled
- [ ] Operations work when backup disabled
- [ ] Backup failure doesn't block operations

---

## Consequences

### Positive

✅ **Simple**: Easy to understand and implement
✅ **Automatic**: Works without user intervention
✅ **Space Efficient**: Only keeps last N backups per file
✅ **No Complexity**: No metadata, sessions, or compression
✅ **Manual Recovery**: Users can just copy files back

### Negative

❌ **Manual Recovery**: No automatic restore command
❌ **No Metadata**: Can't see operation type or timestamp in backup
❌ **No Diff**: Can't see what changed
❌ **Filename Conflicts**: Multiple files with same name from different folders share backups

### Mitigations

- Simple is better than complex for this use case
- Users can use `ls -lt` to see backups sorted by time
- Filename conflicts rare (use full path with underscores)
- Git or Obsidian sync provides more sophisticated backup if needed

---

## Alternatives Considered

### Alternative 1: Complex Session-Based System (Rejected)

**Rejected Because**: Over-engineered for the use case. Session directories, metadata files, diff files, compression, and recovery commands add unnecessary complexity.

### Alternative 2: No Backups (Rejected)

**Rejected Because**: Guardrails alone may not be enough. Simple backups provide a safety net without much cost.

### Alternative 3: Git Integration (Rejected)

**Rejected Because**: Assumes user has git configured. Not all users want or need version control.

---

## References

- ADR-002: Destructive Operation Guardrails
- ADR-001: Skill Architecture
- Destructive Operations List: `docs/destructive-operation-list.md`

---

## Approval

**Status**: Proposed
**Next Steps**:
1. Review with team
2. Implement simple backup in SKILL.md
3. Test with checklist
4. Document in README

**Decision Date**: TBD
**Approved By**: TBD
