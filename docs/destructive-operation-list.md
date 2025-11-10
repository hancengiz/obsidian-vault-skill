# Destructive Operations Reference

This document lists all potentially destructive operations in the Obsidian Local REST API that require special handling, guardrails, and automatic backups.

---

## Overview

**Total Destructive Operations**: 17 endpoints across 5 categories

These operations can permanently delete files, overwrite content, or modify vault structure. All operations listed below trigger automatic backups (when enabled) and require user confirmation based on guardrail settings.

---

## Category 1: DELETE Operations (Critical - Highest Risk)

**Risk Level**: 🔴 **CRITICAL** - Permanent data loss

**Guardrail**: Blocked by default (`allowDelete: false`), requires explicit config opt-in

**Backup**: Always created before execution

### Endpoints

1. **`DELETE /active/`**
   - **Action**: Deletes the currently active file in Obsidian
   - **Risk**: User may not know which file is active
   - **Confirmation Required**: Must type 'DELETE' (exact match)

2. **`DELETE /vault/{filename}`**
   - **Action**: Deletes a specific file by path
   - **Risk**: Permanent file deletion
   - **Confirmation Required**: Must type 'DELETE' (exact match)

3. **`DELETE /periodic/{period}/`**
   - **Action**: Deletes the current period's note (today/this week/this month/this quarter/this year)
   - **Risk**: ⚠️⚠️⚠️ **EXTREME RISK** - Deleting today's daily note loses all of today's work
   - **Special Handling**: Extra prominent warning for current period notes
   - **Confirmation Required**: Must type 'DELETE TODAY' for current period

4. **`DELETE /periodic/{period}/{year}/{month}/{day}/`**
   - **Action**: Deletes a historical periodic note by specific date
   - **Risk**: Loss of historical records
   - **Confirmation Required**: Must type 'DELETE' (exact match)

---

## Category 2: PUT Operations (High Risk - Content Overwrite)

**Risk Level**: 🟠 **HIGH** - Complete content replacement

**Guardrail**: Controlled by `confirmPut` setting (independent of `allowDelete`)

**Backup**: Created when file exists (not for new file creation)

### Endpoints

5. **`PUT /active/`**
   - **Action**: Replaces ALL content in the currently active file
   - **Risk**: Original content completely lost, no append
   - **Confirmation Required**: Must type 'REPLACE' if file exists, 'yes' for new file

6. **`PUT /vault/{filename}`**
   - **Action**: Creates new file OR replaces existing file content entirely
   - **Risk**: If file exists, ALL content is overwritten
   - **Confirmation Required**: Must type 'REPLACE' if file exists, 'yes' for new file

7. **`PUT /periodic/{period}/`**
   - **Action**: Replaces ALL content in current period's note
   - **Risk**: Overwrites today's/this week's/this month's note entirely
   - **Confirmation Required**: Must type 'REPLACE' (exact match)

8. **`PUT /periodic/{period}/{year}/{month}/{day}/`**
   - **Action**: Replaces ALL content in historical periodic note
   - **Risk**: Loss of historical content
   - **Confirmation Required**: Must type 'REPLACE' (exact match)

---

## Category 3: PATCH Operations with `Operation: replace` (Medium Risk - Section Replacement)

**Risk Level**: 🟡 **MEDIUM** - Partial content replacement

**Guardrail**: Controlled by `confirmPatchReplace` setting (independent of `allowDelete`)

**Backup**: Created only when `Operation: replace` header is used (not for append/prepend)

**Safe Modes**: `Operation: append` and `Operation: prepend` do NOT require confirmation or backup

### Endpoints

9. **`PATCH /active/`** (with `Operation: replace`)
   - **Action**: Replaces a specific section in the active file
   - **Targets**: Heading, block reference (`^block-id`), or frontmatter field
   - **Risk**: Section content completely replaced
   - **Confirmation Required**: Must type 'yes'

10. **`PATCH /vault/{filename}`** (with `Operation: replace`)
    - **Action**: Replaces a specific section in a specific file
    - **Targets**: Heading (nested with `::` delimiter), block reference, or frontmatter field
    - **Risk**: Section content completely replaced
    - **Confirmation Required**: Must type 'yes'

11. **`PATCH /periodic/{period}/`** (with `Operation: replace`)
    - **Action**: Replaces a specific section in current period's note
    - **Targets**: Heading, block reference, or frontmatter field
    - **Risk**: Section in today's/this week's note replaced
    - **Confirmation Required**: Must type 'yes'

12. **`PATCH /periodic/{period}/{year}/{month}/{day}/`** (with `Operation: replace`)
    - **Action**: Replaces a specific section in historical periodic note
    - **Targets**: Heading, block reference, or frontmatter field
    - **Risk**: Section in historical note replaced
    - **Confirmation Required**: Must type 'yes'

---

## Category 4: POST Operations - Bulk Only (Lower Risk - Append)

**Risk Level**: 🟢 **LOW** (single file) / 🟡 **MEDIUM** (bulk operations)

**Guardrail**: Controlled by `confirmBulkOperations` setting (only for bulk, independent of `allowDelete`)

**Backup**: NOT created (append operations are additive, not destructive)

**Note**: Single file POST operations are safe and do not require confirmation

### Endpoints

13. **`POST /active/`**
    - **Action**: Appends content to the end of the active file
    - **Risk**: Low - only adds content, doesn't remove
    - **Confirmation Required**: Only if part of bulk operation (>5 files)

14. **`POST /vault/{filename}`**
    - **Action**: Appends content to the end of a specific file
    - **Risk**: Low - only adds content, doesn't remove
    - **Confirmation Required**: Only if part of bulk operation (>5 files)

15. **`POST /periodic/{period}/`**
    - **Action**: Appends content to the end of current period's note
    - **Risk**: Low - only adds content, doesn't remove
    - **Confirmation Required**: Only if part of bulk operation (>5 files)

16. **`POST /periodic/{period}/{year}/{month}/{day}/`**
    - **Action**: Appends content to the end of historical periodic note
    - **Risk**: Low - only adds content, doesn't remove
    - **Confirmation Required**: Only if part of bulk operation (>5 files)

---

## Category 5: Command Execution (Context-Dependent Risk)

**Risk Level**: 🟠 **VARIABLE** - Depends on the command

**Guardrail**: Command analysis with keyword detection

**Backup**: Depends on what the command does (cannot predict)

### Endpoint

17. **`POST /commands/{commandId}/`**
    - **Action**: Executes an Obsidian command (plugin or core)
    - **Risk**: Unknown - depends entirely on the command
    - **Dangerous Patterns**: Commands containing "delete", "remove", "clear", "erase", "destroy"
    - **Confirmation Required**: Always show command name/description, require 'yes' for dangerous patterns

---

## Special Cases & Warnings

### Current Periodic Notes (Today/This Week/This Month)

**EXTREME RISK**: Operations on current period notes are especially dangerous:

- `DELETE /periodic/daily/` at 11 PM → Deletes today's entire daily note
- `PUT /periodic/weekly/` → Replaces this week's entire note
- `PATCH /periodic/monthly/` with `Operation: replace` → Replaces section in this month's note

**Special Handling**:
- Extra prominent warnings: ⚠️⚠️⚠️
- Show content preview (first 500 chars minimum)
- Require typing "DELETE TODAY" instead of just "DELETE"
- Suggest alternatives (archiving instead of deleting)

### Batch/Bulk Operations

**Definition**: Operations affecting more than `bulkThreshold` files (default: 5)

**Examples**:
- "Delete all notes in Archive folder" → Multiple DELETE operations
- "Update frontmatter in all notes tagged #project" → Multiple PUT/PATCH operations

**Requirements**:
- Show complete list of affected files
- Display count prominently: "This will affect 42 files"
- Require confirmation even if individual operations wouldn't
- Consider max batch size limit (e.g., 50 files) with extra warning

### System and Template Files

**High Risk Paths**:
- `.obsidian/` folder → Obsidian configuration files
- `Templates/`, `templates/`, `_templates/` → Template files

**Special Handling**:
- Extra warning: "⚠️ This is an Obsidian system file"
- Suggest creating backup first
- Recommend using Obsidian's settings UI instead (for .obsidian files)

### Large Files

**Definition**: Files >1000 lines or >50KB

**Special Handling**:
- Extra warning: "⚠️ This is a large file (2,345 lines)"
- Show more detailed preview (first + last 200 chars)
- Offer to create backup first
- Suggest PATCH for targeted modifications instead of PUT

---

## Operations That Do NOT Require Confirmation

### Safe GET Operations (Read-Only)

- `GET /active/` - Read active file
- `GET /vault/` - List vault contents
- `GET /vault/{filename}` - Read specific file
- `GET /periodic/{period}/` - Read current periodic note
- `GET /periodic/{period}/{year}/{month}/{day}/` - Read historical periodic note
- All search operations (simple, Dataview, JsonLogic)
- `GET /commands/` - List available commands

### Safe POST Operations (Append - Single File)

- Single file POST operations are additive and safe
- Only bulk POST operations (>5 files) require confirmation

### Safe PATCH Operations (Append/Prepend)

- `PATCH` with `Operation: append` - Adds content after target
- `PATCH` with `Operation: prepend` - Adds content before target
- These are additive and do not require confirmation

---

## Quick Reference Table

| Operation | Risk Level | Default Behavior | Confirmation Required | Backup Created |
|-----------|------------|------------------|----------------------|----------------|
| `DELETE /active/` | 🔴 Critical | Blocked | Type 'DELETE' | Yes |
| `DELETE /vault/{filename}` | 🔴 Critical | Blocked | Type 'DELETE' | Yes |
| `DELETE /periodic/{period}/` | 🔴 Critical | Blocked | Type 'DELETE TODAY' | Yes |
| `DELETE /periodic/{period}/{date}` | 🔴 Critical | Blocked | Type 'DELETE' | Yes |
| `PUT /active/` | 🟠 High | Allowed | Type 'REPLACE' | Yes (if exists) |
| `PUT /vault/{filename}` | 🟠 High | Allowed | Type 'REPLACE' | Yes (if exists) |
| `PUT /periodic/{period}/` | 🟠 High | Allowed | Type 'REPLACE' | Yes |
| `PUT /periodic/{period}/{date}` | 🟠 High | Allowed | Type 'REPLACE' | Yes |
| `PATCH /active/` (replace) | 🟡 Medium | Allowed | Type 'yes' | Yes |
| `PATCH /vault/{filename}` (replace) | 🟡 Medium | Allowed | Type 'yes' | Yes |
| `PATCH /periodic/{period}/` (replace) | 🟡 Medium | Allowed | Type 'yes' | Yes |
| `PATCH /periodic/{period}/{date}` (replace) | 🟡 Medium | Allowed | Type 'yes' | Yes |
| `POST` (bulk >5 files) | 🟡 Medium | Allowed | Type 'yes' | No |
| `POST` (single file) | 🟢 Low | Allowed | None | No |
| `POST /commands/{id}` (dangerous) | 🟠 Variable | Allowed | Type 'yes' | Unknown |
| `POST /commands/{id}` (safe) | 🟢 Low | Allowed | Type 'yes' | No |

---

## Usage in SKILL.md

When creating the `SKILL.md` file, copy this list to inform Claude about:

1. **Which operations are destructive** and require extra care
2. **What confirmation templates to use** for each operation type
3. **When to create backups** automatically
4. **Special cases** that need extra warnings (current periodic notes, system files, large files)
5. **Safe operations** that can proceed without confirmation

This ensures Claude always handles Obsidian vault operations safely and prevents accidental data loss.

---

## References

- **ADR-002**: Destructive Operation Guardrails
- **ADR-003**: Automatic Backup System
- **ADR-004**: SKILL.md Design and Structure
- **API Endpoints Documentation**: `docs/api-endpoints.md`
- **Obsidian Local REST API**: https://github.com/coddingtonbear/obsidian-local-rest-api
