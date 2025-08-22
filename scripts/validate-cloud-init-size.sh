#!/bin/bash

# Azure cloud-init file size validator
# Maximum Azure cloud-init size: 64KB
# This script validates files are under 90% of the limit (58KB)

set -euo pipefail

# Configuration
MAX_SIZE_BYTES=65536  # 64KB in bytes
WARN_THRESHOLD=0.9    # 90% threshold
WARN_SIZE_BYTES=$(echo "$MAX_SIZE_BYTES * $WARN_THRESHOLD" | bc | cut -d. -f1)

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Track validation status
validation_failed=false

echo "🔍 Validating cloud-init file sizes..."
echo "📏 Maximum allowed size: ${MAX_SIZE_BYTES} bytes (64KB)"
echo "⚠️  Warning threshold: ${WARN_SIZE_BYTES} bytes (90% of max)"
echo ""

# Function to validate a single file
validate_file() {
    local file="$1"
    local file_size
    local file_size_kb

    # Get file size in bytes
    file_size=$(wc -c < "$file")
    file_size_kb=$(echo "scale=2; $file_size / 1024" | bc)

    printf "Checking: %-30s " "$(basename "$file")"

    if [ "$file_size" -gt "$MAX_SIZE_BYTES" ]; then
        printf "${RED}FAIL${NC} (${file_size} bytes / ${file_size_kb}KB - exceeds 64KB limit)\n"
        validation_failed=true
    elif [ "$file_size" -gt "$WARN_SIZE_BYTES" ]; then
        printf "${YELLOW}WARN${NC} (${file_size} bytes / ${file_size_kb}KB - exceeds 90%% threshold)\n"
    else
        printf "${GREEN}PASS${NC} (${file_size} bytes / ${file_size_kb}KB)\n"
    fi
}

# If no arguments provided, validate all cloud-init files
if [ $# -eq 0 ]; then
    echo "No specific files provided. Validating all cloud-init/*.conf files..."
    echo ""

    # Find all .conf files in cloud-init directory
    if [ -d "cloud-init" ]; then
        while IFS= read -r -d '' file; do
            validate_file "$file"
        done < <(find cloud-init -name "*.conf" -type f -print0)
    else
        echo "❌ cloud-init directory not found"
        exit 1
    fi
else
    # Validate specific files provided as arguments
    for file in "$@"; do
        if [ -f "$file" ]; then
            validate_file "$file"
        else
            echo "❌ File not found: $file"
            validation_failed=true
        fi
    done
fi

echo ""

# Final validation result
if [ "$validation_failed" = true ]; then
    echo "❌ Validation FAILED: One or more cloud-init files exceed the 64KB Azure limit"
    echo ""
    echo "💡 Solutions:"
    echo "   - Split large cloud-init files into smaller components"
    echo "   - Move complex scripts to external files and download them in cloud-init"
    echo "   - Use cloud-init's #include directive to modularize configuration"
    echo "   - Consider using Azure VM extensions for complex setup tasks"
    exit 1
else
    echo "✅ All cloud-init files are within size limits"
fi
