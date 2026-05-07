#!/usr/bin/env bash
# first-login.sh — Auto-prompt for AI setup on first login
# Installed to /etc/profile.d/ by cloud-init

MARKER="$HOME/.ai-setup-done"

if [ -f "$MARKER" ]; then
    return 0 2>/dev/null || exit 0
fi

# Only run in interactive shells
case $- in
    *i*) ;;
    *) return 0 2>/dev/null || exit 0 ;;
esac

echo ""
echo -e "\033[1m  Welcome! AI development tools are available for this VM.\033[0m"
echo ""
read -rp "  Set up AI tools now? [Y/n] " answer
case "$answer" in
    [nN]*)
        echo "  Skipped. Run 'ai-setup' anytime."
        touch "$MARKER"
        ;;
    *)
        ai-setup
        ;;
esac
