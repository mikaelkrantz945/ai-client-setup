# AI Client Setup

Interactive AI tool installer for cloud VMs. First-login wizard that lets users choose which AI tools to install.

## Supported AI Tools

| Tool | What it does | Requires |
|------|-------------|----------|
| **Claude Code** | Anthropic's coding assistant CLI | Anthropic API key |
| **Aider** | AI pair programming (Claude/GPT) | Anthropic or OpenAI API key |
| **OpenAI CLI** | ChatGPT/GPT-4 in the terminal | OpenAI API key |
| **Copilot CLI** | GitHub Copilot (`gh copilot`) | GitHub auth |
| **Cursor** | AI code editor (AppImage) | Desktop environment |

## Supported Distributions

- Debian 13 (Trixie)
- Ubuntu 24.04 (Noble)
- AlmaLinux 9
- Rocky Linux 9

## How it works

1. User logs in via SSH for the first time
2. Prompt: "Set up AI tools now? [Y/n]"
3. Menu to select tools (comma-separated or all)
4. Installs tools + dependencies (Node.js, Python, etc)
5. Prompts for API keys
6. Marks as done (won't prompt again)

Users can also run `ai-setup` manually at any time.

## Quick start (standalone)

```bash
curl -fsSL https://raw.githubusercontent.com/mikaelkrantz945/ai-client-setup/main/ai-setup.sh -o /usr/local/bin/ai-setup
chmod +x /usr/local/bin/ai-setup
ai-setup
```

## Proxmox Cloud-Init Templates

Pre-built Proxmox VM templates with AI setup baked in. Run on a Proxmox host:

```bash
git clone https://github.com/mikaelkrantz945/ai-client-setup.git
cd ai-client-setup/cloud-init

# Build the template you want:
bash debian-13.sh      # VM ID 9915
bash ubuntu-24.04.sh   # VM ID 9910
bash alma-9.sh         # VM ID 9916
bash rocky-9.sh        # VM ID 9917
```

### Template IDs

| Template | VM ID | Image |
|----------|-------|-------|
| Debian 13 | 9915 | debian-13-genericcloud-amd64 |
| Ubuntu 24.04 | 9910 | noble-server-cloudimg-amd64 |
| AlmaLinux 9 | 9916 | AlmaLinux-9-GenericCloud |
| Rocky Linux 9 | 9917 | Rocky-9-GenericCloud |

### What's included in templates

Base packages: `qemu-guest-agent`, `mtr`, `traceroute`, `htop`, `curl`, `git`

AI setup: `ai-setup` command + first-login auto-prompt

### Customization

Edit variables at the top of each cloud-init script:

```bash
VMID=9915            # Proxmox VM ID
STORAGE="data-pool"  # Proxmox storage
BRIDGE="vmbr0"       # Network bridge
```
