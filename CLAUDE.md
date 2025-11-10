# Obsidian Skill Development Project

This is a development project for building a Claude Code skill that integrates with Obsidian via the Local REST API.

## Your Role

You are an expert in:
1. **Claude Code Skills**: Understanding skill architecture, YAML frontmatter, skill behavior, and best practices
2. **Obsidian**: Knowledge management, markdown formatting, wikilinks, tags, frontmatter, plugins, and vault structure
3. **Obsidian Local REST API**: All 31 endpoints, authentication, PATCH operations, search capabilities (Dataview, JsonLogic), periodic notes, and API patterns
4. **API Design**: REST principles, OpenAPI specifications, error handling, and integration patterns
5. **Developer Experience**: Clear documentation, examples, and user-friendly workflows

## Project Context

### What We're Building
A Claude Code skill that allows users to interact with their Obsidian vaults programmatically through natural language. Users should be able to:
- Search and read notes
- Create and update notes with proper Obsidian formatting
- Manage daily/periodic notes
- Execute Dataview queries
- Perform batch operations
- Maintain Obsidian-specific syntax (wikilinks, tags, callouts, etc.)

### Key Files

- **`SKILL.md`**: The actual skill definition (what gets shipped)
- **`docs/openapi.yaml`**: Official OpenAPI spec from Obsidian Local REST API (2080 lines, 31 endpoints)
- **`docs/api-endpoints.md`**: Comprehensive endpoint documentation with use case scenarios
- **`docs/destructive-operation-list.md`**: List of all 17 destructive operations with risk levels
- **`docs/ADR-001-skill-architecture.md`**: Architecture Decision Record - Initial skill design
- **`docs/ADR-002-destructive-operation-guardrails.md`**: Architecture Decision Record - Safety guardrails
- **`docs/ADR-003-automatic-backup-system.md`**: Architecture Decision Record - Automatic backups
- **`docs/ADR-004-skill-md-design.md`**: Architecture Decision Record - SKILL.md structure
- **`README.md`**: User-facing documentation

### API Capabilities (Reference)

The Obsidian Local REST API provides:
- **File Operations**: GET, POST, PUT, PATCH, DELETE on vault files and active file
- **Advanced PATCH**: Target by heading, block reference, or frontmatter field with append/prepend/replace
- **Search**: Simple text search, Dataview DQL queries, JsonLogic queries with custom operators (glob, regexp)
- **Periodic Notes**: Daily/weekly/monthly/quarterly/yearly with current + specific date support
- **Commands**: List and execute any Obsidian command
- **Metadata**: JSON mode with parsed tags, frontmatter, and file stats
- **Directory Listing**: Browse vault structure

## Development Guidelines

### When Helping with Skill Development

1. **Always Reference the OpenAPI Spec**: Use `docs/openapi.yaml` or `docs/api-endpoints.md` as the source of truth
2. **Preserve Obsidian Conventions**: Maintain wikilinks, tags, frontmatter, callouts, and other Obsidian-specific syntax
3. **Follow Claude Code Skills Best Practices**:
   - Use YAML frontmatter in SKILL.md files
   - Include clear, concise instructions
   - Provide code examples
   - Specify when to activate proactively
   - Define tool access (Bash, Read, Write, etc.)
4. **Security First**:
   - Never hardcode API keys
   - Use environment variables (`OBSIDIAN_API_KEY`)
   - Handle errors gracefully
   - Ask for confirmation on destructive operations

### Path Format Rules (Critical)
- ✅ `folder/subfolder/note.md` (relative to vault root, forward slashes)
- ❌ `/folder/note.md` (no leading slash)
- ✅ Always include `.md` extension
- ✅ URL-encode non-ASCII characters in PATCH targets

### Code Examples Should Use
```python
import os
import requests

api_key = os.getenv('OBSIDIAN_SKILL_API_KEY')
base_url = os.getenv('OBSIDIAN_SKILL_API_URL', 'https://localhost:27124')
headers = {'Authorization': f'Bearer {api_key}'}

# Always include verify=False for self-signed certs (localhost only)
# Always include timeout (e.g., timeout=10)
# Always handle errors gracefully
```

### PATCH Operations (Advanced Feature)

PATCH is powerful but complex. Headers:
- `Operation`: `append` | `prepend` | `replace`
- `Target-Type`: `heading` | `block` | `frontmatter`
- `Target`: The identifier (e.g., `Heading::Subheading`, `^block-id`, `fieldName`)
- `Target-Delimiter`: Default `::` for nested headings
- `Content-Type`: `text/markdown` or `application/json`

Example: Append under a heading
```python
response = requests.patch(
    f'{base_url}/vault/note.md',
    headers={
        **headers,
        'Operation': 'append',
        'Target-Type': 'heading',
        'Target': 'Tasks',
        'Content-Type': 'text/markdown'
    },
    data='- [ ] New task',
    verify=False
)
```

### Common User Requests

When users ask to:
- **"Add more endpoints"**: Check `docs/openapi.yaml` first - we have 31 endpoints already documented
- **"Support feature X"**: Verify if the API supports it in the OpenAPI spec
- **"Simplify the skill"**: Focus on common operations (read, search, create, update daily notes)
- **"Add examples"**: Use Python with requests library, include error handling
- **"Fix formatting"**: Preserve Obsidian syntax (wikilinks, tags, callouts)
- **"Improve security"**: Use environment variables, validate paths, ask for confirmation

### Testing Approach

Suggest users test with:
```bash
# Check API connectivity
curl -H "Authorization: Bearer $OBSIDIAN_SKILL_API_KEY" https://localhost:27124/

# Check environment variable
echo $OBSIDIAN_SKILL_API_KEY

# Verify plugin is running in Obsidian
# Settings → Community Plugins → Local REST API → Should be enabled
```

### Documentation Standards

- Keep README.md user-friendly and concise
- Put technical details in `docs/`
- Include setup instructions with multiple options
- Provide troubleshooting for common issues
- Link to official resources (OpenAPI spec, interactive docs)

## What NOT to Do

- ❌ Don't invent API endpoints that don't exist
- ❌ Don't use leading slashes in vault paths
- ❌ Don't ignore the OpenAPI spec - it's the source of truth
- ❌ Don't hardcode API keys in examples
- ❌ Don't forget error handling in code examples
- ❌ Don't break Obsidian-specific syntax (wikilinks, tags, etc.)
- ❌ Don't recommend POST for creating files (use PUT - POST appends)
- ❌ Don't forget `verify=False` for localhost HTTPS requests

## Claude Code vs Claude Desktop: Skill Setup Differences

### Installation Format

| Platform | Format | Location | Installation |
|----------|--------|----------|--------------|
| **Claude Code** | Directory with SKILL.md | `~/.claude/skills/` or `.claude/skills/` | Copy directory, auto-discovered |
| **Claude Desktop** | .zip file | Upload via Settings | Manual upload through UI |
| **claude.ai (Web)** | .zip file | Upload via Settings | Manual upload through UI |

### Claude Code Installation
- **Format**: Directory structure with `SKILL.md` file
- **Locations**:
  - User-level: `~/.config/claude/skills/` or `~/.claude/skills/`
  - Project-level: `.claude/skills/` (in project root)
  - Plugin-provided: Via marketplace
- **Discovery**: Automatic filesystem scan
- **No zip required**: Just copy the skill directory

### Claude Desktop Installation
- **Format**: .zip archive containing skill directory
- **Upload**: Settings → Capabilities → "Upload skill"
- **Requirements**:
  - Pro, Max, Team, or Enterprise plan
  - Code execution enabled
- **Structure inside .zip**:
  ```
  obsidian-skill.zip
  └── obsidian-skill/
      ├── SKILL.md          (required)
      ├── resources/        (optional)
      └── scripts/          (optional)
  ```

### Key Differences

1. **Packaging**:
   - Code: No packaging needed, use as-is
   - Desktop: Must create .zip file

2. **Installation**:
   - Code: Copy to filesystem, auto-discovered
   - Desktop: Upload through UI

3. **Sharing**:
   - Code: Share directory or git repo
   - Desktop: Share .zip file (users must upload individually)

4. **Updates**:
   - Code: Replace files, restart if needed
   - Desktop: Re-upload new .zip file

### Build Commands for This Project

```bash
# For Claude Code: Just use the directory
cp -r . ~/.claude/skills/obsidian-skill

# For Claude Desktop: Create zip file
# Note: Archive the skill directory itself, not its contents
cd ..
zip -r obsidian-skill.zip obsidian_skill/
```

### SKILL.md Requirements (Both Platforms)

Both platforms use the same SKILL.md format:

```yaml
---
name: skill-identifier
description: When and how to use this skill
---

# Skill instructions in markdown

Your detailed instructions here...
```

**Required fields**: `name` and `description` in YAML frontmatter

## Project Goals

1. **Ease of Use**: Users should interact naturally without knowing API details
2. **Comprehensive**: Support all major API capabilities
3. **Safe**: Prevent accidental data loss or corruption
4. **Well-Documented**: Clear README, examples, and troubleshooting
5. **Extensible**: Easy to customize for specific workflows
6. **Best Practices**: Follow Claude Code and API conventions
7. **Cross-Platform**: Work on both Claude Code and Claude Desktop

## Quick Reference

### API Base URLs
- HTTPS (default): `https://localhost:27124`
- HTTP: `http://localhost:27123`

### Key Endpoints
- Read file: `GET /vault/{filename}`
- Create/replace: `PUT /vault/{filename}`
- Append: `POST /vault/{filename}`
- Patch: `PATCH /vault/{filename}` (with special headers)
- Delete: `DELETE /vault/{filename}`
- Simple search: `POST /search/simple/`
- Dataview: `POST /search/` (Content-Type: application/vnd.olrapi.dataview.dql+txt)
- Daily note: `GET /periodic/daily/`
- List commands: `GET /commands/`

### Content-Types
- `text/markdown` - Markdown content
- `application/json` - JSON data
- `application/vnd.olrapi.note+json` - Note with metadata
- `application/vnd.olrapi.dataview.dql+txt` - Dataview query
- `application/vnd.olrapi.jsonlogic+json` - JsonLogic query

## Remember

This is a development project. Users will come here to:
- Build and customize the skill
- Understand the API capabilities
- Add new features
- Fix bugs
- Improve documentation

Help them be successful by being an expert in Claude Code skills, Obsidian, and the Local REST API!
