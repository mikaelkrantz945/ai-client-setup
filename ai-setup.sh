#!/usr/bin/env bash
# ai-setup.sh — Interactive AI tool installer for cloud VMs
# Supports: Debian/Ubuntu, Rocky/AlmaLinux
# Usage: ai-setup.sh [--auto] (auto skips the welcome prompt)

set -euo pipefail

MARKER="$HOME/.ai-setup-done"
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ── Distro detection ──
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            debian|ubuntu) echo "debian" ;;
            rocky|almalinux|rhel|centos) echo "rhel" ;;
            *) echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)

# ── Package manager helpers ──
pkg_install() {
    if [ "$DISTRO" = "debian" ]; then
        sudo apt-get install -y "$@" >/dev/null 2>&1
    elif [ "$DISTRO" = "rhel" ]; then
        sudo dnf install -y "$@" >/dev/null 2>&1
    fi
}

pkg_update() {
    if [ "$DISTRO" = "debian" ]; then
        sudo apt-get update -qq >/dev/null 2>&1
    elif [ "$DISTRO" = "rhel" ]; then
        sudo dnf check-update -q >/dev/null 2>&1 || true
    fi
}

# ── Prerequisite installers ──
ensure_curl() {
    command -v curl >/dev/null 2>&1 || pkg_install curl
}

ensure_git() {
    command -v git >/dev/null 2>&1 || pkg_install git
}

ensure_nodejs() {
    if command -v node >/dev/null 2>&1; then
        local ver
        ver=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
        if [ "$ver" -ge 18 ] 2>/dev/null; then
            return 0
        fi
    fi
    echo -e "  ${BLUE}Installing Node.js 22.x...${NC}"
    ensure_curl
    if [ "$DISTRO" = "debian" ]; then
        curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - >/dev/null 2>&1
        sudo apt-get install -y nodejs >/dev/null 2>&1
    elif [ "$DISTRO" = "rhel" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - >/dev/null 2>&1
        sudo dnf install -y nodejs >/dev/null 2>&1
    fi
}

ensure_python() {
    if command -v python3 >/dev/null 2>&1; then
        return 0
    fi
    echo -e "  ${BLUE}Installing Python 3...${NC}"
    if [ "$DISTRO" = "debian" ]; then
        pkg_install python3 python3-pip python3-venv
    elif [ "$DISTRO" = "rhel" ]; then
        pkg_install python3 python3-pip
    fi
}

ensure_pipx() {
    if command -v pipx >/dev/null 2>&1; then
        return 0
    fi
    echo -e "  ${BLUE}Installing pipx...${NC}"
    ensure_python
    if [ "$DISTRO" = "debian" ]; then
        pkg_install pipx
    elif [ "$DISTRO" = "rhel" ]; then
        python3 -m pip install --user pipx >/dev/null 2>&1
    fi
    pipx ensurepath >/dev/null 2>&1 || true
    export PATH="$HOME/.local/bin:$PATH"
}

ensure_gh() {
    if command -v gh >/dev/null 2>&1; then
        return 0
    fi
    echo -e "  ${BLUE}Installing GitHub CLI...${NC}"
    ensure_curl
    if [ "$DISTRO" = "debian" ]; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt-get update -qq >/dev/null 2>&1
        sudo apt-get install -y gh >/dev/null 2>&1
    elif [ "$DISTRO" = "rhel" ]; then
        sudo dnf install -y 'dnf-command(config-manager)' >/dev/null 2>&1 || true
        sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo >/dev/null 2>&1
        sudo dnf install -y gh >/dev/null 2>&1
    fi
}

# ── AI tool installers ──
install_claude_code() {
    echo -e "\n${BOLD}Installing Claude Code...${NC}"
    ensure_nodejs
    sudo npm install -g @anthropic-ai/claude-code >/dev/null 2>&1
    echo -e "  ${GREEN}Claude Code installed${NC}"

    echo ""
    read -rp "  Enter your Anthropic API key (or press Enter to skip): " api_key
    if [ -n "$api_key" ]; then
        echo "export ANTHROPIC_API_KEY='$api_key'" >> "$HOME/.bashrc"
        export ANTHROPIC_API_KEY="$api_key"
        echo -e "  ${GREEN}API key saved to .bashrc${NC}"
    else
        echo -e "  ${YELLOW}Skipped. Set ANTHROPIC_API_KEY later.${NC}"
    fi
    echo -e "  ${GREEN}Run: claude${NC}"
}

install_aider() {
    echo -e "\n${BOLD}Installing Aider...${NC}"
    ensure_pipx
    pipx install aider-chat >/dev/null 2>&1
    echo -e "  ${GREEN}Aider installed${NC}"

    echo ""
    echo -e "  Aider supports multiple AI providers. Configure one:"
    echo -e "  ${BLUE}1)${NC} Anthropic (Claude)"
    echo -e "  ${BLUE}2)${NC} OpenAI (GPT-4)"
    echo -e "  ${BLUE}3)${NC} Skip"
    read -rp "  Choice [1-3]: " aider_choice
    case "$aider_choice" in
        1)
            read -rp "  Anthropic API key: " key
            if [ -n "$key" ]; then
                echo "export ANTHROPIC_API_KEY='$key'" >> "$HOME/.bashrc"
                echo -e "  ${GREEN}Saved. Run: aider --model claude-sonnet-4-20250514${NC}"
            fi
            ;;
        2)
            read -rp "  OpenAI API key: " key
            if [ -n "$key" ]; then
                echo "export OPENAI_API_KEY='$key'" >> "$HOME/.bashrc"
                echo -e "  ${GREEN}Saved. Run: aider${NC}"
            fi
            ;;
        *)
            echo -e "  ${YELLOW}Skipped. Set API key later.${NC}"
            ;;
    esac
    echo -e "  ${GREEN}Run: aider${NC}"
}

install_openai_cli() {
    echo -e "\n${BOLD}Installing OpenAI CLI...${NC}"
    ensure_pipx
    pipx install openai >/dev/null 2>&1
    echo -e "  ${GREEN}OpenAI CLI installed${NC}"

    echo ""
    read -rp "  Enter your OpenAI API key (or press Enter to skip): " api_key
    if [ -n "$api_key" ]; then
        echo "export OPENAI_API_KEY='$api_key'" >> "$HOME/.bashrc"
        export OPENAI_API_KEY="$api_key"
        echo -e "  ${GREEN}API key saved to .bashrc${NC}"
    else
        echo -e "  ${YELLOW}Skipped. Set OPENAI_API_KEY later.${NC}"
    fi
    echo -e "  ${GREEN}Run: openai api chat.completions.create -m gpt-4 -g user \"Hello\"${NC}"
}

install_copilot_cli() {
    echo -e "\n${BOLD}Installing GitHub Copilot CLI...${NC}"
    ensure_gh
    gh extension install github/gh-copilot >/dev/null 2>&1 || true
    echo -e "  ${GREEN}GitHub Copilot CLI installed${NC}"

    echo ""
    echo -e "  ${YELLOW}You need to authenticate with GitHub:${NC}"
    echo -e "  Run: ${BOLD}gh auth login${NC}"
    echo -e "  Then: ${BOLD}gh copilot suggest \"your question\"${NC}"
}

install_cursor() {
    echo -e "\n${BOLD}Installing Cursor...${NC}"
    ensure_curl
    local tmpdir
    tmpdir=$(mktemp -d)
    echo -e "  ${BLUE}Downloading Cursor AppImage...${NC}"
    curl -fsSL "https://downloader.cursor.sh/linux/appImage/x64" -o "$tmpdir/cursor.AppImage" 2>/dev/null
    sudo mv "$tmpdir/cursor.AppImage" /usr/local/bin/cursor
    sudo chmod +x /usr/local/bin/cursor
    rm -rf "$tmpdir"
    echo -e "  ${GREEN}Cursor installed at /usr/local/bin/cursor${NC}"
    echo -e "  ${YELLOW}Note: Cursor requires a desktop environment (X11/Wayland).${NC}"
    echo -e "  ${GREEN}Run: cursor${NC}"
}

# ── Main menu ──
show_menu() {
    echo -e "\n${BOLD}Available AI Tools:${NC}\n"
    echo -e "  ${BLUE}1)${NC} Claude Code      — Anthropic's coding assistant CLI"
    echo -e "  ${BLUE}2)${NC} Aider            — AI pair programming (Claude/GPT)"
    echo -e "  ${BLUE}3)${NC} OpenAI CLI       — ChatGPT/GPT-4 in the terminal"
    echo -e "  ${BLUE}4)${NC} Copilot CLI      — GitHub Copilot (gh copilot)"
    echo -e "  ${BLUE}5)${NC} Cursor           — AI code editor (AppImage)"
    echo -e ""
    echo -e "  ${BLUE}a)${NC} Install ALL"
    echo -e "  ${BLUE}q)${NC} Quit"
    echo ""
    read -rp "  Select tools (comma-separated, e.g. 1,2): " choices
}

run_installs() {
    local choices="$1"

    # Normalize
    choices=$(echo "$choices" | tr '[:upper:]' '[:lower:]')

    if [[ "$choices" == *"a"* ]]; then
        choices="1,2,3,4,5"
    fi

    if [[ "$choices" == *"q"* ]]; then
        echo -e "\n${YELLOW}Setup skipped. Run 'ai-setup' anytime to install tools.${NC}"
        return 0
    fi

    echo -e "\n${BOLD}Updating package index...${NC}"
    pkg_update

    IFS=',' read -ra items <<< "$choices"
    for item in "${items[@]}"; do
        item=$(echo "$item" | tr -d ' ')
        case "$item" in
            1) install_claude_code ;;
            2) install_aider ;;
            3) install_openai_cli ;;
            4) install_copilot_cli ;;
            5) install_cursor ;;
            *) echo -e "  ${RED}Unknown option: $item${NC}" ;;
        esac
    done

    echo -e "\n${GREEN}${BOLD}Setup complete!${NC}"
    echo -e "  Reload shell: ${BOLD}source ~/.bashrc${NC}"
}

# ── Entry point ──
main() {
    echo -e "\n${BOLD}╔══════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║       AI Development Tools Setup     ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════╝${NC}"
    echo -e "  OS: $(. /etc/os-release && echo "$PRETTY_NAME")"
    echo -e "  Host: $(hostname)"
    echo ""

    if [ "$DISTRO" = "unknown" ]; then
        echo -e "${RED}Unsupported distribution. Supports Debian/Ubuntu and Rocky/AlmaLinux.${NC}"
        exit 1
    fi

    show_menu
    run_installs "$choices"

    # Mark as done
    touch "$MARKER"
}

main "$@"
