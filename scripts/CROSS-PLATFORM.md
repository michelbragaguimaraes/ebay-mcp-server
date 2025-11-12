# Cross-Platform Shell Scripts Documentation

All shell scripts in this directory have been optimized for cross-platform compatibility across Windows (Git Bash/WSL), macOS, and Linux.

## Platform Support

### Windows
- ✅ **Git Bash** (recommended): Install [Git for Windows](https://git-scm.com/download/win)
- ✅ **WSL** (Windows Subsystem for Linux): Full bash support
- ⚠️ **PowerShell**: Not supported - use Git Bash instead
- ⚠️ **Command Prompt**: Not supported - use Git Bash instead

### macOS
- ✅ All macOS versions with default bash/zsh terminal
- ✅ Tested on macOS 10.14+ (Mojave and later)

### Linux
- ✅ All major distributions (Ubuntu, Debian, Fedora, CentOS, Arch, etc.)
- ✅ Requires bash 4.0 or later

## Cross-Platform Features

### 1. Platform Detection
All scripts automatically detect the current platform:

```bash
# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "macos" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}
```

### 2. ANSI Color Support
Colors are automatically disabled on Windows terminals that don't support ANSI escape codes:

```bash
# Colors with fallback for Windows
if [ "$PLATFORM" = "windows" ] || [ -z "${TERM:-}" ] || [ "$TERM" = "dumb" ]; then
    # No colors - plain text output
    RED=''
    GREEN=''
    # ... etc
else
    # Full ANSI color support
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    # ... etc
fi
```

### 3. Path Resolution
Scripts use cross-platform path resolution that works with both Unix-style (`/`) and Windows-style (`\`) paths:

```bash
# Cross-platform script directory detection
get_script_dir() {
    local source="${BASH_SOURCE[0]:-$0}"
    while [ -L "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$(cd -P "$(dirname "$source")" && pwd)"
}

# Normalize paths for Windows (convert backslashes to forward slashes for JSON)
if [ "$PLATFORM" = "windows" ]; then
    BUILD_PATH=$(echo "$BUILD_PATH" | sed 's|\\|/|g')
fi
```

### 4. Cross-Platform sed
Scripts use platform-aware `sed` operations with Perl fallback:

```bash
# Use perl for consistent cross-platform behavior
if command -v perl >/dev/null 2>&1; then
    perl -i -pe "s|old|new|g" "$FILE"
else
    # Fallback to platform-specific sed
    case "$PLATFORM" in
        macos)
            sed -i '' "s|old|new|g" "$FILE"
            ;;
        *)
            sed -i "s|old|new|g" "$FILE"
            ;;
    esac
fi
```

### 5. Timestamp Generation
Cross-platform timestamp generation with multiple fallbacks:

```bash
# Get current timestamp in milliseconds (cross-platform)
get_timestamp_ms() {
    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'import time; print(int(time.time() * 1000))'
    elif command -v python >/dev/null 2>&1; then
        python -c 'import time; print(int(time.time() * 1000))'
    elif command -v node >/dev/null 2>&1; then
        node -e 'console.log(Date.now())'
    else
        # Fallback to bash (may have precision issues)
        echo $(($(date +%s) * 1000))
    fi
}
```

### 6. User Input Handling
Windows-compatible user input with proper handling of `read` command limitations:

```bash
# Cross-platform read function
read_user_input() {
    local prompt="$1"
    if [ "$PLATFORM" = "windows" ]; then
        # Windows Git Bash may have issues with read -n 1
        echo -n "$prompt"
        read REPLY
        # Take only first character
        REPLY="${REPLY:0:1}"
    else
        read -p "$prompt" -n 1 -r
        echo ""
    fi
}
```

## Running Scripts

### On Windows (Git Bash)
```bash
# From Git Bash terminal
cd /c/path/to/ebay-api-mcp-server
./scripts/generate-types.sh
./scripts/create-mcp-setup.sh
./scripts/setup-mcp-clients.sh
```

### On macOS/Linux
```bash
# From standard terminal
cd /path/to/ebay-api-mcp-server
./scripts/generate-types.sh
./scripts/create-mcp-setup.sh
./scripts/setup-mcp-clients.sh
```

### Making Scripts Executable
If you get a "Permission denied" error:

```bash
# Make all scripts executable
chmod +x scripts/*.sh

# Or make individual scripts executable
chmod +x scripts/generate-types.sh
chmod +x scripts/create-mcp-setup.sh
chmod +x scripts/setup-mcp-clients.sh
```

## Dependencies

### Required on All Platforms
- **bash** 4.0 or later (included with Git Bash on Windows)
- **jq** (JSON processor)
  - macOS: `brew install jq`
  - Linux: `sudo apt-get install jq` or `sudo yum install jq`
  - Windows: Included with Git for Windows or install from [jqlang.github.io/jq](https://jqlang.github.io/jq/)

### Optional (Improves Compatibility)
- **perl** (for cross-platform sed operations)
  - macOS: Pre-installed
  - Linux: Usually pre-installed, or `sudo apt-get install perl`
  - Windows: Included with Git for Windows

- **python3** or **node** (for precise timestamp generation)
  - Recommended for accurate token expiry calculations

## Troubleshooting

### Windows Issues

**Problem**: Script won't run or shows "command not found"
- **Solution**: Use Git Bash, not PowerShell or Command Prompt
- **Install**: Download from [git-scm.com](https://git-scm.com/download/win)

**Problem**: Colors show as escape codes like `\033[0;31m`
- **Solution**: This is normal for unsupported terminals. The script automatically disables colors in this case.

**Problem**: Path errors with backslashes
- **Solution**: Scripts automatically convert paths. Ensure you're in Git Bash, not Command Prompt.

**Problem**: `jq` command not found
- **Solution**: Install jq via Chocolatey: `choco install jq`
- **Or**: Download binary from [jqlang.github.io/jq](https://jqlang.github.io/jq/) and add to PATH

### macOS Issues

**Problem**: `sed: command s expects \ followed by text` error
- **Solution**: Scripts automatically detect macOS and use `sed -i ''` syntax
- **Alternative**: Install GNU sed: `brew install gnu-sed` (optional)

**Problem**: Permission denied
- **Solution**: Run `chmod +x scripts/*.sh` to make scripts executable

### Linux Issues

**Problem**: `jq: command not found`
- **Ubuntu/Debian**: `sudo apt-get update && sudo apt-get install jq`
- **Fedora/RHEL**: `sudo yum install jq` or `sudo dnf install jq`
- **Arch**: `sudo pacman -S jq`

**Problem**: Bash version too old
- **Solution**: Update bash to 4.0 or later
- **Check version**: `bash --version`

## Testing Cross-Platform Compatibility

### Automated Testing
Run the test suite to verify cross-platform compatibility:

```bash
npm run test
```

### Manual Testing Checklist
- [ ] Run all scripts on Windows (Git Bash)
- [ ] Run all scripts on macOS
- [ ] Run all scripts on Linux
- [ ] Verify color output works correctly
- [ ] Verify path handling (no backslash errors)
- [ ] Verify JSON files are created correctly
- [ ] Test with and without optional dependencies (perl, python, node)

## Best Practices

### 1. Use Portable Shebang
```bash
#!/usr/bin/env bash  # ✅ Portable
#!/bin/bash          # ❌ May not work on all systems
```

### 2. Enable Strict Mode
```bash
set -e          # Exit on error
set -u          # Exit on undefined variable
set -o pipefail # Exit on pipe failure
```

### 3. Avoid Platform-Specific Commands
```bash
# ❌ Don't use
date +%s%N  # Nanoseconds not available on macOS

# ✅ Do use
date +%s    # Seconds available everywhere
```

### 4. Quote Variables
```bash
# ✅ Always quote paths and variables
"$BUILD_PATH"
"${CONFIG_DIR}"

# ❌ Never do this (breaks with spaces)
$BUILD_PATH
```

### 5. Use Command Existence Checks
```bash
# Check if command exists before using
if command -v jq >/dev/null 2>&1; then
    jq '.' file.json
else
    echo "jq is required but not installed"
    exit 1
fi
```

## Architecture Decision Records

### Why Bash Instead of PowerShell?
- ✅ Works on all platforms (with Git Bash on Windows)
- ✅ Single codebase for all platforms
- ✅ No need to maintain separate .sh and .ps1 versions
- ✅ Developers already familiar with bash
- ✅ Better tooling support (jq, sed, grep, etc.)

### Why Not Pure JavaScript/Node?
- ❌ Adds Node.js as a hard dependency
- ❌ Less familiar for system administration tasks
- ❌ Bash is already required for npm scripts
- ✅ Bash scripts are faster for simple file operations
- ✅ Better integration with existing Unix tools

### Why Support Windows Git Bash?
- ✅ Most developers on Windows already have Git installed
- ✅ Provides a consistent bash environment
- ✅ Better developer experience than WSL for simple scripts
- ✅ Works without admin privileges

## Future Improvements

- [ ] Add Windows .bat/.ps1 wrappers that call Git Bash scripts
- [ ] Add automated cross-platform CI testing (GitHub Actions matrix)
- [ ] Create Docker image for consistent execution environment
- [ ] Add comprehensive script error logging
- [ ] Create interactive installation wizard (using `whiptail` or similar)

## References

- [Bash Guide](https://mywiki.wooledge.org/BashGuide)
- [ShellCheck](https://www.shellcheck.net/) - Script quality checker
- [Git for Windows](https://gitforwindows.org/)
- [jq Manual](https://jqlang.github.io/jq/manual/)
