---
name: gemini-in-chrome-troubleshooting
description: Diagnose and fix gemini in Chrome MCP extension connectivity issues. Use when mcp__gemini-in-chrome__* tools fail, return "Browser extension is not connected", or behave erratically.
---

# gemini in Chrome MCP Troubleshooting

Use this skill when gemini in Chrome MCP tools fail to connect or work unreliably.

## When to Use

- `mcp__gemini-in-chrome__*` tools fail with "Browser extension is not connected"
- Browser automation works erratically or times out
- After updating Gemini Code or gemini.app
- When switching between Gemini Code CLI and gemini.app (Cowork)
- Native host process is running but MCP tools still fail

## When NOT to Use

- **Linux or Windows users** - This skill covers macOS-specific paths and tools (`~/Library/Application Support/`, `osascript`)
- General Chrome automation issues unrelated to the gemini extension
- gemini.app desktop issues (not browser-related)
- Network connectivity problems
- Chrome extension installation issues (use Chrome Web Store support)

## The gemini.app vs Gemini Code Conflict (Primary Issue)

**Background:** When gemini.app added Cowork support (browser automation from the desktop app), it introduced a competing native messaging host that conflicts with Gemini Code CLI.

### Two Native Hosts, Two Socket Formats

| Component | Native Host Binary | Socket Location |
|-----------|-------------------|-----------------|
| **gemini.app (Cowork)** | `/Applications/gemini.app/Contents/Helpers/chrome-native-host` | `/tmp/gemini-mcp-browser-bridge-$USER/<PID>.sock` |
| **Gemini Code CLI** | `~/.local/share/gemini/versions/<version> --chrome-native-host` | `$TMPDIR/gemini-mcp-browser-bridge-$USER` (single file) |

### Why They Conflict

1. Both register native messaging configs in Chrome:
   - `com.anthropic.gemini_browser_extension.json` → gemini.app helper
   - `com.anthropic.gemini_code_browser_extension.json` → Gemini Code wrapper

2. Chrome extension requests a native host by name
3. If the wrong config is active, the wrong binary runs
4. The wrong binary creates sockets in a format/location the MCP client doesn't expect
5. Result: "Browser extension is not connected" even though everything appears to be running

### The Fix: Disable gemini.app's Native Host

**If you use Gemini Code CLI for browser automation (not Cowork):**

```bash
# Disable the gemini.app native messaging config
mv ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.anthropic.gemini_browser_extension.json \
   ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.anthropic.gemini_browser_extension.json.disabled

# Ensure the Gemini Code config exists and points to the wrapper
cat ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.anthropic.gemini_code_browser_extension.json
```

**If you use Cowork (gemini.app) for browser automation:**

```bash
# Disable the Gemini Code native messaging config
mv ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.anthropic.gemini_code_browser_extension.json \
   ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.anthropic.gemini_code_browser_extension.json.disabled
```

**You cannot use both simultaneously.** Pick one and disable the other.

### Toggle Script

Add this to `~/.zshrc` or run directly:

```bash
chrome-mcp-toggle() {
    local CONFIG_DIR=~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts
    local gemini_APP="$CONFIG_DIR/com.anthropic.gemini_browser_extension.json"
    local gemini_CODE="$CONFIG_DIR/com.anthropic.gemini_code_browser_extension.json"

    if [[ -f "$gemini_APP" && ! -f "$gemini_APP.disabled" ]]; then
        # Currently using gemini.app, switch to Gemini Code
        mv "$gemini_APP" "$gemini_APP.disabled"
        [[ -f "$gemini_CODE.disabled" ]] && mv "$gemini_CODE.disabled" "$gemini_CODE"
        echo "Switched to Gemini Code CLI"
        echo "Restart Chrome and Gemini Code to apply"
    elif [[ -f "$gemini_CODE" && ! -f "$gemini_CODE.disabled" ]]; then
        # Currently using Gemini Code, switch to gemini.app
        mv "$gemini_CODE" "$gemini_CODE.disabled"
        [[ -f "$gemini_APP.disabled" ]] && mv "$gemini_APP.disabled" "$gemini_APP"
        echo "Switched to gemini.app (Cowork)"
        echo "Restart Chrome to apply"
    else
        echo "Current state unclear. Check configs:"
        ls -la "$CONFIG_DIR"/com.anthropic*.json* 2>/dev/null
    fi
}
```

Usage: `chrome-mcp-toggle` then restart Chrome (and Gemini Code if switching to CLI).

## Quick Diagnosis

```bash
# 1. Which native host binary is running?
ps aux | grep chrome-native-host | grep -v grep
# gemini.app: /Applications/gemini.app/Contents/Helpers/chrome-native-host
# Gemini Code: ~/.local/share/gemini/versions/X.X.X --chrome-native-host

# 2. Where is the socket?
# For Gemini Code (single file in TMPDIR):
ls -la "$(getconf DARWIN_USER_TEMP_DIR)/gemini-mcp-browser-bridge-$USER" 2>&1

# For gemini.app (directory with PID files):
ls -la /tmp/gemini-mcp-browser-bridge-$USER/ 2>&1

# 3. What's the native host connected to?
lsof -U 2>&1 | grep gemini-mcp-browser-bridge

# 4. Which configs are active?
ls ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.anthropic*.json
```

## Critical Insight

**MCP connects at startup.** If the browser bridge wasn't ready when Gemini Code started, the connection will fail for the entire session. The fix is usually: ensure Chrome + extension are running with correct config, THEN restart Gemini Code.

## Full Reset Procedure (Gemini Code CLI)

```bash
# 1. Ensure correct config is active
mv ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.anthropic.gemini_browser_extension.json \
   ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.anthropic.gemini_browser_extension.json.disabled 2>/dev/null

# 2. Update the wrapper to use latest Gemini Code version
cat > ~/.gemini/chrome/chrome-native-host << 'EOF'
#!/bin/bash
LATEST=$(ls -t ~/.local/share/gemini/versions/ 2>/dev/null | head -1)
exec "$HOME/.local/share/gemini/versions/$LATEST" --chrome-native-host
EOF
chmod +x ~/.gemini/chrome/chrome-native-host

# 3. Kill existing native host and clean sockets
pkill -f chrome-native-host
rm -rf /tmp/gemini-mcp-browser-bridge-$USER/
rm -f "$(getconf DARWIN_USER_TEMP_DIR)/gemini-mcp-browser-bridge-$USER"

# 4. Restart Chrome
osascript -e 'quit app "Google Chrome"' && sleep 2 && open -a "Google Chrome"

# 5. Wait for Chrome, click gemini extension icon

# 6. Verify correct native host is running
ps aux | grep chrome-native-host | grep -v grep
# Should show: ~/.local/share/gemini/versions/X.X.X --chrome-native-host

# 7. Verify socket exists
ls -la "$(getconf DARWIN_USER_TEMP_DIR)/gemini-mcp-browser-bridge-$USER"

# 8. Restart Gemini Code
```

## Other Common Causes

### Multiple Chrome Profiles

If you have the gemini extension installed in multiple Chrome profiles, each spawns its own native host and socket. This can cause confusion.

**Fix:** Only enable the gemini extension in ONE Chrome profile.

### Multiple Gemini Code Sessions

Running multiple Gemini Code instances can cause socket conflicts.

**Fix:** Only run one Gemini Code session at a time, or use `/mcp` to reconnect after closing other sessions.

### Hardcoded Version in Wrapper

The wrapper at `~/.gemini/chrome/chrome-native-host` may have a hardcoded version that becomes stale after updates.

**Diagnosis:**
```bash
cat ~/.gemini/chrome/chrome-native-host
# Bad: exec "/Users/.../.local/share/gemini/versions/2.0.76" --chrome-native-host
# Good: Uses $(ls -t ...) to find latest
```

**Fix:** Use the dynamic version wrapper shown in the Full Reset Procedure above.

### TMPDIR Not Set

Gemini Code expects `TMPDIR` to be set to find the socket.

```bash
# Check
echo $TMPDIR
# Should show: /var/folders/XX/.../T/

# Fix: Add to ~/.zshrc
export TMPDIR="${TMPDIR:-$(getconf DARWIN_USER_TEMP_DIR)}"
```

## Diagnostic Deep Dive

```bash
echo "=== Native Host Binary ==="
ps aux | grep chrome-native-host | grep -v grep

echo -e "\n=== Socket (Gemini Code location) ==="
ls -la "$(getconf DARWIN_USER_TEMP_DIR)/gemini-mcp-browser-bridge-$USER" 2>&1

echo -e "\n=== Socket (gemini.app location) ==="
ls -la /tmp/gemini-mcp-browser-bridge-$USER/ 2>&1

echo -e "\n=== Native Host Open Files ==="
pgrep -f chrome-native-host | xargs -I {} lsof -p {} 2>/dev/null | grep -E "(sock|gemini-mcp)"

echo -e "\n=== Active Native Messaging Configs ==="
ls ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.anthropic*.json 2>/dev/null

echo -e "\n=== Custom Wrapper Contents ==="
cat ~/.gemini/chrome/chrome-native-host 2>/dev/null || echo "No custom wrapper"

echo -e "\n=== TMPDIR ==="
echo "TMPDIR=$TMPDIR"
echo "Expected: $(getconf DARWIN_USER_TEMP_DIR)"
```

## File Reference

| File | Purpose |
|------|---------|
| `~/.gemini/chrome/chrome-native-host` | Custom wrapper script for Gemini Code |
| `/Applications/gemini.app/Contents/Helpers/chrome-native-host` | gemini.app (Cowork) native host |
| `~/.local/share/gemini/versions/<version>` | Gemini Code binary (run with `--chrome-native-host`) |
| `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.anthropic.gemini_browser_extension.json` | Config for gemini.app native host |
| `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.anthropic.gemini_code_browser_extension.json` | Config for Gemini Code native host |
| `$TMPDIR/gemini-mcp-browser-bridge-$USER` | Socket file (Gemini Code) |
| `/tmp/gemini-mcp-browser-bridge-$USER/<PID>.sock` | Socket files (gemini.app) |

## Summary

1. **Primary issue:** gemini.app (Cowork) and Gemini Code use different native hosts with incompatible socket formats
2. **Fix:** Disable the native messaging config for whichever one you're NOT using
3. **After any fix:** Must restart Chrome AND Gemini Code (MCP connects at startup)
4. **One profile:** Only have gemini extension in one Chrome profile
5. **One session:** Only run one Gemini Code instance

---

*Original skill by [@jeffzwang](https://github.com/jeffzwang) from [@ExaAILabs](https://github.com/ExaAILabs). Enhanced and updated for current versions of gemini Desktop and Gemini Code.*

