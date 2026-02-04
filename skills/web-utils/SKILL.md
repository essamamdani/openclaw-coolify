---
name: web-utils
description: Advanced web tools for searching, summarizing, and scraping content.
metadata:
  openclaw:
    emoji: 🌐
    requires:
      bins: ["curl", "bun", "python3"]
      services: ["searxng"]
    install:
      # These are installed in Dockerfile, but listed here for documentation
      - id: "summarize"
        kind: "bun"
        pkg: "@steipete/summarize"
      - id: "botasaurus"
        kind: "pip"
        pkg: "botasaurus"
---

# Web Utilities

This skill provides advanced capabilities for interacting with the web.

## Actions

### Web Search (SearXNG)
Search the web using a private SearXNG instance. Returns JSON results.
```bash
{baseDir}/scripts/search.sh "query string"
```

### Summarize Strategy
Summarize the content of a URL (text or video) using AI.
```bash
{baseDir}/scripts/summarize.sh "https://example.com/article"
```

### Advanced Scrape
Fetch web content. Supports basic `curl`, `browser` (Headless Chromium), or `botasaurus` logic.
```bash
# Basic (fast)
{baseDir}/scripts/scrape.sh --mode curl "https://example.com"

# Advanced (JavaScript support)
{baseDir}/scripts/scrape.sh --mode browser "https://example.com"
```
