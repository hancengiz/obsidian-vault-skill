# Obsidian Vault Skill - Installation Guide

Quick reference for all installation methods.

## 🚀 Quick Install (Recommended)

### Claude Code - User Level
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/remote-install.sh | bash -s -- --user
```
Installs to: `~/.claude/skills/obsidian-vault/`

### Claude Code - Project Level
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/remote-install.sh | bash -s -- --project
```
Installs to: `./.claude/skills/obsidian-vault/`

### Claude Desktop/Web
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/remote-install.sh | bash -s -- --desktop
```
Downloads zip to: `~/Downloads/obsidian-vault-skill.zip`

### Interactive Mode
```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/remote-install.sh | bash
```
Choose installation target during installation.

---

## 📦 Alternative Methods

### Method 1: Clone + Local Installer

**For Claude Code**:
```bash
git clone https://github.com/YOUR_USERNAME/obsidian_skill.git
cd obsidian_skill
./install-claude-code.sh
```

**For Claude Desktop/Web**:
```bash
git clone https://github.com/YOUR_USERNAME/obsidian_skill.git
cd obsidian_skill
./create-zip.sh
```

### Method 2: Manual Installation

**Claude Code - User Level**:
```bash
git clone https://github.com/YOUR_USERNAME/obsidian_skill.git
mkdir -p ~/.claude/skills
cp -r obsidian_skill ~/.claude/skills/obsidian-vault
```

**Claude Code - Project Level**:
```bash
git clone https://github.com/YOUR_USERNAME/obsidian_skill.git
mkdir -p ./.claude/skills
cp -r obsidian_skill ./.claude/skills/obsidian-vault
```

**Claude Desktop/Web**:
```bash
git clone https://github.com/YOUR_USERNAME/obsidian_skill.git
cd obsidian_skill
zip -r obsidian-vault-skill.zip obsidian-vault-skill/
```

Then upload the zip file via Settings → Capabilities → Upload skill.

---

## ⚙️ Post-Installation Configuration

After installation, you need to configure your Obsidian API key.

### Get Your API Key

1. Open Obsidian
2. Go to Settings → Community Plugins
3. Find "Local REST API" plugin
4. Click on plugin settings
5. Copy the API key

### Configuration Options

Choose one method:

#### Option 1: Environment Variable (Recommended)
```bash
# Permanent (add to shell config)
echo 'export OBSIDIAN_SKILL_API_KEY="your-api-key-here"' >> ~/.zshrc
source ~/.zshrc

# Or for bash
echo 'export OBSIDIAN_SKILL_API_KEY="your-api-key-here"' >> ~/.bash_profile
source ~/.bash_profile
```

#### Option 2: User Config File
```bash
mkdir -p ~/.cc_obsidian
cat > ~/.cc_obsidian/config.json << 'EOF'
{
  "apiKey": "your-api-key-here",
  "apiUrl": "https://localhost:27124"
}
EOF
```

#### Option 3: Project .env File
```bash
cat > .env << 'EOF'
apiKey=your-api-key-here
apiUrl=https://localhost:27124
EOF
```

**Important**: Add `.env` to `.gitignore`!

---

## ✅ Verify Installation

### For Claude Code
Start a new conversation and ask:
```
Can you search my Obsidian vault?
```

The skill should activate automatically.

### For Claude Desktop/Web
After uploading the zip file:
1. Go to Settings → Capabilities
2. Ensure "Obsidian Vault" skill is enabled
3. Start a new conversation
4. Ask: "Can you search my Obsidian vault?"

---

## 🔧 Troubleshooting

### "Cannot connect to Obsidian API"
- Ensure Obsidian is running
- Verify Local REST API plugin is enabled
- Test: `curl -H "Authorization: Bearer $OBSIDIAN_SKILL_API_KEY" https://localhost:27124/`

### "Authentication failed"
- Check API key: `echo $OBSIDIAN_SKILL_API_KEY`
- Verify it matches the key in Obsidian plugin settings
- Regenerate the key if needed

### "Skill not loading"
**Claude Code**:
- Check: `ls ~/.claude/skills/obsidian-vault/SKILL.md`
- Restart Claude Code or start new conversation

**Claude Desktop/Web**:
- Re-upload the zip file
- Check Settings → Capabilities → Skills are enabled
- Verify you have Pro/Max/Team/Enterprise plan

---

## 📚 Additional Resources

- **README.md** - Full documentation
- **docs/api-endpoints.md** - Complete API reference
- **docs/ADR-*.md** - Architecture decisions
- **CLAUDE.md** - Developer guide

---

## 🆘 Need Help?

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/obsidian_skill/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/obsidian_skill/discussions)
- **Obsidian Forum**: [Obsidian Community](https://forum.obsidian.md/)

---

**Remember**: Replace `YOUR_USERNAME` with your GitHub username in all commands above.
