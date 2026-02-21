# syntax=docker/dockerfile:1
# Multi-stage build for optimal caching with BuildKit
# Each stage builds on the previous, with COPY . . only in the final stage
# BuildKit features: cache mounts, parallel builds, improved layer caching

# Stage 1: Base system dependencies (rarely changes)
# Pin Node version to 22 to avoid compatibility issues with better-sqlite3
FROM node:22-bookworm-slim AS base

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_ROOT_USER_ACTION=ignore

# Install Core & Power Tools + Docker CLI (client only)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    python3 \
    python3-pip \
    python3-venv \
    jq \
    lsof \
    openssl \
    ca-certificates \
    gnupg \
    ripgrep fd-find fzf bat \
    pandoc \
    poppler-utils \
    ffmpeg \
    imagemagick \
    graphviz \
    sqlite3 \
    pass \
    chromium \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Stage 2: System CLI tools (change occasionally)
FROM base AS system-tools

# Install Docker CE CLI (Latest) to support API 1.44+
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Install Go (Latest)
RUN curl -L "https://go.dev/dl/go1.23.4.linux-amd64.tar.gz" -o go.tar.gz && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz

# Install Cloudflare Tunnel (cloudflared)
RUN ARCH=$(dpkg --print-architecture) && \
    curl -L --output cloudflared.deb "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}.deb" && \
    dpkg -i cloudflared.deb && \
    rm cloudflared.deb

# Install GitHub CLI (gh)
RUN mkdir -p -m 755 /etc/apt/keyrings && \
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

# Install uv (Python tool manager)
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Stage 3: Language runtimes and package managers (change sometimes)
FROM system-tools AS runtimes

ENV BUN_INSTALL_NODE=0 \
    BUN_INSTALL="/data/.bun" \
    PATH="/usr/local/go/bin:/data/.bun/bin:/data/.bun/install/global/bin:$PATH"

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

# Python tools
RUN pip3 install ipython csvkit openpyxl python-docx pypdf botasaurus browser-use playwright --break-system-packages && \
    playwright install-deps

# Configure QMD Persistence
ENV XDG_CACHE_HOME="/data/.cache"

# Debian aliases
RUN ln -s /usr/bin/fdfind /usr/bin/fd || true && \
    ln -s /usr/bin/batcat /usr/bin/bat || true

# Stage 4: Application dependencies (package installations)
FROM runtimes AS dependencies

# OpenClaw install (version: OPENCLAW_VERSION env at build, or latest; OPENCLAW_BETA=true → beta)
ARG OPENCLAW_BETA=false
ARG OPENCLAW_VERSION=
ENV OPENCLAW_BETA=${OPENCLAW_BETA} \
    OPENCLAW_VERSION=${OPENCLAW_VERSION} \
    OPENCLAW_NO_ONBOARD=1 \
    NPM_CONFIG_UNSAFE_PERM=true

# Install node-gyp first to support native module compilation (e.g., better-sqlite3)
RUN npm install -g node-gyp

# Install Vercel, Marp, QMD with BuildKit cache mount for faster rebuilds
RUN --mount=type=cache,target=/data/.bun/install/cache \
    bun install -g vercel @marp-team/marp-cli https://github.com/tobi/qmd && hash -r && \
    bun pm -g untrusted && \
    bun install -g @openai/codex @google/gemini-cli opencode-ai @steipete/summarize @hyperbrowser/agent clawhub

# Install OpenClaw (OPENCLAW_BETA=beta | OPENCLAW_VERSION=x.y.z | else latest)
RUN --mount=type=cache,target=/data/.npm \
    set -e; \
    if [ "$OPENCLAW_BETA" = "true" ]; then \
      echo "Installing openclaw@beta"; npm install -g openclaw@beta; \
    elif [ -n "$OPENCLAW_VERSION" ]; then \
      echo "Installing openclaw@${OPENCLAW_VERSION}"; npm install -g "openclaw@${OPENCLAW_VERSION}"; \
    else \
      echo "Installing openclaw@latest"; npm install -g openclaw@latest; \
    fi && \
    if command -v openclaw >/dev/null 2>&1; then \
      echo "✅ openclaw binary found"; openclaw --version 2>/dev/null || true; \
    else \
      echo "❌ OpenClaw install failed (binary 'openclaw' not found)"; exit 1; \
    fi

# AI Tool Suite & ClawHub
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    curl -L https://code.kimi.com/install.sh | bash

# Stage 5: Final application stage (changes frequently)
FROM dependencies AS final

WORKDIR /app

# Copy everything (obeying .dockerignore)
# This is the only layer that changes on code updates
COPY . .

# Specialized symlinks and permissions
RUN ln -sf /data/.claude/bin/claude /usr/local/bin/claude 2>/dev/null || true && \
    ln -sf /data/.kimi/bin/kimi /usr/local/bin/kimi 2>/dev/null || true && \
    ln -sf /app/scripts/openclaw-approve.sh /usr/local/bin/openclaw-approve && \
    chmod +x /app/scripts/*.sh /usr/local/bin/openclaw-approve

# ✅ FINAL PATH (important)
ENV PATH="/usr/local/go/bin:/usr/local/bin:/usr/bin:/bin:/data/.local/bin:/data/.npm-global/bin:/data/.bun/bin:/data/.bun/install/global/bin:/data/.claude/bin:/data/.kimi/bin"

EXPOSE 18789
CMD ["bash", "/app/scripts/bootstrap.sh"]
