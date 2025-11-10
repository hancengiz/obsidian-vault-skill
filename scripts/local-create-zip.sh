#!/bin/bash

# Obsidian Vault Skill - Zip Creator for Claude Desktop/Web
# Creates a zip file that can be uploaded to Claude Desktop or claude.ai
# Contains only SKILL.md and README.md

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_DIR="$SCRIPT_DIR/.."

# Source common utilities
source "$SCRIPT_DIR/lib/common.sh"

SKILL_NAME="obsidian-vault-skill"
ZIP_NAME="${SKILL_NAME}.zip"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

print_banner "📦 Obsidian Vault Skill - Zip Builder"
echo "  For Claude Desktop & claude.ai (Web)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if SKILL.md exists
if [ ! -f "$SOURCE_DIR/SKILL.md" ]; then
    echo -e "${RED}✗${NC} Error: SKILL.md not found in $SOURCE_DIR"
    echo "   Make sure you're running this from the obsidian_skill/scripts directory"
    exit 1
fi

echo -e "${GREEN}➜${NC} Preparing files for packaging..."

# Create temporary directory structure
mkdir -p "$TEMP_DIR/$SKILL_NAME"

# Copy only SKILL.md and README.md
cp "$SOURCE_DIR/SKILL.md" "$TEMP_DIR/$SKILL_NAME/"
echo -e "${GREEN}  ✓${NC} SKILL.md"

if [ -f "$SOURCE_DIR/README.md" ]; then
    cp "$SOURCE_DIR/README.md" "$TEMP_DIR/$SKILL_NAME/"
    echo -e "${GREEN}  ✓${NC} README.md"
fi

echo ""
echo -e "${GREEN}➜${NC} Creating zip file..."

# Create zip file
cd "$TEMP_DIR"
zip -r "$SOURCE_DIR/$ZIP_NAME" "$SKILL_NAME" > /dev/null

# Get file size
FILE_SIZE=$(du -h "$SOURCE_DIR/$ZIP_NAME" | cut -f1)

echo -e "${GREEN}✓${NC} Zip file created successfully!"
echo ""

print_section "📦 Package Details:"
echo -e "  ${GREEN}✓${NC} File: $ZIP_NAME"
echo -e "  ${GREEN}✓${NC} Size: $FILE_SIZE"
echo -e "  ${GREEN}✓${NC} Location: $SOURCE_DIR"
echo ""
echo "  📄 Contents:"
echo "     - SKILL.md"
echo "     - README.md"
echo ""
echo "  📚 Documentation:"
echo "     View full docs at: https://github.com/YOUR_USERNAME/obsidian_skill/tree/main/docs"
echo ""

print_section "🎯 Installation Instructions:"
echo -e "${BLUE}For Claude Desktop:${NC}"
echo "  1. Open Claude Desktop"
echo "  2. Go to Settings → Capabilities"
echo "  3. Click \"Upload skill\""
echo "  4. Select: $SOURCE_DIR/$ZIP_NAME"
echo "  5. Enable the skill"
echo ""
echo -e "${BLUE}For claude.ai (Web):${NC}"
echo "  1. Go to https://claude.ai"
echo "  2. Click Settings (gear icon)"
echo "  3. Go to Capabilities tab"
echo "  4. Click \"Upload skill\""
echo "  5. Select: $SOURCE_DIR/$ZIP_NAME"
echo "  6. Enable the skill"
echo ""
echo -e "${YELLOW}⚠️  Requirements:${NC}"
echo "  • Pro, Max, Team, or Enterprise plan"
echo "  • Code execution must be enabled"
echo ""

print_section "⚙️  Configuration (After Upload):"
echo "The skill needs your Obsidian API key to work."
echo ""
echo "Create a config file in one of these locations:"
echo ""
echo "  1. Project .env file (in your working directory):"
echo "     "
echo "     apiKey=your-api-key-here"
echo "     apiUrl=https://localhost:27124"
echo "     allowDelete=false"
echo ""
echo "  2. User config file (~/.cc_obsidian/config.json):"
echo "     "
echo "     {"
echo "       \"apiKey\": \"your-api-key-here\","
echo "       \"apiUrl\": \"https://localhost:27124\","
echo "       \"allowDelete\": false,"
echo "       \"backupEnabled\": true,"
echo "       \"backupDirectory\": \"~/.cc_obsidian/backups\","
echo "       \"backupKeepLastN\": 5,"
echo "       \"DANGEROUSLY_SKIP_CONFIRMATIONS\": false"
echo "     }"
echo ""
echo "  3. Or use environment variables (platform-dependent):"
echo "     "
echo "     export OBSIDIAN_SKILL_API_KEY=\"your-api-key-here\""
echo "     export OBSIDIAN_SKILL_API_URL=\"https://localhost:27124\""
echo ""
echo "Get your API key from:"
echo "  Obsidian → Settings → Community Plugins → Local REST API"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}✨ Package ready for upload!${NC}"
echo ""
