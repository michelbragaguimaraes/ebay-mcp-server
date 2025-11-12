# eBay API MCP Server - Utility Scripts

This directory contains automated setup and utility scripts for the eBay API MCP Server.

## Available Scripts

### 1. MCP Client Auto-Configuration (`setup-mcp-clients.sh`)

**Automated MCP client configuration for Claude Desktop, Gemini CLI, and ChatGPT Desktop**

#### Quick Start
```bash
# From project root
./scripts/setup-mcp-clients.sh
```

[Jump to detailed documentation →](#script-setup-mcp-clientssh)

---

### 2. Type Generation (`generate-types.sh`)

**Generate TypeScript types from OpenAPI specifications**

#### Quick Start
```bash
npm run generate:types
```

This command generates TypeScript types for all eBay APIs from the OpenAPI specs in the `docs/` folder.

[Jump to detailed documentation →](#script-generate-typessh)

---

## Script: setup-mcp-clients.sh

### Overview

Automatically detects and configures the eBay API MCP server for all supported AI clients.

### Supported Clients

- ✅ **Claude Desktop** (macOS, Windows, Linux)
- ✅ **Gemini CLI** (macOS, Linux, Windows via WSL)
- ✅ **ChatGPT Desktop** (macOS, Windows, Linux - if MCP support is available)

### What It Does

1. **Detects Operating System**: Automatically detects macOS, Linux, or Windows
2. **Verifies Prerequisites**:
   - Checks for Node.js installation
   - Verifies project is built (`build/index.js` exists)
   - Installs `jq` if needed (for JSON manipulation)
3. **Prompts for Configuration**:
   - eBay Client ID
   - eBay Client Secret
   - Environment (Sandbox or Production)
   - Optional: OAuth Redirect URI
4. **Auto-Configures Clients**:
   - Searches for Claude Desktop config directory
   - Searches for Gemini CLI config directory
   - Searches for ChatGPT Desktop config directory
   - Creates or updates MCP configuration files
   - Uses absolute paths for reliability
5. **Provides Summary**: Lists all successfully configured clients

### Requirements

- **Node.js** 18+ installed
- **Built project**: Run `npm run build` first
- **jq** (installed automatically if missing via package manager)

### Platform-Specific Config Paths

**macOS:**
- Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Gemini CLI: `~/.gemini/settings.json`
- ChatGPT Desktop: `~/Library/Application Support/ChatGPT/mcp_config.json`

**Linux:**
- Claude Desktop: `~/.config/Claude/claude_desktop_config.json`
- Gemini CLI: `~/.gemini/settings.json`
- ChatGPT Desktop: `~/.config/ChatGPT/mcp_config.json`

**Windows:**
- Claude Desktop: `%APPDATA%/Claude/claude_desktop_config.json`
- Gemini CLI: `~/.gemini/settings.json` (WSL)
- ChatGPT Desktop: `%APPDATA%/ChatGPT/mcp_config.json`

### Usage

```bash
# Make sure the project is built
npm install && npm run build

# Run the setup script
./scripts/setup-mcp-clients.sh

# Follow the interactive prompts
```

### Troubleshooting

**Permission Denied:**
```bash
chmod +x ./scripts/setup-mcp-clients.sh
./scripts/setup-mcp-clients.sh
```

**jq Not Found:**
The script will attempt to install `jq` automatically. If it fails:
- macOS: `brew install jq`
- Ubuntu/Debian: `sudo apt-get install jq`
- CentOS/RHEL: `sudo yum install jq`
- Windows: Use WSL or install manually from https://stedolan.github.io/jq/

**Build Not Found:**
```bash
npm install
npm run build
./scripts/setup-mcp-clients.sh
```

**Client Not Detected:**
- Ensure the client is installed in the default location
- Check that config directories exist
- Fall back to [manual configuration](../README.md#manual-configuration)

### Security Notes

- **Credentials in Config**: The script stores eBay credentials in client config files
- **File Permissions**: Config files are created with user-only read/write permissions
- **No Network Calls**: The script only modifies local configuration files
- **Credentials Display**: Credentials are not echoed to the terminal during input

---

## Script: generate-types.sh

## Overview

The type generation workflow uses `openapi-typescript` to convert eBay's OpenAPI 3.0 specifications into type-safe TypeScript definitions.

### Flow Diagram

```
docs/sell-apps/
├── account-management/
│   └── sell_account_v1_oas3.json ──────┐
├── order-management/                    │
│   └── sell_fulfillment_v1_oas3.json ───┤
├── listing-management/                  │
│   └── sell_inventory_v1_oas3.json ─────┤
├── listing-metadata/                    │
│   └── sell_metadata_v1_oas3.json ──────┤
├── analytics-and-report/                │
│   └── sell_analytics_v1_oas3.json ─────┤
├── markeitng-and-promotions/            │
│   ├── sell_marketing_v1_oas3.json ─────┤
│   └── sell_recommendation_v1_oas3.json ┤
├── communication/                       │
│   ├── sell_negotiation_v1_oas3.json ───┤  openapi-typescript
│   ├── commerce_feedback_v1_beta_oas3.json  ────────────►
│   ├── commerce_notification_v1_oas3.json   conversion
│   └── commerce_message_v1_oas3.json ───┤
└── other-apis/                          │
    ├── commerce_identity_v1_oas3.json ──┤
    ├── commerce_vero_v1_oas3.json ──────┤
    ├── sell_compliance_v1_oas3.json ────┤
    └── commerce_translation_v1_beta_oas3.json
                                         │
                                         │
                                         ▼
            src/types/openapi-schemas/
            ├── sell_account_v1_oas3.ts
            ├── sell_fulfillment_v1_oas3.ts
            ├── sell_inventory_v1_oas3.ts
            ├── sell_metadata_v1_oas3.ts
            ├── sell_analytics_v1_oas3.ts
            ├── sell_marketing_v1_oas3.ts
            ├── sell_recommendation_v1_oas3.ts
            ├── sell_negotiation_v1_oas3.ts
            ├── commerce_feedback_v1_beta_oas3.ts
            ├── commerce_notification_v1_oas3.ts
            ├── commerce_message_v1_oas3.ts
            ├── commerce_identity_v1_oas3.ts
            ├── commerce_vero_v1_oas3.ts
            ├── sell_compliance_v1_oas3.ts
            └── commerce_translation_v1_beta_oas3.ts
```

## Script: generate-types.sh

### What It Does

1. **Validates Environment**: Ensures script runs from project root
2. **Creates Output Directory**: Creates `src/types/openapi-schemas/` if needed
3. **Processes Each Spec**: Iterates through all OpenAPI JSON files
4. **Generates TypeScript Types**: Uses `openapi-typescript` for conversion
5. **Reports Results**: Shows success/failure summary

### Features

- ✅ **Colored Output**: Easy-to-read progress indicators
- ✅ **Error Handling**: Continues processing even if individual files fail
- ✅ **Mapping System**: Explicit docs-to-output path mapping
- ✅ **Silent Mode**: Suppresses verbose openapi-typescript output
- ✅ **Exit Codes**: Returns non-zero on errors for CI/CD integration

### Output

The script generates TypeScript definition files with:
- **Type-safe interfaces** for all API schemas
- **Discriminated unions** for polymorphic responses
- **Proper JSDoc comments** from OpenAPI descriptions
- **Enum types** for fixed value sets

### Example Generated Type Usage

```typescript
// Import generated types
import type { components } from "./types/openapi-schemas/sell_inventory_v1_oas3.js";

// Use strongly-typed interfaces
type InventoryItem = components["schemas"]["InventoryItem"];
type Offer = components["schemas"]["Offer"];

// Type-safe function signatures
async function getInventoryItem(sku: string): Promise<InventoryItem> {
  // Implementation uses correctly typed responses
}
```

## Folder Mapping

The script uses explicit path mappings to control where types are generated:

| Docs Folder | OpenAPI Spec | Generated Type |
|-------------|--------------|----------------|
| `sell-apps/account-management/` | `sell_account_v1_oas3.json` | `src/types/openapi-schemas/sell_account_v1_oas3.ts` |
| `sell-apps/order-management/` | `sell_fulfillment_v1_oas3.json` | `src/types/openapi-schemas/sell_fulfillment_v1_oas3.ts` |
| `sell-apps/listing-management/` | `sell_inventory_v1_oas3.json` | `src/types/openapi-schemas/sell_inventory_v1_oas3.ts` |
| `sell-apps/listing-metadata/` | `sell_metadata_v1_oas3.json` | `src/types/openapi-schemas/sell_metadata_v1_oas3.ts` |
| `sell-apps/analytics-and-report/` | `sell_analytics_v1_oas3.json` | `src/types/openapi-schemas/sell_analytics_v1_oas3.ts` |
| `sell-apps/markeitng-and-promotions/` | `sell_marketing_v1_oas3.json` | `src/types/openapi-schemas/sell_marketing_v1_oas3.ts` |
| `sell-apps/markeitng-and-promotions/` | `sell_recommendation_v1_oas3.json` | `src/types/openapi-schemas/sell_recommendation_v1_oas3.ts` |
| `sell-apps/communication/` | `sell_negotiation_v1_oas3.json` | `src/types/openapi-schemas/sell_negotiation_v1_oas3.ts` |
| `sell-apps/communication/` | `commerce_feedback_v1_beta_oas3.json` | `src/types/openapi-schemas/commerce_feedback_v1_beta_oas3.ts` |
| `sell-apps/communication/` | `commerce_notification_v1_oas3.json` | `src/types/openapi-schemas/commerce_notification_v1_oas3.ts` |
| `sell-apps/communication/` | `commerce_message_v1_oas3.json` | `src/types/openapi-schemas/commerce_message_v1_oas3.ts` |
| `sell-apps/other-apis/` | `commerce_identity_v1_oas3.json` | `src/types/openapi-schemas/commerce_identity_v1_oas3.ts` |
| `sell-apps/other-apis/` | `commerce_vero_v1_oas3.json` | `src/types/openapi-schemas/commerce_vero_v1_oas3.ts` |
| `sell-apps/other-apis/` | `sell_compliance_v1_oas3.json` | `src/types/openapi-schemas/sell_compliance_v1_oas3.ts` |
| `sell-apps/other-apis/` | `commerce_translation_v1_beta_oas3.json` | `src/types/openapi-schemas/commerce_translation_v1_beta_oas3.ts` |

## Adding New Specs

To add a new OpenAPI specification:

1. **Add the spec file** to the appropriate `docs/sell-apps/*/` folder
2. **Edit `generate-types.sh`** and add a new entry to the `SPEC_MAPPINGS` array:

```bash
declare -a SPEC_MAPPINGS=(
    # ... existing mappings ...

    # Your New API
    "sell-apps/your-folder:your_api_v1_oas3.json:your_api_v1_oas3.ts"
)
```

3. **Run the generator**:
```bash
npm run generate:types
```

## Manual Usage

You can also run the script directly:

```bash
# From project root
./scripts/generate-types.sh

# Or with bash explicitly
bash scripts/generate-types.sh
```

## Troubleshooting

### Script Won't Execute

```bash
# Make sure it's executable
chmod +x scripts/generate-types.sh

# Check line endings (must be Unix LF, not Windows CRLF)
file scripts/generate-types.sh
# Should show: "Bourne-Again shell script text executable"
```

### "Input file not found" Error

- Verify the OpenAPI JSON file exists in the `docs/` folder
- Check the path in `SPEC_MAPPINGS` array matches the actual file location
- Ensure folder names are correct (note: `markeitng-and-promotions` has a typo)

### Generation Fails for Specific File

- Validate the OpenAPI JSON is valid (use https://editor.swagger.io/)
- Check for syntax errors in the JSON file
- Try generating that specific file manually:
  ```bash
  npx openapi-typescript docs/path/to/spec.json -o output.ts
  ```

### Types Not Updating

- Generated files are cached - delete and regenerate:
  ```bash
  rm -rf src/types/openapi-schemas/
  npm run generate:types
  ```

## CI/CD Integration

The script exits with status code 1 if any errors occur, making it suitable for CI/CD:

```yaml
# Example GitHub Actions workflow
- name: Generate TypeScript Types
  run: npm run generate:types

- name: Verify Types Compile
  run: npm run typecheck
```

## Dependencies

- **openapi-typescript**: v7.10.1+ (installed as devDependency)
- **Node.js**: 18.0.0+
- **Bash**: 3.0+ (macOS/Linux standard)

## See Also

- [openapi-typescript Documentation](https://github.com/drwpow/openapi-typescript)
- [eBay API Documentation](https://developer.ebay.com/api-docs)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
