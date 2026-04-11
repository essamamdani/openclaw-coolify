# OpenClaw aka (Clawdbot, MoltBot) (Coolify Edition)

**Your Assistant. Your Machine. Your Rules.**

OpenClaw aka (Clawdbot, MoltBot) is an open agent platform that runs on your machine and works from the chat apps you already use. WhatsApp, Telegram, Discord, Slack, Teams—wherever you are, your AI assistant follows.

Unlike SaaS assistants where your data lives on someone else’s servers, OpenClaw runs where you choose—laptop, homelab, or VPS. Your infrastructure. Your keys. Your data.

---

## 🚀 Easy Setup on Coolify

1.  Open your Coolify Dashboard.
2.  Navigate to **Project** > **New**.
3.  Select **Public Repository**.
4.  Enter the URL: `https://github.com/essamamdani/openclaw-coolify`
5.  Switch Build Pack to **Docker Compose**
6.  Click **Continue**.

---

## 📦 Post-Deployment (Ready)
Once the container is running and healthy:

1.  **Access the Dashboard**:
    - Open the **Service Logs** in Coolify.
    - Look for: `🦞 OPENCLAW READY`.
    - You will see a **Dashboard URL** with a token (e.g., `https://.../?token=xyz`).
    - **Click that link** to access your OpenClaw Gateway UI.
2.  **Approve Your Device**:
    - You will see an "Unauthorized" or pairing screen (this is normal).
    - Open the **Service Terminal** in Coolify.
    - Run: `openclaw-approve`
    - > [!WARNING]
    - > **Security Note**: `openclaw-approve` is a break-glass utility that auto-accepts ALL pending pairing requests. Only run this immediately after accessing the URL yourself. Do not leave it running or use it when you don't recognize a request.
3.  **Guided Onboarding**: To configure your agent's personality and skills:
    - In the terminal, run: `openclaw onboard`
    - Follow the interactive wizard.
4.  **Configure Channels**: Go to the **Channels** tab in the dashboard to link WhatsApp, Telegram, etc.

---

## � Channel Setup

OpenClaw lives where you work. You can connect it to WhatsApp, Telegram, Discord, etc.

### 📱 Telegram
**Fastest setup.**
1.  Talk to **@BotFather** on Telegram.
2.  Create a new bot (`/newbot`) and get the **Token**.
3.  Add `TELEGRAM_BOT_TOKEN` to your Coolify Environment Variables.
4.  **Redeploy** (or just restart).
5.  DM your new bot. It will ask for a **Pairing Code**.
6.  Go to your OpenClaw Dashboard > **Pairing** to approve it.
    *   *Docs: [Telegram Channel Guide](docs/channels/telegram.md)*

### 🟢 WhatsApp
**Requires scanning a QR code.**
1.  Go to your OpenClaw Dashboard (from the logs).
2.  Navigate to **Channels** > **WhatsApp**.
3.  Open WhatsApp on your phone > **Linked Devices** > **Link a Device**.
4.  Scan the QR code shown on the dashboard.
5.  **Done!** You can now chat with OpenClaw.
    *   *Docs: [WhatsApp Channel Guide](docs/channels/whatsapp.md)*

### ⚡ Other Channels
You can verify status or manage other channels (Discord, Slack) via the dashboard or CLI.
*   *CLI Docs: [Channel Management](docs/cli/channels.md)*

---

## 📦 ClawHub & Skills

**ClawHub** is the public skill registry for OpenClaw. It allows you to easily find, install, and share capabilities for your agent.

### Quick Start
1.  **Search** for a skill:
    ```bash
    clawhub search "calendar"
    ```
2.  **Install** it:
    ```bash
    clawhub install <skill-slug>
    ```
3.  **Use it**: Restart your session, and the agent will have the new capabilities.

### CLI Commands
The `clawhub` CLI is pre-installed in your container.

| Command | Description |
| :--- | :--- |
| `clawhub search "query"` | Find skills by name or tag. |
| `clawhub install <slug>` | Install a skill into your workspace. |
| `clawhub update --all` | Update all installed skills to the latest version. |
| `clawhub login` | Login to publish your own skills. |
| `clawhub publish` | Publish a skill from the current directory. |

### How it Works
A skill is a folder containing a `SKILL.md` (instructions) and supporting files. When you install a skill, it is downloaded to your workspace. OpenClaw automatically loads these skills, giving your agent new powers without writing code.

---



## � Architecture: The AI Office

Think of this Docker container not as an app, but as an **Office Building**.

### 1. The Staff (Multi-Agent System)
*   **The Manager (Gateway)**: The main `openclaw` process. It hires "staff" to do work.
*   **The Workers (Sandboxes)**: When you ask for a complex coding task, the Manager spins up **isolated Docker containers** (sub-agents).
    *   They have their own Linux tools (Python, Node, Go).
    *   They work safely in a sandbox, then report back.
    *   *Managed via: Docker Socket Proxy (Secure Sidecar).*

### 2. Corporate Memory (Long-Term Storage)
Your office never forgets, thanks to a 3-tier memory architecture:
*   **The Filing Cabinet (`openclaw-workspace`)**: A persistent Docker Volume where agents write code, save files, and store heavy data. Survives restarts.
*   **The Brain (Internal SQLite)**: OpenClaw's native transactional memory for conversations and facts.
*   **Web Search (SearXNG)**: A private, tracking-free search engine (`searxng:8080`) for the agent's research.

### 3. The Security Vault
Your agent can securely manage credentials without leaking them:
*   **Bitwarden (`rbw`)**: Securely fetch secrets from your Bitwarden vault.
*   **Pass**: Local GPG-encrypted password storage for the agent's exclusive use.

### 4. The Public Front Door (Cloudflare Tunnel)
Need to show a client your work?
*   The agent can start a web server (e.g., Next.js on port 3000).
*   It uses `cloudflared` to instantly create a **secure public URL** (e.g., `https://project-viz.trycloudflare.com`).
*   *No router port forwarding required.*

### 5. Advanced Web Utilities
*   **Universal Scraper**: 5-stage fallback engine (Curl -> AI Browser -> Anti-Detect) to read any website.
*   **Research Tools**: `hackernews-cli`, `tuir` (Reddit), `newsboat` (RSS), `sonos` control.

### 6. Zero-Config & Production Ready
*   **Pre-installed Tools**: `gh` (GitHub), `vercel`, `bun`, `python`, `ripgrep`.
*   **Office Suite**: `pandoc` (Docs), `marp` (Slides), `csvkit` (Excel), `qmd` (Local AI Search).
*   **Secure**: All sub-agents are firewalled.
*   **Self-Healing**: Docker volumes ensure `openclaw-config` and `openclaw-workspace` persist forever.

---


## 🔒 Security & Sandboxing

- **Authentication**: Dashboard is token-protected. New chat users must be "paired" (approved) first.
- **Docker Proxy**: This setup uses a **Sockety Proxy (Sidecar)** pattern.
    - OpenClaw talks to a restricted Docker API proxy (`tcp://docker-proxy:2375`).
    - **Blocked**: Swarm, Secrets, System, Volumes, and other critical host functions.
    - **Allowed**: Only what's needed for sandboxing (Containers, Images, Networks).
- **Isolation**: Sub-agents run in disposable containers. `SOUL.md` rules forbid the agent from touching your other Coolify services.

---

## ❓ FAQ & Troubleshooting

### Usage
*   **Q: How do I install extra tools like `nmap` or `ffmpeg`?**
    *   **A**: Don't edit the Dockerfile! Use **Skills**.
    *   Create a folder `skills/my-tools` with a `SKILL.md` file instructing the agent to "Use apt-get to install ffmpeg".
    *   Or install a pre-made skill: `clawhub install web-utils`.

### Requirements
*   **Q: How much space do I need on my Coolify server to install openclaw-coolify ?**
    *   **A**: Make sure to have approximately 13 GB of free space, even if all are not used, this is what is required in docker build cache during the install process.

### Connection Issues
*   **Q: "No available server" or "502 Bad Gateway" on Coolify?**
    *   **A**: Ensure your `docker-compose.yaml` has `expose: ["18789"]` (fixed in latest version).
    *   **A**: Check logs for `OpenClaw listening on 18789`. If it says `127.0.0.1`, Traefik cannot reach it. It *must* listen on `0.0.0.0` or `lan` (default).

*   **Q: I can't connect from my Mac/PC?**
    *   **A**: Use the **Public URL** generated by Coolify (e.g., `https://openclaw.my-server.com`).
    *   **A**: DO NOT try to connect to `http://<server-ip>:18789` directly unless you manually opened that port in your server's firewall (UFW/AWS Security Group). The default setup uses reverse proxying for security.

*   **Q: `minimax-portal-auth` failed to load?**
    *   **A**: This is a known warning from an optional plugin. You can safely ignore it; it does not affect the agent's core functionality.
