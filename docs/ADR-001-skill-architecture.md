# Obsidian Skill Design Document

## Project Overview

**Project Name**: Obsidian Vault Integration Skill for Claude Code
**Purpose**: Enable Claude Code and Claude Desktop to interact with Obsidian vaults through natural language
**Target Platforms**: Claude Code (CLI) and Claude Desktop
**Version**: 1.0

---

## Design Decisions

### 1. Integration Method: Local REST API

**Decision**: Use Obsidian Local REST API plugin (Option B)

**Rationale**:
- Building a skill to connect to Obsidian, so using MCP would be redundant (skill IS the integration layer)
- REST API plugin has widespread adoption and proven reliability
- Well-documented OpenAPI specification (2080 lines, 31 endpoints)
- Standard HTTP/HTTPS protocol works universally
- Extensive feature set: Dataview, commands, periodic notes, PATCH operations

**Alternative Considered**: CLI tools exist but reliability is uncertain compared to the widely-used REST API plugin

**Future Extension Point**: Document CLI option as alternative integration method for users who prefer it

---

### 2. Configuration System

**Decision**: Multi-tier fallback configuration system with environment variable prefix

#### Configuration Priority (in order):

1. **Environment Variables** (Highest Priority)
   - **Prefix**: `OBSIDIAN_SKILL_` for all variables
   - Available settings:
     - `OBSIDIAN_SKILL_API_KEY` - API authentication token
     - `OBSIDIAN_SKILL_API_URL` - Base URL (default: `https://localhost:27124`)
     - `OBSIDIAN_SKILL_ALLOW_DELETE` - Enable DELETE operations (default: `false`)
     - `OBSIDIAN_SKILL_BACKUP_ENABLED` - Enable automatic backups (default: `true`)
     - `OBSIDIAN_SKILL_BACKUP_DIRECTORY` - Backup storage location (default: `~/.cc_obsidian/backups`)
     - `OBSIDIAN_SKILL_BACKUP_KEEP_LAST_N` - Number of backups to retain (default: `5`)
     - `OBSIDIAN_SKILL_DANGEROUSLY_SKIP_CONFIRMATIONS` - Skip all confirmations except DELETE (default: `false`)
   - **Rationale**: Secure, follows Claude Code best practices, system-wide availability, clear namespace

2. **Project-level .env File** (Second Priority)
   - Look for `.env` in project root
   - **No prefix required** in .env file
   - Available settings (same as environment variables but without prefix):
     - `apiKey`
     - `apiUrl`
     - `allowDelete`
     - `backupEnabled`
     - `backupDirectory`
     - `backupKeepLastN`
     - `DANGEROUSLY_SKIP_CONFIRMATIONS` (all-caps to emphasize danger)
   - **Rationale**: Project-specific configuration, useful for project-scoped Obsidian integration

3. **User Home Config** (Lowest Priority)
   - Look for `~/.cc_obsidian/config.json`
   - **No prefix required** in JSON file
   - JSON format with all settings:
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
   - **Rationale**: User-level defaults, works across all projects

#### Configuration Loading Logic

```python
def get_config_value(key: str, default: Any = None) -> Any:
    """
    Load configuration value with fallback priority.

    Args:
        key: Configuration key (without prefix, e.g., 'apiKey', 'allowDelete')
        default: Default value if not found

    Returns:
        Configuration value from highest priority source
    """
    # 1. Check environment variable with prefix
    env_key = f"OBSIDIAN_SKILL_{key.upper()}"
    if env_key in os.environ:
        return os.environ[env_key]

    # 2. Check project .env file (without prefix)
    if dotenv_exists('.env'):
        dotenv_value = load_from_dotenv(key)
        if dotenv_value is not None:
            return dotenv_value

    # 3. Check user config file (without prefix)
    config_path = os.path.expanduser('~/.cc_obsidian/config.json')
    if os.path.exists(config_path):
        with open(config_path) as f:
            config = json.load(f)
            if key in config:
                return config[key]

    # 4. Return default
    return default
```

#### Special Case: DANGEROUSLY_SKIP_CONFIRMATIONS

This setting is intentionally named in ALL_CAPS across all formats to emphasize its dangerous nature:

- **Env var**: `OBSIDIAN_SKILL_DANGEROUSLY_SKIP_CONFIRMATIONS`
- **.env file**: `DANGEROUSLY_SKIP_CONFIRMATIONS`
- **JSON file**: `"DANGEROUSLY_SKIP_CONFIRMATIONS": false`

**Rationale**: Visual warning that this setting bypasses safety mechanisms

#### Endpoint Support

**Decision**: Support both HTTP and HTTPS

- Default HTTPS: `https://localhost:27124` (recommended)
- Default HTTP: `http://localhost:27123` (fallback)
- **Rationale**: User chooses based on their setup; HTTPS is more secure but uses self-signed certs

---

### 3. Feature Scope: Full API Coverage

**Decision**: Implement ALL capabilities exposed by the Local REST API

#### Comprehensive Feature Set:

##### File Operations
- ✅ Read notes (GET)
- ✅ Create notes (PUT)
- ✅ Update notes (PUT for replace, POST for append)
- ✅ Delete notes (DELETE)
- ✅ List vault contents (directories and files)

##### Advanced Note Manipulation
- ✅ PATCH operations (surgical updates)
  - By heading (nested with `::` delimiter)
  - By block reference (`^block-id`)
  - By frontmatter field
  - Append/prepend/replace modes
  - Table row manipulation
- ✅ Frontmatter operations (read/modify YAML)
- ✅ Get metadata (JSON mode with parsed tags, frontmatter, stats)

##### Search & Discovery
- ✅ Simple text search with context
- ✅ Dataview DQL queries
- ✅ JsonLogic queries with custom operators (glob, regexp)
- ✅ Search by tags
- ✅ Search by frontmatter

##### Periodic Notes
- ✅ Daily notes
- ✅ Weekly notes
- ✅ Monthly notes
- ✅ Quarterly notes
- ✅ Yearly notes
- ✅ Access specific dates (not just "today")

##### Obsidian Integration
- ✅ Execute Obsidian commands
- ✅ Open files in UI
- ✅ Work with active file

**Rationale**:
- Use OpenAPI document as source of truth
- Provide complete feature parity with the API
- Enable advanced workflows without artificial limitations

---

### 4. Safety & Confirmation

**Decision**: ALWAYS require explicit user confirmation for destructive operations

**Critical Safety Rules** (Non-negotiable):
- ✅ **Creating new notes**: Ask for confirmation
- ✅ **Modifying existing notes**: Ask for confirmation
- ✅ **Deleting notes**: Ask for confirmation
- ✅ **All destructive operations**: Ask for confirmation

**Implementation Requirements**:
- Rule must be SUPER STRICT and not skippable
- Skill must understand this is absolute
- Provide preview of changes before execution
- Clear, explicit confirmation prompts

**Rationale**: Prevent accidental data loss or corruption in user's knowledge base

---

### 5. File Type Support

**Decision**: Markdown files only (for now)

**Supported**: `.md` files
**Not Supported**: `.canvas`, other file types

**Rationale**:
- Focus on core use case (markdown notes)
- Simplifies initial implementation
- Matches most common Obsidian usage

**Future Extension Point**: Add canvas and other file type support based on user demand

---

### 6. Vault Access

**Decision**: Full vault access

**Rationale**:
- Depends on what REST API exposes (API is the gatekeeper)
- User controls access via API plugin configuration in Obsidian
- No artificial skill-level restrictions

**Note**: Skill should respect `.obsidian` folder convention (system files) but won't enforce hard restrictions

---

### 7. Template Support

**Decision**: Best-effort template detection and usage

**Behavior**:
- When creating a file in a specific folder, check for template
- Read template and generate file based on template structure
- Ask user during file creation about template usage

**Rationale**: Leverage existing Obsidian template workflows without requiring configuration

---

### 8. Periodic Notes Configuration

**Decision**: Research and use Obsidian's default periodic notes plugin behavior

**Action Items**:
- ⚠️ **TODO**: Web search to find Obsidian's default periodic notes plugin configuration
- ⚠️ **TODO**: Confirm default behaviors (format, location, naming)
- ⚠️ **TODO**: Implement matching behavior in skill

**Rationale**: Match user expectations by following Obsidian conventions

---

### 9. Automatic Note Enhancements

**Decision**: Ask user, but default to Obsidian desktop client behavior

**Features to Consider**:
- Generate frontmatter for new notes?
- Add tags automatically based on content?
- Create backlinks/references?
- Apply naming conventions?

**Action Items**:
- ⚠️ **TODO**: Web search to find Obsidian desktop client default behaviors
- ⚠️ **TODO**: Implement matching defaults
- ⚠️ **TODO**: Provide user override options

**Rationale**: Consistency with native Obsidian experience

---

### 10. Platform Support

**Decision**: Support both Claude Code (CLI) and Claude Desktop

**Claude Code Installation**:
- No zip file required
- Install script copies skill to appropriate directory
- Project-level: `.claude/skills/` or similar
- User-level: `~/.claude/skills/` or similar

**Claude Desktop Installation**:
- Requires zip file for skill registration
- Package skill with all dependencies
- Follow Claude Desktop skill packaging format

**Action Items**:
- ⚠️ **TODO**: Create install script for Claude Code
- ⚠️ **TODO**: Create packaging script for Claude Desktop zip
- ⚠️ **TODO**: Document both installation methods

**Rationale**: Maximize accessibility across both platforms

---

## Technical Architecture

### API Communication

```
Claude Code/Desktop
      │
      ├─ Configuration Loader
      │   ├─ 1. Check environment variables (OBSIDIAN_SKILL_* prefix)
      │   │   ├─ OBSIDIAN_SKILL_API_KEY
      │   │   ├─ OBSIDIAN_SKILL_API_URL
      │   │   ├─ OBSIDIAN_SKILL_ALLOW_DELETE
      │   │   ├─ OBSIDIAN_SKILL_BACKUP_ENABLED
      │   │   ├─ OBSIDIAN_SKILL_BACKUP_DIRECTORY
      │   │   ├─ OBSIDIAN_SKILL_BACKUP_KEEP_LAST_N
      │   │   └─ OBSIDIAN_SKILL_DANGEROUSLY_SKIP_CONFIRMATIONS
      │   │
      │   ├─ 2. Check project .env file (no prefix)
      │   │   └─ apiKey, apiUrl, allowDelete, backupEnabled, etc.
      │   │
      │   └─ 3. Check ~/.cc_obsidian/config.json (no prefix)
      │       └─ Same keys as .env file
      │
      ├─ REST API Client
      │   ├─ Base URL: http(s)://localhost:27123/27124
      │   ├─ Auth: Bearer token
      │   └─ Timeout: 10s, verify=False for HTTPS
      │
      └─ Obsidian Operations
          ├─ File CRUD
          ├─ PATCH operations
          ├─ Search (simple/Dataview/JsonLogic)
          ├─ Periodic notes
          └─ Commands
```

### Error Handling

**Strategy**: Fail fast with clear, actionable error messages

1. **API Unavailable** (Critical):
   - **Message**: "Obsidian Local REST API is not available"
   - **Action**: Stop immediately, do not retry
   - **Troubleshooting**:
     - Check if Obsidian is running
     - Verify Local REST API plugin is enabled
     - Confirm correct port (27123/27124)
     - Test: `curl -H "Authorization: Bearer $OBSIDIAN_API_KEY" https://localhost:27124/`

2. **Authentication Errors**:
   - **Message**: "API key authentication failed"
   - **Action**: Verify API key configuration
   - **Troubleshooting**:
     - Check environment variable: `echo $OBSIDIAN_API_KEY`
     - Verify key in Obsidian: Settings → Community Plugins → Local REST API
     - Regenerate key if needed

3. **Not Found Errors**:
   - **Message**: "Note not found: {path}"
   - **Action**: Validate path format
   - **Troubleshooting**:
     - Check path format: `folder/note.md` (no leading slash)
     - Verify note exists in vault
     - Ensure `.md` extension included

4. **Validation Errors** (New):
   - **Message**: "Note validation failed: {details}"
   - **Details**: Line number, error description, suggested fix
   - **Action**: Option to write anyway (with confirmation)

5. **Operational Errors**:
   - Provide clear context
   - Suggest troubleshooting steps
   - Never fail silently

---

## Path Format Standards

**Critical Rules** (API requirements):
- ✅ Relative to vault root: `folder/subfolder/note.md`
- ❌ No leading slash: `/folder/note.md` is WRONG
- ✅ Forward slashes only
- ✅ Always include `.md` extension
- ✅ URL-encode non-ASCII characters in PATCH targets

---

## Content Type Standards

**Supported Content-Types**:
- `text/markdown` - Markdown content
- `application/json` - JSON data (tables, arrays)
- `application/vnd.olrapi.note+json` - Note with parsed metadata
- `application/vnd.olrapi.dataview.dql+txt` - Dataview DQL query
- `application/vnd.olrapi.jsonlogic+json` - JsonLogic query

---

## Validation Rules

**Before Writing Notes**:
1. ✅ **Markdown Syntax Validation**:
   - Check for malformed headings, lists, code blocks
   - Validate frontmatter YAML syntax
   - Ensure proper link formats `[[note]]` and `[text](url)`

2. ✅ **Required Frontmatter Fields**:
   - Validate presence of required fields (if defined)
   - Check field value types (string, array, date, etc.)
   - Warn if common fields are missing (`title`, `tags`, `created`)

3. ✅ **Error Reporting**:
   - Clear error messages with line numbers
   - Suggestions for fixes
   - Option to write anyway (with user confirmation)

---

## Obsidian Syntax Preservation

**Must Preserve**:
- Wikilinks: `[[Note Name]]` or `[[Note Name|Display Text]]`
- Tags: `#tag` or `#nested/tag`
- Block references: `^block-id`
- Embeds: `![[Note Name]]`
- Callouts: `> [!note]`, `> [!warning]`, etc.
- Frontmatter: YAML between `---` delimiters

---

## Security Considerations

1. **API Key Storage**:
   - Never hardcode in code
   - Never commit to repository
   - Add to `.gitignore`
   - Use environment variables or secure config files

2. **SSL/HTTPS**:
   - Support self-signed certificates (localhost)
   - Set `verify=False` for local development
   - Document security implications

3. **User Confirmation**:
   - All destructive operations require confirmation
   - Preview changes before execution
   - Clear, explicit prompts

---

## Open Design Questions & TODOs

### Research Required

1. ⚠️ **Periodic Notes Plugin**:
   - Research default configuration
   - Confirm format, location, naming conventions

2. ⚠️ **Obsidian Desktop Defaults**:
   - Frontmatter generation behavior
   - Tag generation behavior
   - Backlink creation behavior
   - Naming conventions

### Implementation TODOs

3. ⚠️ **Installation Scripts**:
   - Create Claude Code install script
   - Create Claude Desktop packaging script
   - Document both methods

4. ⚠️ **Template Detection**:
   - Define template folder conventions
   - Implement template discovery logic
   - Handle missing templates gracefully

### User Preference Questions (ANSWERED ✅)

5. ✅ **Search Result Format** (Q4.2):
   - **Decision**: Context around matches (100 chars before/after)
   - **Rationale**:
     - Shows WHY it matched
     - Enough context to decide relevance
     - Can see multiple matches in same file
     - Fast to scan
   - **Enhancement**: If user needs full context after finding a match, skill can fetch the complete file on request

6. ✅ **Error Handling Strategy** (Q7.1):
   - **Decision**: Fail immediately with clear error message
   - **Message**: "Obsidian Local REST API is not available"
   - **Rationale**: Skill only works with API, no fallback mechanism needed

7. ✅ **Content Validation** (Q7.2):
   - **Decision**: YES, validate before writing
   - **Checks**:
     - ✅ Validate Markdown syntax
     - ✅ Validate required frontmatter fields
   - **Rationale**: Catch errors before writing to vault, ensure data quality

8. ✅ **Output Formatting** (Q9.1):
   - **Decision**: Adaptive based on note length
   - **Rules**:
     - Short notes (<500 lines): Show full content
     - Long notes (≥500 lines): Show metadata + excerpt
   - **Rationale**: Balance between completeness and readability

9. ✅ **Workflow Examples** (Q6.2):
   - **Primary Workflows**:
     1. **Search & Summarize**: "Search my notes on topic X, summarize findings, create new note with insights"
     2. **Research Capture**: Claude conducts research → saves results directly to Obsidian as a note
     3. **Read/Write Like Artifacts**: Treat Obsidian notes as persistent artifacts that can be read and written
   - **Use Case**: Obsidian becomes Claude's long-term memory and knowledge base

10. ✅ **Additional Features** (Q10.1):
    - **Decision**: Focus on core API coverage first
    - **Rationale**: Build solid foundation, add enhancements based on user feedback
    - **Future Enhancements**: Auto-link notes, extract tasks, analyze vault stats, batch operations

11. ✅ **Features to Avoid** (Q10.2):
    - **Decision**: No artificial restrictions
    - **Limit**: API capabilities define what's possible
    - **Rationale**: Let Obsidian API be the gatekeeper, don't impose skill-level limitations

---

## Success Criteria

### Functionality
- ✅ All 31 API endpoints accessible
- ✅ Full CRUD operations on notes
- ✅ Advanced PATCH operations working
- ✅ Search capabilities (all 3 types)
- ✅ Periodic notes management
- ✅ Command execution

### Usability
- ✅ Natural language interaction
- ✅ Clear error messages
- ✅ Intuitive confirmation prompts
- ✅ Comprehensive documentation

### Safety
- ✅ No accidental data loss
- ✅ All destructive operations require confirmation
- ✅ Preview changes before execution

### Compatibility
- ✅ Works on Claude Code (CLI)
- ✅ Works on Claude Desktop
- ✅ Supports both HTTP and HTTPS
- ✅ Handles self-signed certificates

### Documentation
- ✅ Clear README with setup instructions
- ✅ API endpoint reference
- ✅ Troubleshooting guide
- ✅ Example workflows

---

## Version History

**v1.0** - Initial design
- Local REST API integration
- Multi-tier configuration
- Full API coverage
- Strict safety confirmations
- Cross-platform support

---

## References

- Obsidian Local REST API: https://github.com/coddingtonbear/obsidian-local-rest-api
- OpenAPI Specification: `docs/openapi.yaml` (2080 lines)
- API Endpoints: `docs/api-endpoints.md` (31 endpoints documented)
- Destructive Operations: `docs/destructive-operation-list.md` (17 operations detailed)
