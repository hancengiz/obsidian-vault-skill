# Obsidian Vault Skill for Claude

A Claude Code skill that enables seamless interaction with your Obsidian vault through the Local REST API. Read, search, create, update, and manage your notes using natural language with Claude.

**Works with:** Claude Code | Claude Desktop | claude.ai (Web)

## Quick Install

### One-Line Installation (Recommended)

**Claude Code - User Level** (installs to `~/.claude/skills/`):
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/scripts/remote-install.sh | bash -s -- --user
```

**Claude Code - Project Level** (installs to `./.claude/skills/`):
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/scripts/remote-install.sh | bash -s -- --project
```

**Claude Desktop/Web** (downloads zip to `~/Downloads/`):
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/scripts/remote-install.sh | bash -s -- --desktop
```

**Interactive Mode** (choose during installation):
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/scripts/remote-install.sh | bash
```

> **Note**: Replace `YOUR_USERNAME` with your GitHub username once you push this repository.

## Overview

This skill equips Claude with the ability to interact with your Obsidian vault programmatically, enabling workflows like:
- Searching and analyzing your knowledge base
- Creating and updating notes with proper Obsidian formatting
- Managing daily/periodic notes
- Executing Dataview queries
- Organizing and linking notes
- Batch processing operations

## Prerequisites

### 1. Obsidian with Local REST API Plugin

You need Obsidian with the [Local REST API plugin](https://github.com/coddingtonbear/obsidian-local-rest-api) installed and enabled.

**Installation**:
1. Open Obsidian
2. Go to Settings → Community Plugins
3. Disable Safe Mode (if enabled)
4. Click "Browse" and search for "Local REST API"
5. Install and Enable the plugin
6. Go to plugin settings and copy your API key

### 2. API Configuration

The skill requires an API key to authenticate with your Obsidian vault. Configuration is loaded in priority order (first found wins):

#### Configuration Priority

1. **Environment Variables** (Highest Priority)
2. **Project .env File** (Second Priority)
3. **User Home Config File** (Lowest Priority)

#### Option 1: Environment Variables (Recommended)

**Temporary (current session)**:
```bash
export OBSIDIAN_SKILL_API_KEY='your-api-key-here'
export OBSIDIAN_SKILL_API_URL='https://localhost:27124'  # Optional, defaults to this
```

**Permanent (add to shell config)**:
```bash
# For zsh (macOS default)
echo 'export OBSIDIAN_SKILL_API_KEY="your-api-key-here"' >> ~/.zshrc
source ~/.zshrc

# For bash
echo 'export OBSIDIAN_SKILL_API_KEY="your-api-key-here"' >> ~/.bash_profile
source ~/.bash_profile
```

#### Option 2: Project .env File

Create a `.env` file in your project root:

```
apiKey=your-api-key-here
apiUrl=https://localhost:27124
```

**Note**: No `OBSIDIAN_SKILL_` prefix in .env files. The prefix is only used for environment variables.

**Important**: Add `.env` to your `.gitignore` to prevent committing secrets!

#### Option 3: User Home Config File

Create `~/.cc_obsidian/config.json` in your home directory:

```bash
mkdir -p ~/.cc_obsidian
cat > ~/.cc_obsidian/config.json << 'EOF'
{
  "apiKey": "your-api-key-here",
  "apiUrl": "https://localhost:27124"
}
EOF
```

This provides user-level defaults that work across all projects without environment variables.

## Project Structure

```
obsidian_skill/
├── SKILL.md                      # Main skill definition (required)
├── README.md                     # This file - setup and usage guide
├── CLAUDE.md                     # Developer instructions
├── .gitignore
├── scripts/
│   ├── lib/
│   │   ├── common.sh             # Shared utilities for installers
│   │   └── installer-core.sh     # Core installation logic
│   ├── remote-install.sh         # One-line remote installer (curl from GitHub)
│   ├── local-install.sh          # Local installer for Claude Code
│   ├── local-create-zip.sh       # Build script for Claude Desktop/Web
│   └── INSTALL.md                # Installation documentation
├── docs/
│   ├── openapi.yaml              # Complete OpenAPI specification (31 endpoints)
│   ├── api-endpoints.md          # All endpoints with use case scenarios
│   ├── destructive-operation-list.md  # All 17 destructive operations with risk levels
│   ├── ADR-001-skill-architecture.md      # Architecture Decision: Initial design
│   ├── ADR-002-destructive-operation-guardrails.md  # Architecture Decision: Safety guardrails
│   ├── ADR-003-automatic-backup-system.md  # Architecture Decision: Automatic backups
│   └── ADR-004-skill-md-design.md         # Architecture Decision: SKILL.md structure
```

## Installation

> **Quick Install**: See [One-Line Installation](#one-line-installation-recommended) at the top of this README for the fastest method.

Choose the installation method based on your platform:

### For Claude Code (CLI)

**Method 1: Remote Installation (Fastest)**:
```bash
# User-level (recommended)
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/remote-install.sh | bash -s -- --user

# Project-level
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/remote-install.sh | bash -s -- --project
```

**Method 2: Clone + Run Installer**:
```bash
git clone https://github.com/YOUR_USERNAME/obsidian_skill.git
cd obsidian_skill
./scripts/local-install.sh
```

**Method 3: Manual Installation**:
```bash
# Clone and copy only essential files
git clone https://github.com/your-username/obsidian_skill.git
mkdir -p ~/.claude/skills/obsidian-vault
cp obsidian_skill/SKILL.md ~/.claude/skills/obsidian-vault/
cp obsidian_skill/README.md ~/.claude/skills/obsidian-vault/
```

**Project-Level Installation** (optional):
```bash
# Install to specific project
mkdir -p your-project/.claude/skills/obsidian-vault
cp obsidian_skill/SKILL.md your-project/.claude/skills/obsidian-vault/
cp obsidian_skill/README.md your-project/.claude/skills/obsidian-vault/
```

The skill will be automatically discovered by Claude Code when you start a new conversation.

> **Note**: Installations only include SKILL.md and README.md. Full documentation is available at https://github.com/YOUR_USERNAME/obsidian_skill/tree/main/docs

---

### For Claude Desktop / claude.ai (Web)

**Method 1: Remote Download (Fastest)**:
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/remote-install.sh | bash -s -- --desktop
```
This downloads `obsidian-vault-skill.zip` to `~/Downloads/`.

**Method 2: Clone + Build**:
```bash
git clone https://github.com/YOUR_USERNAME/obsidian_skill.git
cd obsidian_skill
./scripts/local-create-zip.sh
```

**Method 3: Manual Build**:
```bash
cd obsidian_skill
# Create minimal zip with only SKILL.md and README.md
mkdir -p obsidian-vault-skill
cp SKILL.md README.md obsidian-vault-skill/
zip -r obsidian-vault-skill.zip obsidian-vault-skill/
rm -rf obsidian-vault-skill
```

**Upload to Claude**:
1. Open Claude Desktop or go to https://claude.ai
2. Click Settings → Capabilities
3. Click "Upload skill"
4. Select `obsidian-vault-skill.zip`
5. Enable the skill

**Requirements**: Pro, Max, Team, or Enterprise plan with code execution enabled

> **Note**: The zip file only contains SKILL.md and README.md. Full documentation is available at https://github.com/YOUR_USERNAME/obsidian_skill/tree/main/docs

---

### Verify Installation

After installation, test the skill by asking:
- "Can you search my Obsidian vault?"
- "Read my daily note"

The skill should activate automatically when you mention Obsidian.

## Usage

Once installed, simply ask Claude to interact with your vault:

### Basic Examples

**Search your vault**:
```
Search my Obsidian vault for notes about machine learning
```

**Read a note**:
```
Read the note at "Projects/AI Research.md" and summarize it
```

**Create a new note**:
```
Create a new note called "Meeting Notes 2025-01-10" with a summary of our discussion
```

**Update a note**:
```
Add today's learnings to my daily note
```

**Dataview queries**:
```
Use Dataview to find all notes tagged with #important from the last week
```

### Advanced Workflows

**Knowledge graph analysis**:
```
Analyze my notes on topic X and create a summary note with connections to related notes
```

**Daily note automation**:
```
Create today's daily note using my template and add a task list for the day
```

**Batch processing**:
```
Find all notes in the "Archive" folder and update their frontmatter to include an "archived: true" field
```

## Configuration

### API Endpoints

By default, the skill connects to:
- **HTTPS**: `https://localhost:27124` (default)
- **HTTP**: `http://localhost:27123`

You can override this with the `OBSIDIAN_API_URL` environment variable.

### SSL/HTTPS

The Local REST API uses self-signed certificates for HTTPS. The skill handles this automatically by setting `verify=False` in requests. For production use, consider:
- Adding the certificate to your system trust store
- Using the HTTP endpoint if local security is acceptable
- Configuring a proper SSL certificate

### Vault Permissions

By default, the skill can access your entire vault. To restrict access:
1. Modify the `CLAUDE.md` file to add path restrictions
2. Or tell Claude which folders to avoid (e.g., ".obsidian", "Templates")

## Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  Claude         │────────▶│  Obsidian Vault  │────────▶│  Obsidian       │
│  (with Skill)   │         │  Skill           │         │  Local REST API │
└─────────────────┘         └──────────────────┘         └─────────────────┘
                                     │                            │
                                     │                            │
                                     ▼                            ▼
                            Python requests                 Vault Files
                            + Bearer Auth                  (.md, .canvas)
```

### Components

1. **`SKILL.md`**: Skill definition with:
   - YAML frontmatter (name, description)
   - System instructions with API details
   - Code examples and best practices
   - When to activate proactively

2. **`docs/`**: Complete documentation:
   - `openapi.yaml`: Official API specification (2080 lines, 31 endpoints)
   - `api-endpoints.md`: All endpoints with use case scenarios
   - `destructive-operation-list.md`: All 17 destructive operations with risk levels
   - `ADR-001-skill-architecture.md`: Architecture Decision - Initial design
   - `ADR-002-destructive-operation-guardrails.md`: Architecture Decision - Safety guardrails
   - `ADR-003-automatic-backup-system.md`: Architecture Decision - Automatic backups
   - `ADR-004-skill-md-design.md`: Architecture Decision - SKILL.md structure

3. **README.md**: This file - setup, usage, and documentation

## Alternative Integration Methods

This skill uses the **Local REST API** approach, which is HTTP-based and works with any tool that can make HTTP requests.

### Other Options

If the REST API doesn't fit your workflow, consider these alternatives:

#### 1. MCP Server (Recommended for Claude Code)
- **Plugin**: [`obsidian-claude-code-mcp`](https://github.com/iansinnott/obsidian-claude-code-mcp)
- **Pros**: Auto-discovery in Claude Code, no API key management, WebSocket support
- **Cons**: Requires separate plugin, newer approach

#### 2. CLI Tools
- **Tool**: [`obsidian-cli`](https://github.com/Yakitrak/obsidian-cli) or others
- **Pros**: Command-line native, good for shell scripts
- **Cons**: Less feature-rich than REST API

#### 3. Direct File System Access
- **Method**: Read/write markdown files directly
- **Pros**: No plugins needed, simple
- **Cons**: Bypasses Obsidian features, risk of corruption

**Comparison**:

| Method | Setup | Features | Real-time | Auth |
|--------|-------|----------|-----------|------|
| REST API | Plugin + API key | ⭐⭐⭐⭐⭐ | Polling | API Key |
| MCP Server | Plugin | ⭐⭐⭐⭐ | WebSocket | MCP |
| CLI Tools | Binary install | ⭐⭐⭐ | No | Varies |
| File System | None | ⭐⭐ | No | None |

## Troubleshooting

### "Cannot connect to Obsidian API"
- Verify Obsidian is running
- Check the Local REST API plugin is enabled
- Test connection: `curl -H "Authorization: Bearer $OBSIDIAN_SKILL_API_KEY" https://localhost:27124/`

### "Authentication failed"
- Verify API key is correct: `echo $OBSIDIAN_SKILL_API_KEY`
- Check the key matches the one in Obsidian's plugin settings
- Regenerate the API key if needed

### "Note not found"
- Check path format: no leading slash, use forward slashes
- Ensure `.md` extension is included
- Verify the note exists in your vault

### SSL Certificate Errors
- The skill sets `verify=False` by default for self-signed certs
- If you encounter issues, try using HTTP endpoint: `http://localhost:27123`

### Skill Not Loading
- Check skill is in the correct directory: `~/.claude/skills/obsidian-vault/`
- Verify `SKILL.md` file exists and has proper YAML frontmatter
- For Claude Code: Restart or start a new conversation
- For Claude Desktop: Re-upload the skill zip file

### Missing Documentation
- Documentation (docs/ folder) is not included in skill installations
- Access full docs at: https://github.com/YOUR_USERNAME/obsidian_skill/tree/main/docs
- OpenAPI spec, ADRs, and endpoint guides available in GitHub repo

## Development

### Customizing the Skill

1. Review Architecture Decision Records:
   - `docs/ADR-001-skill-architecture.md` - Initial design decisions
   - `docs/ADR-002-destructive-operation-guardrails.md` - Safety guardrails
   - `docs/ADR-003-automatic-backup-system.md` - Automatic backups
   - `docs/ADR-004-skill-md-design.md` - SKILL.md structure and design
   - `docs/destructive-operation-list.md` - All destructive operations
2. Edit `SKILL.md` to modify:
   - Available capabilities
   - Example code
   - Workflows
   - Safety restrictions

3. Test changes by asking Claude to use the skill

### Contributing

Contributions are welcome! Areas for improvement:
- Additional workflow examples
- Enhanced error handling
- Support for more Obsidian plugins (Templater, etc.)
- MCP server variant of this skill
- Tests and validation

## Security

### API Key Safety
- Never commit API keys to version control
- Use environment variables or config files (in `.gitignore`)
- Rotate keys periodically
- Restrict Claude Code file permissions if needed (`.claude/settings.json`)

### Vault Integrity
- The skill can modify your vault - review changes carefully
- Consider backups before batch operations
- Test workflows on a copy of your vault first

### Network Security
- The API runs on localhost - no external exposure by default
- HTTPS provides encryption for local traffic
- API key authentication prevents unauthorized access

## Resources

### Claude Skills Documentation
- [Skills Overview](https://docs.claude.com/en/docs/skills/skills-overview) - Introduction to Claude Skills
- [Creating Skills](https://docs.claude.com/en/docs/skills/creating-skills) - How to create your own skills
- [Skills on Claude Code](https://docs.claude.com/en/docs/claude-code/skills) - Using skills in Claude Code
- [Skills on Claude Desktop](https://docs.claude.com/en/docs/claude-desktop/skills) - Using skills in Claude Desktop
- [Skills on claude.ai](https://docs.claude.com/en/docs/claude-ai/skills) - Using skills on the web
- [Skills Engineering Blog](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) - Technical deep dive
- [Example Skills Repository](https://github.com/anthropics/skills) - Official skill examples

### Obsidian Local REST API Documentation
- [Local REST API Plugin](https://github.com/coddingtonbear/obsidian-local-rest-api) - Main repository
- [OpenAPI Specification](https://coddingtonbear.github.io/obsidian-local-rest-api/openapi.yaml) - Complete API spec
- [Interactive API Docs](https://coddingtonbear.github.io/obsidian-local-rest-api/) - Swagger UI

### Alternative Obsidian Integrations
- [obsidian-claude-code-mcp](https://github.com/iansinnott/obsidian-claude-code-mcp) - MCP server
- [obsidian-mcp-tools](https://github.com/jacksteamdev/obsidian-mcp-tools) - MCP with semantic search
- [obsidian-cli](https://github.com/Yakitrak/obsidian-cli) - CLI tool

## License

MIT License - See LICENSE file for details

## Acknowledgments

- [Local REST API Plugin](https://github.com/coddingtonbear/obsidian-local-rest-api) by coddingtonbear
- [Obsidian](https://obsidian.md) - The knowledge base app
- [Anthropic](https://anthropic.com) - Claude Code and Skills framework

## Support

- **Issues**: Open an issue on GitHub
- **Discussions**: Obsidian Forum or Claude Code community
- **Updates**: Watch this repository for updates

---

**Built with Claude Code Skills** | [Contribute](https://github.com/your-repo) | [Report Issues](https://github.com/your-repo/issues)
