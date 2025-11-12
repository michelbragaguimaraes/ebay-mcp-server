#!/usr/bin/env bash

#############################################################################
# MCP Client Auto-Configuration Script
#############################################################################
#
# This script automatically configures the eBay API MCP Server for:
#   - Claude Desktop (macOS/Windows/Linux)
#   - Gemini CLI (if installed)
#   - ChatGPT Desktop (macOS/Windows - if installed)
#
# Usage:
#   ./scripts/setup-mcp-clients.sh
#
# Requirements:
#   - Node.js 18+ installed
#   - This package built (npm run build)
#   - eBay API credentials (will be prompted)
#
#############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)    OS="macos";;
        Linux*)     OS="linux";;
        MINGW*|MSYS*|CYGWIN*)    OS="windows";;
        *)          OS="unknown";;
    esac
    echo "$OS"
}

# Get absolute path to this package
get_package_path() {
    local SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local PACKAGE_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
    echo "$PACKAGE_DIR"
}

# Check if jq is installed (for JSON manipulation)
check_jq() {
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not installed. Installing jq for JSON manipulation..."

        case "$OS" in
            macos)
                if command -v brew &> /dev/null; then
                    brew install jq
                else
                    print_error "Please install Homebrew first: https://brew.sh/"
                    exit 1
                fi
                ;;
            linux)
                if command -v apt-get &> /dev/null; then
                    sudo apt-get update && sudo apt-get install -y jq
                elif command -v yum &> /dev/null; then
                    sudo yum install -y jq
                elif command -v dnf &> /dev/null; then
                    sudo dnf install -y jq
                else
                    print_error "Please install jq manually: https://stedolan.github.io/jq/"
                    exit 1
                fi
                ;;
            windows)
                print_error "Please install jq manually: https://stedolan.github.io/jq/"
                print_info "Or use Windows Subsystem for Linux (WSL)"
                exit 1
                ;;
        esac
        print_success "jq installed successfully"
    fi
}

# Get eBay credentials from user
get_ebay_credentials() {
    print_header "eBay API Credentials"

    print_info "You need eBay API credentials to use this MCP server."
    print_info "Get your credentials at: https://developer.ebay.com/my/keys"
    echo ""

    read -p "Enter your eBay Client ID: " EBAY_CLIENT_ID
    read -p "Enter your eBay Client Secret: " EBAY_CLIENT_SECRET

    echo ""
    echo "Select eBay Environment:"
    echo "  1) Sandbox (testing)"
    echo "  2) Production"
    read -p "Enter choice [1-2]: " ENV_CHOICE

    case $ENV_CHOICE in
        1) EBAY_ENVIRONMENT="sandbox";;
        2) EBAY_ENVIRONMENT="production";;
        *)
            print_error "Invalid choice. Defaulting to sandbox."
            EBAY_ENVIRONMENT="sandbox"
            ;;
    esac

    # Optional: Redirect URI
    read -p "Enter OAuth Redirect URI (optional, press Enter to skip): " EBAY_REDIRECT_URI

    print_success "Credentials collected"
}

# Configure Claude Desktop
configure_claude_desktop() {
    print_header "Configuring Claude Desktop"

    case "$OS" in
        macos)
            CONFIG_DIR="$HOME/Library/Application Support/Claude"
            ;;
        linux)
            CONFIG_DIR="$HOME/.config/Claude"
            ;;
        windows)
            CONFIG_DIR="$APPDATA/Claude"
            ;;
        *)
            print_error "Unsupported OS for Claude Desktop"
            return 1
            ;;
    esac

    CONFIG_FILE="$CONFIG_DIR/claude_desktop_config.json"

    # Create config directory if it doesn't exist
    if [ ! -d "$CONFIG_DIR" ]; then
        print_info "Claude Desktop config directory not found: $CONFIG_DIR"
        read -p "Would you like to create it? (y/n): " CREATE_DIR
        if [[ "$CREATE_DIR" =~ ^[Yy]$ ]]; then
            mkdir -p "$CONFIG_DIR"
            print_success "Created directory: $CONFIG_DIR"
        else
            print_warning "Skipping Claude Desktop configuration"
            return 1
        fi
    fi

    # Create or update config file
    if [ ! -f "$CONFIG_FILE" ]; then
        # Create new config
        print_info "Creating new Claude Desktop config..."
        cat > "$CONFIG_FILE" <<EOF
{
  "mcpServers": {}
}
EOF
    fi

    # Build the server config
    local SERVER_CONFIG=$(cat <<EOF
{
  "command": "node",
  "args": ["$PACKAGE_PATH/build/index.js"],
  "env": {
    "EBAY_CLIENT_ID": "$EBAY_CLIENT_ID",
    "EBAY_CLIENT_SECRET": "$EBAY_CLIENT_SECRET",
    "EBAY_ENVIRONMENT": "$EBAY_ENVIRONMENT"$([ -n "$EBAY_REDIRECT_URI" ] && echo ",
    \"EBAY_REDIRECT_URI\": \"$EBAY_REDIRECT_URI\"" || echo "")
  }
}
EOF
)

    # Update config file using jq
    local TEMP_FILE=$(mktemp)
    jq ".mcpServers.ebay = $SERVER_CONFIG" "$CONFIG_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$CONFIG_FILE"

    print_success "Claude Desktop configured successfully"
    print_info "Config file: $CONFIG_FILE"
    print_warning "Please restart Claude Desktop to apply changes"
}

# Configure Gemini CLI
configure_gemini_cli() {
    print_header "Configuring Gemini CLI"

    # Check if Gemini CLI is installed
    if ! command -v gemini &> /dev/null && ! command -v google-gemini &> /dev/null; then
        print_warning "Gemini CLI not found. Skipping Gemini configuration."
        print_info "Install Gemini CLI from: https://ai.google.dev/gemini-api/docs/cli"
        return 1
    fi

    CONFIG_DIR="$HOME/.gemini"
    CONFIG_FILE="$CONFIG_DIR/settings.json"

    # Create config directory if it doesn't exist
    if [ ! -d "$CONFIG_DIR" ]; then
        print_info "Creating Gemini config directory..."
        mkdir -p "$CONFIG_DIR"
    fi

    # Create or update config file
    if [ ! -f "$CONFIG_FILE" ]; then
        print_info "Creating new Gemini config..."
        cat > "$CONFIG_FILE" <<EOF
{
  "mcpServers": {}
}
EOF
    fi

    # Build the server config
    local SERVER_CONFIG=$(cat <<EOF
{
  "command": "node",
  "args": ["$PACKAGE_PATH/build/index.js"],
  "env": {
    "EBAY_CLIENT_ID": "$EBAY_CLIENT_ID",
    "EBAY_CLIENT_SECRET": "$EBAY_CLIENT_SECRET",
    "EBAY_ENVIRONMENT": "$EBAY_ENVIRONMENT"$([ -n "$EBAY_REDIRECT_URI" ] && echo ",
    \"EBAY_REDIRECT_URI\": \"$EBAY_REDIRECT_URI\"" || echo "")
  }
}
EOF
)

    # Update config file using jq
    local TEMP_FILE=$(mktemp)
    jq ".mcpServers.ebay = $SERVER_CONFIG" "$CONFIG_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$CONFIG_FILE"

    print_success "Gemini CLI configured successfully"
    print_info "Config file: $CONFIG_FILE"
    print_warning "Run 'gemini mcp refresh' or restart Gemini CLI to apply changes"
}

# Configure ChatGPT Desktop
configure_chatgpt_desktop() {
    print_header "Configuring ChatGPT Desktop"

    case "$OS" in
        macos)
            CONFIG_DIR="$HOME/Library/Application Support/ChatGPT"
            ;;
        linux)
            CONFIG_DIR="$HOME/.config/ChatGPT"
            ;;
        windows)
            CONFIG_DIR="$APPDATA/ChatGPT"
            ;;
        *)
            print_error "Unsupported OS for ChatGPT Desktop"
            return 1
            ;;
    esac

    CONFIG_FILE="$CONFIG_DIR/mcp_config.json"

    # Check if ChatGPT Desktop is installed
    if [ ! -d "$CONFIG_DIR" ]; then
        print_warning "ChatGPT Desktop config directory not found: $CONFIG_DIR"
        print_info "ChatGPT Desktop may not be installed or does not support MCP yet"
        return 1
    fi

    # Create or update config file
    if [ ! -f "$CONFIG_FILE" ]; then
        print_info "Creating new ChatGPT Desktop config..."
        cat > "$CONFIG_FILE" <<EOF
{
  "mcpServers": {}
}
EOF
    fi

    # Build the server config
    local SERVER_CONFIG=$(cat <<EOF
{
  "command": "node",
  "args": ["$PACKAGE_PATH/build/index.js"],
  "env": {
    "EBAY_CLIENT_ID": "$EBAY_CLIENT_ID",
    "EBAY_CLIENT_SECRET": "$EBAY_CLIENT_SECRET",
    "EBAY_ENVIRONMENT": "$EBAY_ENVIRONMENT"$([ -n "$EBAY_REDIRECT_URI" ] && echo ",
    \"EBAY_REDIRECT_URI\": \"$EBAY_REDIRECT_URI\"" || echo "")
  }
}
EOF
)

    # Update config file using jq
    local TEMP_FILE=$(mktemp)
    jq ".mcpServers.ebay = $SERVER_CONFIG" "$CONFIG_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$CONFIG_FILE"

    print_success "ChatGPT Desktop configured successfully"
    print_info "Config file: $CONFIG_FILE"
    print_warning "Please restart ChatGPT Desktop to apply changes"
}

# Verify build exists
verify_build() {
    print_header "Verifying Build"

    if [ ! -f "$PACKAGE_PATH/build/index.js" ]; then
        print_error "Build not found. Building project..."
        cd "$PACKAGE_PATH"
        if command -v npm &> /dev/null; then
            npm run build
        elif command -v pnpm &> /dev/null; then
            pnpm build
        else
            print_error "Neither npm nor pnpm found. Please install Node.js."
            exit 1
        fi
        print_success "Build completed"
    else
        print_success "Build found at: $PACKAGE_PATH/build/index.js"
    fi
}

# Main execution
main() {
    print_header "eBay API MCP Server - Auto Configuration"

    # Detect OS
    OS=$(detect_os)
    print_info "Detected OS: $OS"

    # Get package path
    PACKAGE_PATH=$(get_package_path)
    print_info "Package path: $PACKAGE_PATH"

    # Check prerequisites
    check_jq
    verify_build

    # Get credentials
    get_ebay_credentials

    # Configure clients
    echo ""
    print_info "The following clients will be configured if available:"
    print_info "  - Claude Desktop"
    print_info "  - Gemini CLI"
    print_info "  - ChatGPT Desktop"
    echo ""

    read -p "Continue? (y/n): " CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelled by user"
        exit 0
    fi

    # Try to configure each client
    CONFIGURED_COUNT=0

    if configure_claude_desktop; then
        ((CONFIGURED_COUNT++))
    fi

    if configure_gemini_cli; then
        ((CONFIGURED_COUNT++))
    fi

    if configure_chatgpt_desktop; then
        ((CONFIGURED_COUNT++))
    fi

    # Summary
    print_header "Setup Complete"

    if [ $CONFIGURED_COUNT -eq 0 ]; then
        print_warning "No clients were configured"
        print_info "You may need to manually configure your MCP client"
    else
        print_success "Successfully configured $CONFIGURED_COUNT client(s)"
    fi

    echo ""
    print_info "Next steps:"
    echo "  1. Restart your configured AI client(s)"
    echo "  2. Verify the eBay MCP server appears in available tools"
    echo "  3. Use 'ebay_get_token_status' to check authentication"
    echo "  4. Use 'ebay_get_oauth_url' to set up user tokens (recommended)"
    echo ""
    print_info "For detailed documentation, see:"
    echo "  - README.md - User guide and examples"
    echo "  - OAUTH-SETUP.md - OAuth configuration guide"
    echo "  - docs/auth/README.md - Authentication details"
    echo ""
}

# Run main function
main
