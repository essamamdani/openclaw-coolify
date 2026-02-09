# =============================================================================
# STAGE 1: BASE IMAGE WITH SYSTEM DEPENDENCIES
# =============================================================================
FROM node:22-bookworm AS base

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_ROOT_USER_ACTION=ignore

# ============================================
# LAYER 1: System packages (rarely changes)
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
# LAYER 2: Docker CLI
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
# LAYER 3: Go
# ============================================
RUN curl -L "https://go.dev/dl/go1.23.4.linux-amd64.tar.gz" -o go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz
ENV PATH="/usr/local/go/bin:/root/go/bin:${PATH}"

# ============================================
# LAYER 4: GitHub CLI
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
# LAYER 5: Cloudflared
# ============================================
RUN ARCH=$(dpkg --print-architecture) && \
    curl -L --output cloudflared.deb "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb" && \
    dpkg -i cloudflared.deb && \
    rm cloudflared.deb

# ============================================
# LAYER 6: Bun
# ============================================
ENV BUN_INSTALL="/root/.bun"
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:/root/.bun/install/global/bin:${PATH}"

# ============================================
# LAYER 7: UV Python tool manager
# ============================================
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# ============================================
# LAYER 8: Python packages (cached)
# ============================================
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3 install --break-system-packages \
    ipython \
    csvkit \
    openpyxl \
    python-docx \
    pypdf \
    botasaurus \
    browser-use \
    playwright \
    nano-pdf \
    yt-dlp

# ============================================
# LAYER 9: Playwright browsers
# ============================================
RUN playwright install-deps && \
    playwright install chromium

# ============================================
# LAYER 10: Global Bun packages
# ============================================
RUN bun install -g \
    vercel \
    @marp-team/marp-cli \
    @steipete/bird \
    clawhub \
    https://github.com/tobi/qmd

# ============================================
# LAYER 11: OpenClaw (auto-updates to latest stable)
# ============================================
ARG OPENCLAW_BETA=false
ENV OPENCLAW_NO_ONBOARD=1 \
    NPM_CONFIG_UNSAFE_PERM=true

RUN --mount=type=cache,target=/root/.npm \
    if [ "$OPENCLAW_BETA" = "true" ]; then \
        npm install -g openclaw@beta; \
    else \
        npm install -g openclaw@latest; \
    fi && \
    openclaw --version

# ============================================
# LAYER 12: AI Tool Suite
# ============================================
RUN bun pm -g untrusted && \
    bun install -g \
    @openai/codex \
    opencode-ai \
    @steipete/summarize \
    @hyperbrowser/agent

# Install Gemini CLI via npm for better compatibility
RUN --mount=type=cache,target=/root/.npm \
    npm install -g @google/gemini-cli

# Claude CLI & Kimi CLI
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    curl -L https://code.kimi.com/install.sh | bash

# ============================================
# LAYER 13: gog CLI (Google Workspace CLI)
# ============================================
RUN mkdir -p /root/.cache/go-build && \
    GOTMPDIR=/root/.cache/go-build go install github.com/steipete/gogcli/cmd/gog@latest && \
    ln -sf /root/go/bin/gog /usr/local/bin/gog

# =============================================================================
# STAGE 2: RUNTIME IMAGE
# =============================================================================
FROM base AS runtime

# ============================================
# Runtime environment for writable tools
# ============================================
ENV PYTHONUSERBASE=/root/.openclaw/python \
    NPM_CONFIG_PREFIX=/root/.openclaw/npm \
    XDG_CACHE_HOME="/root/.openclaw/cache" \
    PATH="/root/.openclaw/npm/bin:/root/.openclaw/python/bin:${PATH}"

# ============================================
# LAYER 14: Scripts, Skills & Plugins
# ============================================
WORKDIR /app

# Copy scripts, skills, workspace files, and plugins
COPY scripts/ /app/scripts/
COPY skills/ /app/skills/
COPY workspace-files/ /app/workspace-files/
COPY extensions/ /app/extensions/
COPY openclaw.template.json /app/

# Set permissions and create symlinks
RUN chmod +x /app/scripts/*.sh && \
    find /app/skills -type f -name "*.sh" -exec chmod +x {} \; && \
    ln -sf /root/.claude/bin/claude /usr/local/bin/claude 2>/dev/null || true && \
    ln -sf /root/.kimi/bin/kimi /usr/local/bin/kimi 2>/dev/null || true && \
    ln -sf /app/scripts/openclaw-approve.sh /usr/local/bin/openclaw-approve

# ============================================
# FINAL: Entrypoint
# ============================================
EXPOSE 18789
CMD ["bash", "/app/scripts/bootstrap.sh"]
