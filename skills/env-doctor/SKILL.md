---
name: env-doctor
description: >
  Diagnoses why a project, service, or dev environment won't start or is broken.
  Auto-invokes when user says "it's not working", "won't start", "broken",
  "error starting", or describes a startup failure. Runs systematic checks.
---

# Env Doctor

Systematically diagnose why the environment is broken.

## Diagnostic Runbook

### 1. Collect error output
```bash
# Get the actual error — don't guess
<run the failing command> 2>&1 | tail -50
```

### 2. Check dependencies
```bash
# Node
node --version && npm --version
cat package.json | grep -E '"engines|"node'

# Python
python --version
pip list | grep -E 'requirement|conflict'

# Go
go version
go mod verify
```

### 3. Check environment variables
```bash
# What's set vs what's needed
cat .env.example | grep -v '^#' | grep '='
printenv | grep -E 'PORT|HOST|DB|API|SECRET|KEY|URL'
```

### 4. Check ports and processes
```bash
# Windows
netstat -ano | findstr LISTENING
tasklist | findstr <process>

# What's blocking the port?
netstat -ano | findstr :8080
```

### 5. Check file permissions and paths
```bash
# Does the config file exist?
ls -la .env config/ *.json 2>&1

# Is the binary in PATH?
where <command>  # Windows
which <command>  # Unix
```

### 6. Check service dependencies
```bash
# Is the DB up?
# Is Redis up?
# Is the API it depends on reachable?
curl -s -o /dev/null -w "%{http_code}" <dependency-url>
```

## Output

Report findings as:
```
PROBLEM: <what's broken>
CAUSE:   <why it's broken>
FIX:     <exact command or change to fix it>
```

Then verify the fix worked by re-running the original command.
