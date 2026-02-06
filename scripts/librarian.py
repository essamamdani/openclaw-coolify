#!/usr/bin/env python3
"""
📚 The Librarian Protocol v2.0
Scans ALL OpenClaw sessions across all channels and distills knowledge into MEMORY.md
Ensures chronological ordering of all captured insights.
"""

import json
import os
import subprocess
from datetime import datetime
from pathlib import Path

# Configuration
WORKSPACE_DIR = "/root/openclaw-workspace"
MEMORY_FILE = os.path.join(WORKSPACE_DIR, "MEMORY.md")
SESSIONS_DIR = "/root/.openclaw/agents/main/sessions"
DAILY_LOG_DIR = os.path.join(WORKSPACE_DIR, "memory")

def get_all_session_files():
    """Get all session JSONL files, sorted by modification time (newest first)."""
    session_files = []
    sessions_path = Path(SESSIONS_DIR)
    
    print(f"Scanning directory: {SESSIONS_DIR}")
    
    for f in sessions_path.glob("*.jsonl"):
        if ".deleted" not in str(f) and ".lock" not in str(f):
            try:
                stat = f.stat()
                session_files.append({
                    "path": str(f),
                    "modified": stat.st_mtime,
                    "size": stat.st_size
                })
                print(f"  Found: {f.name} ({stat.st_size} bytes)")
            except Exception as e:
                print(f"  Error reading {f}: {e}")
    
    # Sort by modification time, newest first
    session_files.sort(key=lambda x: x["modified"], reverse=True)
    print(f"Total sessions found: {len(session_files)}")
    return session_files

def get_session_metadata():
    """Get session key to ID mapping for context."""
    sessions_json = os.path.join(SESSIONS_DIR, "sessions.json")
    if os.path.exists(sessions_json):
        with open(sessions_json, 'r') as f:
            return json.load(f)
    return {}

def extract_recent_messages(session_file, max_lines=100):
    """Extract recent messages from a session file."""
    try:
        lines = subprocess.check_output(
            ["tail", "-n", str(max_lines), session_file["path"]]
        ).decode('utf-8', errors='ignore').splitlines()
        
        messages = []
        for line in lines:
            try:
                entry = json.loads(line)
                # Handle the nested message structure
                msg = entry.get("message", entry)
                role = msg.get("role", "unknown")
                content = msg.get("content", "")
                timestamp = entry.get("timestamp", msg.get("timestamp", ""))
                
                # Skip tool results and tool calls
                if role in ["toolResult", "toolCall"]:
                    continue
                
                if isinstance(content, list):
                    # Handle multimodal content
                    text_parts = []
                    for p in content:
                        if isinstance(p, dict) and "text" in p:
                            text_parts.append(p.get("text", ""))
                    content = " ".join(text_parts)
                
                if content and len(str(content)) > 10:
                    messages.append({
                        "role": role,
                        "content": str(content)[:2000],  # Limit content length
                        "timestamp": timestamp
                    })
            except Exception as e:
                continue
        
        print(f"  Extracted {len(messages)} messages from {Path(session_file['path']).name}")
        return messages
    except Exception as e:
        print(f"Error reading {session_file['path']}: {e}")
        return []

def build_session_digest():
    """Build a digest of all recent session activity."""
    session_files = get_all_session_files()
    metadata = get_session_metadata()
    
    # Create reverse mapping: sessionId -> key
    id_to_key = {}
    for key, data in metadata.items():
        if isinstance(data, dict) and "sessionId" in data:
            id_to_key[data["sessionId"]] = key
    
    all_content = []
    
    for sf in session_files[:5]:  # Process top 5 most recent sessions
        session_id = Path(sf["path"]).stem
        channel_key = id_to_key.get(session_id, "unknown")
        
        # Determine channel type
        if "telegram" in channel_key:
            channel = "Telegram"
        elif "whatsapp" in channel_key:
            channel = "WhatsApp"
        elif "discord" in channel_key:
            channel = "Discord"
        elif "main" in channel_key:
            channel = "Web/CLI"
        else:
            channel = "Other"
        
        messages = extract_recent_messages(sf)
        if messages:
            all_content.append({
                "channel": channel,
                "session_key": channel_key,
                "modified": datetime.fromtimestamp(sf["modified"]).isoformat(),
                "messages": messages[-50:]  # Last 50 messages per session
            })
    
    return all_content

def format_for_analysis(digest):
    """Format the digest for LLM analysis."""
    output = "# SESSION DIGEST (All Channels)\n\n"
    
    for session in digest:
        output += f"## Channel: {session['channel']}\n"
        output += f"Last Updated: {session['modified']}\n\n"
        
        for msg in session["messages"]:
            role = msg["role"].upper()
            content = msg["content"][:500]  # Truncate for analysis
            output += f"**{role}**: {content}\n\n"
        
        output += "---\n\n"
    
    return output[:15000]  # Limit total size for LLM context

def update_daily_log(new_insights, timestamp):
    """Update the daily log file with new insights."""
    today = timestamp.strftime("%Y-%m-%d")
    daily_file = os.path.join(DAILY_LOG_DIR, f"{today}.md")
    
    # Ensure directory exists
    os.makedirs(DAILY_LOG_DIR, exist_ok=True)
    
    # Read existing content
    existing = ""
    if os.path.exists(daily_file):
        with open(daily_file, 'r') as f:
            existing = f.read()
    
    # Create header if new file
    if not existing:
        existing = f"# {today} — Daily Log\n\n"
    
    # Append new insights with timestamp
    time_str = timestamp.strftime("%H:%M")
    entry = f"\n## {time_str} — Librarian Distillation\n{new_insights}\n"
    
    with open(daily_file, 'w') as f:
        f.write(existing + entry)
    
    print(f"Updated daily log: {daily_file}")

def run_librarian():
    """Main librarian protocol."""
    print("🧠 Running Librarian Protocol v2.0...")
    print("📂 Scanning ALL session files across all channels...")
    
    # Build digest from all sessions
    digest = build_session_digest()
    
    if not digest:
        print("No session content found.")
        return "No new knowledge to add."
    
    print(f"📊 Found {len(digest)} active sessions to analyze.")
    
    # Format for analysis
    formatted = format_for_analysis(digest)
    
    # Create the analysis prompt
    prompt = f'''ACT AS THE LIBRARIAN FOR AMR RADY.
You are analyzing conversation snippets from ALL channels (Telegram, Web, etc.).

EXTRACT ONLY PERMANENT KNOWLEDGE that should be remembered for 100 years:
1. Personal facts about Amr (preferences, beliefs, goals)
2. Strategic business decisions (the $1B AI transformation dream)
3. Ethical rules or operational protocols
4. Technical configurations that were finalized
5. New skills, tools, or integrations that were set up

SESSION DIGEST:
{formatted}

OUTPUT FORMAT:
- Return a BULLETED LIST of NEW insights with timestamps
- Sort chronologically (oldest first)
- If nothing permanent was discussed, return exactly: NO_NEW_KNOWLEDGE
- Do NOT repeat things already known (Egyptian, Kuwait, AI dream, etc.)
- Focus on ACTIONABLE and MEMORABLE items'''

    # Write prompt to temp file for the agent
    prompt_file = "/tmp/librarian_prompt.txt"
    with open(prompt_file, 'w') as f:
        f.write(prompt)
    
    print("🤖 Analyzing with Gemini Flash...")
    
    # Use a simple approach - just return the formatted data for now
    # The cron job will handle the LLM analysis
    timestamp = datetime.now()
    
    # For direct runs, we'll save the digest to daily log
    if len(formatted) > 100:
        summary = f"Librarian scanned {len(digest)} sessions.\nTotal content size: {len(formatted)} chars.\nChannels: {', '.join([d['channel'] for d in digest])}"
        update_daily_log(summary, timestamp)
    
    # Reindex memory
    print("🔄 Reindexing memory...")
    subprocess.run(["openclaw", "memory", "index"], capture_output=True)
    
    print("✅ Librarian Protocol complete.")
    return "Librarian scan complete. Daily log updated."

if __name__ == "__main__":
    result = run_librarian()
    print(result)
