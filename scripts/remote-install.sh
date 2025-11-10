#!/bin/bash

# Obsidian Vault Skill - Remote Installer
# One-command installation from GitHub
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/scripts/remote-install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/scripts/remote-install.sh | bash -s -- --user
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/scripts/remote-install.sh | bash -s -- --project
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main/scripts/remote-install.sh | bash -s -- --desktop

set -e  # Exit on error

# Configuration
GITHUB_RAW_URL="https://raw.githubusercontent.com/YOUR_USERNAME/obsidian_skill/main"
MODE="remote"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Download and source library files
download_lib() {
    local url="${GITHUB_RAW_URL}/scripts/lib/$1"
    local output="$TEMP_DIR/$1"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$output" "$url"
    else
        echo "Error: Neither curl nor wget is available"
        exit 1
    fi

    echo "$output"
}

# Download library files
COMMON_SH=$(download_lib "common.sh")
INSTALLER_CORE_SH=$(download_lib "installer-core.sh")

# Source libraries
source "$COMMON_SH"
source "$INSTALLER_CORE_SH"

# Parse arguments
INSTALL_MODE=""
if [ "$1" = "--user" ] || [ "$1" = "-u" ]; then
    INSTALL_MODE="user"
elif [ "$1" = "--project" ] || [ "$1" = "-p" ]; then
    INSTALL_MODE="project"
elif [ "$1" = "--desktop" ] || [ "$1" = "-d" ]; then
    INSTALL_MODE="desktop"
else
    INSTALL_MODE="interactive"
fi

# Print banner
print_banner "📝 Obsidian Vault Skill - Remote Installer"

# Interactive mode - ask user what to install
if [ "$INSTALL_MODE" = "interactive" ]; then
    echo -e "${BLUE}Select installation target:${NC}"
    echo ""
    echo "  1. Claude Code - User level (~/.claude/skills/)"
    echo "  2. Claude Code - Project level (./.claude/skills/)"
    echo "  3. Claude Desktop/Web - Download zip file"
    echo "  4. Exit"
    echo ""
    read -p "Enter choice (1-4): " -n 1 -r CHOICE
    echo ""
    echo ""

    case $CHOICE in
        1)
            INSTALL_MODE="user"
            ;;
        2)
            INSTALL_MODE="project"
            ;;
        3)
            INSTALL_MODE="desktop"
            ;;
        4)
            echo "Installation cancelled"
            exit 0
            ;;
        *)
            echo -e "${RED}✗${NC} Invalid choice"
            exit 1
            ;;
    esac
fi

# Execute installation based on mode
case $INSTALL_MODE in
    user)
        install_to_user_level
        configure_api_key
        echo ""
        show_next_steps
        ;;
    project)
        install_to_project_level
        configure_api_key
        echo ""
        show_next_steps
        ;;
    desktop)
        install_claude_desktop
        ;;
    *)
        echo -e "${RED}✗${NC} Unknown installation mode"
        exit 1
        ;;
esac

# Function to download zip for Claude Desktop
install_claude_desktop() {
    echo -e "${GREEN}➜${NC} Downloading package for Claude Desktop/Web..."
    echo ""

    local temp_skill_dir="$TEMP_DIR/obsidian-vault-skill"
    mkdir -p "$temp_skill_dir"

    # Download only SKILL.md and README.md
    echo -e "${GREEN}  ↓${NC} Downloading SKILL.md..."
    download_file "SKILL.md" "$temp_skill_dir/SKILL.md"

    echo -e "${GREEN}  ↓${NC} Downloading README.md..."
    download_file "README.md" "$temp_skill_dir/README.md"

    # Create zip file
    echo -e "${GREEN}  📦${NC} Creating zip file..."
    local output_zip="$HOME/Downloads/obsidian-vault-skill.zip"

    cd "$TEMP_DIR"
    zip -r "$output_zip" "obsidian-vault-skill" > /dev/null 2>&1

    local file_size=$(du -h "$output_zip" | cut -f1)

    echo ""
    echo -e "${GREEN}✓${NC} Package created successfully!"
    echo ""
    print_section "📦 Package Details:"
    echo "     File: obsidian-vault-skill.zip"
    echo "     Size: $file_size"
    echo "     Location: ~/Downloads/"
    echo ""
    echo "  📄 Contents:"
    echo "     - SKILL.md"
    echo "     - README.md"
    echo ""
    echo "  📚 Documentation:"
    echo "     View full docs at: https://github.com/YOUR_USERNAME/obsidian_skill/tree/main/docs"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${BLUE}Upload Instructions:${NC}"
    echo ""
    echo "  For Claude Desktop:"
    echo "    1. Open Claude Desktop"
    echo "    2. Settings → Capabilities → Upload skill"
    echo "    3. Select: ~/Downloads/obsidian-vault-skill.zip"
    echo ""
    echo "  For claude.ai (Web):"
    echo "    1. Go to https://claude.ai"
    echo "    2. Settings → Capabilities → Upload skill"
    echo "    3. Select: ~/Downloads/obsidian-vault-skill.zip"
    echo ""
    echo -e "${YELLOW}⚠️  Requirements:${NC}"
    echo "    • Pro, Max, Team, or Enterprise plan"
    echo "    • Code execution must be enabled"
    echo ""
    print_section "⚙️  Configuration (After Upload):"
    echo "The skill needs your Obsidian API key to work."
    echo ""
    echo "Create a config file in one of these locations:"
    echo ""
    echo "  1. Project .env file (in your working directory):"
    echo "     apiKey=your-api-key-here"
    echo "     apiUrl=https://localhost:27124"
    echo ""
    echo "  2. User config file (~/.cc_obsidian/config.json):"
    echo "     {"
    echo "       \"apiKey\": \"your-api-key-here\","
    echo "       \"apiUrl\": \"https://localhost:27124\","
    echo "       \"allowDelete\": false"
    echo "     }"
    echo ""
    echo "Get your API key from:"
    echo "  Obsidian → Settings → Community Plugins → Local REST API"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}✨ Package ready for upload!${NC}"
    echo ""
}
