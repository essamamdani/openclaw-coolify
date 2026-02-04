FROM node:22-bookworm

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_ROOT_USER_ACTION=ignore

# ============================================
# LAYER 1: System packages (rarely changes - cached)
# ============================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    lsof \
    openssl \
    ca-certificates \
    gnupg \
    unzip \
    ripgrep \
    fd-find \
    fzf \
    bat \
    pandoc \
    poppler-utils \
    ffmpeg \
    imagemagick \
    graphviz \
    sqlite3 \
    pass \
    chromium \
    && rm -rf /var/lib/apt/lists/*

# Debian aliases
RUN ln -s /usr/bin/fdfind /usr/bin/fd 2>/dev/null || true && \
    ln -s /usr/bin/batcat /usr/bin/bat 2>/dev/null || true

# ============================================
# LAYER 2: Docker CLI (rarely changes - cached)
# ============================================
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# LAYER 3: Go (rarely changes - cached)
# ============================================
RUN curl -L "https://go.dev/dl/go1.23.4.linux-amd64.tar.gz" -o go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"

# ============================================
# LAYER 4: GitHub CLI (rarely changes - cached)
# ============================================
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# ============================================
# LAYER 5: Cloudflared (rarely changes - cached)
# ============================================
RUN ARCH=$(dpkg --print-architecture) && \
    curl -L --output cloudflared.deb "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb" && \
    dpkg -i cloudflared.deb && \
    rm cloudflared.deb

# ============================================
# LAYER 6: Bun (rarely changes - cached)
# ============================================
ENV BUN_INSTALL="/root/.bun"
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:/root/.bun/install/global/bin:${PATH}"

# ============================================
# LAYER 7: UV Python tool manager (rarely changes - cached)
# ============================================
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# ============================================
# LAYER 8: Python packages (rarely changes - cached)
# ============================================
RUN pip3 install --break-system-packages \
    ipython \
    csvkit \
    openpyxl \
    python-docx \
    pypdf \
    botasaurus \
    browser-use \
    playwright && \
    playwright install-deps && \
    playwright install chromium

# ============================================
# LAYER 9: Global Bun packages (rarely changes - cached)
# ============================================
RUN bun install -g \
    vercel \
    @marp-team/marp-cli \
    https://github.com/tobi/qmd

# ============================================
# LAYER 10: OpenClaw (changes on version bump)
# ============================================
ARG OPENCLAW_BETA=false
ARG OPENCLAW_VERSION=2026.2.2-3
ENV OPENCLAW_NO_ONBOARD=1 \
    NPM_CONFIG_UNSAFE_PERM=true

RUN if [ "$OPENCLAW_BETA" = "true" ]; then \
        npm install -g openclaw@beta; \
    else \
        npm install -g openclaw@${OPENCLAW_VERSION}; \
    fi && \
    openclaw --version

# ============================================
# LAYER 11: AI Tool Suite (changes occasionally)
# ============================================
RUN bun pm -g untrusted && \
    bun install -g \
    @openai/codex \
    @google/gemini-cli \
    opencode-ai \
    @steipete/summarize \
    @hyperbrowser/agent \
    clawhub

# Claude CLI & Kimi CLI
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    curl -L https://code.kimi.com/install.sh | bash

# ============================================
# LAYER 12: Scripts & Skills (changes frequently - LAST!)
# ============================================
WORKDIR /app

# Copy scripts, skills, and workspace files
COPY scripts/ /app/scripts/
COPY skills/ /app/skills/
COPY workspace-files/ /app/workspace-files/
COPY SOUL.md /app/
COPY BOOTSTRAP.md /app/

# Set permissions and create symlinks
RUN chmod +x /app/scripts/*.sh && \
    find /app/skills -type f -name "*.sh" -exec chmod +x {} \; && \
    ln -sf /root/.claude/bin/claude /usr/local/bin/claude 2>/dev/null || true && \
    ln -sf /root/.kimi/bin/kimi /usr/local/bin/kimi 2>/dev/null || true && \
    ln -sf /app/scripts/openclaw-approve.sh /usr/local/bin/openclaw-approve

# ============================================
# FINAL: Environment & Entrypoint
# ============================================
ENV PATH="/usr/local/go/bin:/usr/local/bin:/usr/bin:/bin:/root/.local/bin:/root/.bun/bin:/root/.bun/install/global/bin:/root/.claude/bin:/root/.kimi/bin:/root/go/bin" \
    XDG_CACHE_HOME="/root/.openclaw/cache"

EXPOSE 18789
CMD ["bash", "/app/scripts/bootstrap.sh"]
