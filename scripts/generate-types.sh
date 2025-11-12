#!/usr/bin/env bash

# generate-types.sh
# Automatically generates TypeScript types from OpenAPI specifications
# Maps docs folder structure to src/types output structure
# Cross-platform compatible: Windows (Git Bash/WSL), macOS, Linux

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "macos" ;;
        CYGWIN*|MINGW*|MSYS*) echo "windows" ;;
        *)          echo "unknown" ;;
    esac
}

PLATFORM=$(detect_platform)

# Colors for output (with fallback for Windows)
if [ "$PLATFORM" = "windows" ] || [ -z "${TERM:-}" ] || [ "$TERM" = "dumb" ]; then
    # No colors on Windows CMD or unsupported terminals
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
fi

# Get script directory (cross-platform)
get_script_dir() {
    local source="${BASH_SOURCE[0]:-$0}"
    while [ -L "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    echo "$(cd -P "$(dirname "$source")" && pwd)"
}

SCRIPT_DIR="$(get_script_dir)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Base directories (use absolute paths)
DOCS_DIR="$PROJECT_ROOT/docs"
TYPES_DIR="$PROJECT_ROOT/src/types"
OPENAPI_SCHEMAS_DIR="${TYPES_DIR}"

# Change to project root
cd "$PROJECT_ROOT"

# Ensure we're in the project root
if [ ! -f "package.json" ]; then
    echo -e "${RED}Error: Must be run from project root${NC}"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "${OPENAPI_SCHEMAS_DIR}"

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  OpenAPI TypeScript Type Generator        ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo ""

# Counter for generated files
GENERATED_COUNT=0
SKIPPED_COUNT=0
ERROR_COUNT=0

# Function to generate types from OpenAPI spec
generate_types() {
    local input_file="$1"
    local output_file="$2"
    local spec_name="$3"

    echo -e "${YELLOW}→${NC} Generating: ${spec_name}"
    echo -e "  ${BLUE}Input:${NC}  ${input_file}"
    echo -e "  ${BLUE}Output:${NC} ${output_file}"

    if [ ! -f "${input_file}" ]; then
        echo -e "  ${RED}✗ Error: Input file not found${NC}"
        ((ERROR_COUNT++))
        return 1
    fi

    # Generate types using openapi-typescript
    if npx openapi-typescript "${input_file}" -o "${output_file}" --silent 2>/dev/null; then
        echo -e "  ${GREEN}✓ Success${NC}"
        ((GENERATED_COUNT++))
    else
        echo -e "  ${RED}✗ Failed to generate types${NC}"
        ((ERROR_COUNT++))
        return 1
    fi

    echo ""
}

# Mapping: docs folder -> spec file -> output file
# Format: "docs_path:spec_filename:output_filename"

declare -a SPEC_MAPPINGS=(
    # Account Management
    "sell-apps/account-management:sell_account_v1_oas3.json:sell_account_v1_oas3.ts"

    # Order Management
    "sell-apps/order-management:sell_fulfillment_v1_oas3.json:sell_fulfillment_v1_oas3.ts"

    # Listing Management
    "sell-apps/listing-management:sell_inventory_v1_oas3.json:sell_inventory_v1_oas3.ts"

    # Listing Metadata
    "sell-apps/listing-metadata:sell_metadata_v1_oas3.json:sell_metadata_v1_oas3.ts"

    # Analytics and Report
    "sell-apps/analytics-and-report:sell_analytics_v1_oas3.json:sell_analytics_v1_oas3.ts"

    # Marketing and Promotions (note the typo in folder name)
    "sell-apps/markeitng-and-promotions:sell_marketing_v1_oas3.json:sell_marketing_v1_oas3.ts"
    "sell-apps/markeitng-and-promotions:sell_recommendation_v1_oas3.json:sell_recommendation_v1_oas3.ts"

    # Communication
    "sell-apps/communication:sell_negotiation_v1_oas3.json:sell_negotiation_v1_oas3.ts"
    "sell-apps/communication:commerce_feedback_v1_beta_oas3.json:commerce_feedback_v1_beta_oas3.ts"
    "sell-apps/communication:commerce_notification_v1_oas3.json:commerce_notification_v1_oas3.ts"
    "sell-apps/communication:commerce_message_v1_oas3.json:commerce_message_v1_oas3.ts"

    # Other APIs
    "sell-apps/other-apis:commerce_identity_v1_oas3.json:commerce_identity_v1_oas3.ts"
    "sell-apps/other-apis:commerce_vero_v1_oas3.json:commerce_vero_v1_oas3.ts"
    "sell-apps/other-apis:sell_compliance_v1_oas3.json:sell_compliance_v1_oas3.ts"
    "sell-apps/other-apis:commerce_translation_v1_beta_oas3.json:commerce_translation_v1_beta_oas3.ts"
    "sell-apps/other-apis:sell_edelivery_international_shipping_oas3.json:sell_edelivery_international_shipping_oas3.ts"
)

echo -e "${GREEN}Processing OpenAPI Specifications...${NC}"
echo ""

# Process each mapping
for mapping in "${SPEC_MAPPINGS[@]}"; do
    IFS=':' read -r docs_path spec_file output_file <<< "$mapping"

    input_path="${DOCS_DIR}/${docs_path}/${spec_file}"
    output_path="${OPENAPI_SCHEMAS_DIR}/${output_file}"
    spec_name=$(basename "${spec_file}" .json)

    generate_types "${input_path}" "${output_path}" "${spec_name}"
done

# Summary
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Generation Summary                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}✓ Generated:${NC} ${GENERATED_COUNT} files"
echo -e "  ${YELLOW}⚠ Skipped:${NC}   ${SKIPPED_COUNT} files"
echo -e "  ${RED}✗ Errors:${NC}    ${ERROR_COUNT} files"
echo ""

if [ ${ERROR_COUNT} -gt 0 ]; then
    echo -e "${RED}Generation completed with errors${NC}"
    exit 1
else
    echo -e "${GREEN}All types generated successfully!${NC}"
    echo ""
    echo -e "${BLUE}Types location:${NC} ${OPENAPI_SCHEMAS_DIR}"
    exit 0
fi
