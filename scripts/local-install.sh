#!/bin/bash

# Obsidian Vault Skill - Local Installation Script
# Installs the Obsidian Vault skill from cloned repository

set -e  # Exit on error

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SOURCE_DIR="$SCRIPT_DIR/.."
MODE="local"

# Source library files
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/installer-core.sh"

# Print banner
print_banner "📝 Obsidian Vault Skill - Local Installer"

# Check if ~/.claude/skills directory exists
if [ ! -d "$HOME/.claude/skills" ]; then
    echo -e "${YELLOW}⚠️  Creating ~/.claude/skills directory...${NC}"
    mkdir -p "$HOME/.claude/skills"
    echo -e "${GREEN}✓${NC} Directory created"
    echo ""
fi

# Verify SKILL.md exists
if [ ! -f "$SOURCE_DIR/SKILL.md" ]; then
    echo -e "${RED}✗${NC} Error: SKILL.md not found in $SOURCE_DIR"
    echo "   Make sure you're running this from the obsidian_skill/scripts directory"
    exit 1
fi

# Parse installation target
INSTALL_TARGET="${1:---user}"

case $INSTALL_TARGET in
    --user|-u)
        install_to_user_level
        ;;
    --project|-p)
        install_to_project_level
        ;;
    *)
        echo -e "${BLUE}Select installation target:${NC}"
        echo ""
        echo "  1. User level (~/.claude/skills/)"
        echo "  2. Project level (./.claude/skills/)"
        echo "  3. Exit"
        echo ""
        read -p "Enter choice (1-3): " -n 1 -r CHOICE
        echo ""
        echo ""

        case $CHOICE in
            1)
                install_to_user_level
                ;;
            2)
                install_to_project_level
                ;;
            3)
                echo "Installation cancelled"
                exit 0
                ;;
            *)
                echo -e "${RED}✗${NC} Invalid choice"
                exit 1
                ;;
        esac
        ;;
esac

# Configuration setup
configure_api_key

# Show next steps
echo ""
show_next_steps
