#!/bin/bash
# Default values
HELP=false
URL=""
TEXT_SEARCH=""
BUTTON_TEXT=""
CSS_SELECTOR=""
CSS_TEXT=""
CONTENT_TEXT=""
usage() {
    echo "Usage:"
    echo "  $0 -w <URL> -t <TEXT_SEARCH> [-b <BUTTON_TEXT>] [-c <CONTENT_TEXT> -cc content] [-s <CSS_TEXT> -ss <CSS_SELECTOR>]"
    echo ""
    echo "Options:"
    echo "  -w      URL of the page to test"
    echo "  -t      Text to search using Playwright getByText()"
    echo "  -b      Optional button text to click first"
    echo ""
    echo "Content-based search (body text):"
    echo "  -c      Text to find inside full page body text"
    echo "  -cc     Enable content search mode (must be used with -cc then -c together)"
    echo ""
    echo "CSS selector search:"
    echo "  -s      Text to search inside items returned by CSS selector"
    echo "  -ss     CSS selector (must be used with -s)"
    echo ""
    echo "Examples:"
    echo "  ./script.sh -w <https://site> -t \\"Start hier\\" -cc -c \\"Transavia\\""
    echo "  ./script.sh -w <https://site> -t \\"Start\\" -ss \\".faq-title\\" -s \\"Transavia\\""
    exit 1
}
# Parse parameters
while [[ $# -gt 0 ]]; do
    case "$1" in
        -w) URL="$2"; shift 2 ;;
        -t) TEXT_SEARCH="$2"; shift 2 ;;
        -b) BUTTON_TEXT="$2"; shift 2 ;;
        -s) CSS_TEXT="$2"; shift 2 ;;
        -ss) CSS_SELECTOR="$2"; shift 2 ;;
        -c) CONTENT_TEXT="$2"; shift 2 ;;
        -cc) CONTENT_MODE="enabled"; shift 1 ;;
        -help|--help) usage ;;
        *) usage ;;
    esac
done
# Mandatory checks
if [ -z "$URL" ] || [ -z "$TEXT_SEARCH" ]; then
    usage
fi
# Validate CSS search pairing
if { [ ! -z "$CSS_TEXT" ] && [ -z "$CSS_SELECTOR" ]; } || \\
   { [ -z "$CSS_TEXT" ] && [ ! -z "$CSS_SELECTOR" ]; }; then
    echo "ERROR: -s and -ss must be used together."
    exit 1
fi
# Validate content search pairing
if { [ ! -z "$CONTENT_TEXT" ] && [ "$CONTENT_MODE" != "enabled" ]; } || \\
   { [ -z "$CONTENT_TEXT" ] && [ "$CONTENT_MODE" = "enabled" ]; }; then
    echo "ERROR: -c and -cc must be used together."
    exit 1
fi
# Paths
#
TEST_DIR="/usr/local/nagios/libexec/check_website_content/product"
OUT_DIR="$TEST_DIR/out"
SPEC_FILE="$TEST_DIR/tests/product.spec.ts"
LOG_FILE="$OUT_DIR/playwright_log.txt"
mkdir -p "$OUT_DIR"
mkdir -p "$TEST_DIR/tests"
rm -f "$SPEC_FILE" "$LOG_FILE"
###############################
# Generate Playwright Test    #
###############################
cat > "$SPEC_FILE" <<EOF
import { test, expect } from '@playwright/test';
test('Firat Gulec Website Check', async ({ page }) => {
  await page.goto('$URL');
  let buttonCheck = 'Skipped';
  let textCheck = 'Failed';
  let contentCheck = 'Skipped';
  let cssCheck = 'Skipped';
EOF
# Button click
if [ ! -z "$BUTTON_TEXT" ]; then
cat >> "$SPEC_FILE" <<EOF
  try {
    await page.getByRole('button', { name: /$BUTTON_TEXT/i }).click();
    buttonCheck = 'Passed';
  } catch {
    buttonCheck = 'Failed';
  }
EOF
fi
# Standard getByText()
cat >> "$SPEC_FILE" <<EOF
  try {
    await expect(page.getByText('$TEXT_SEARCH')).toBeVisible();
    textCheck = 'Passed';
  } catch {
    textCheck = 'Failed';
  }
EOF
# Content-based search
if [ "$CONTENT_MODE" = "enabled" ]; then
cat >> "$SPEC_FILE" <<EOF
  try {
    const body = await page.textContent('body');
    if (body && body.includes("$CONTENT_TEXT")) {
      contentCheck = 'Passed';
    } else {
      contentCheck = 'Failed';
    }
  } catch {
    contentCheck = 'Failed';
  }
EOF
fi
# CSS Selector Search
if [ ! -z "$CSS_SELECTOR" ]; then
cat >> "$SPEC_FILE" <<EOF
  try {
    const list = await page.locator('$CSS_SELECTOR').allTextContents();
    if (list.some(x => x.includes("$CSS_TEXT"))) {
      cssCheck = 'Passed';
    } else {
      cssCheck = 'Failed';
    }
  } catch {
    cssCheck = 'Failed';
  }
EOF
fi
cat >> "$SPEC_FILE" <<EOF
  console.log("RESULT_JSON:" + JSON.stringify({
    buttonCheck,
    textCheck,
    contentCheck,
    cssCheck
  }));
});
EOF
# echo "INFO: Spec file created at $SPEC_FILE"
###############################
# Run Docker Runner           #
###############################
docker run --rm \\
    -v "$TEST_DIR/tests:/tests/tests" \\
    -v "$OUT_DIR:/tests/out" \\
    playwright-runner > "$LOG_FILE" 2>&1
RAW_JSON=$(grep "RESULT_JSON:" "$LOG_FILE" | sed 's/RESULT_JSON://')
if [ -z "$RAW_JSON" ]; then
    echo "CRITICAL: No JSON output received!"
    exit 2
fi
# Extract all statuses
BUTTON_STATUS=$(echo "$RAW_JSON" | jq -r '.buttonCheck')
TEXT_STATUS=$(echo "$RAW_JSON" | jq -r '.textCheck')
CONTENT_STATUS=$(echo "$RAW_JSON" | jq -r '.contentCheck')
CSS_STATUS=$(echo "$RAW_JSON" | jq -r '.cssCheck')
# Count totals
TOTAL=0
PASSED=0
FAILED=0
for item in "$BUTTON_STATUS" "$TEXT_STATUS" "$CONTENT_STATUS" "$CSS_STATUS"; do
    if [ "$item" = "Skipped" ]; then
        continue
    fi
    ((TOTAL++))
    if [ "$item" = "Passed" ]; then
        ((PASSED++))
    else
        ((FAILED++))
    fi
done
MSG="Website check: $PASSED/$TOTAL passed, $FAILED failed | Text: $TEXT_STATUS | Button: $BUTTON_STATUS | Content: $CONTENT_STATUS | CSS: $CSS_STATUS"
if [ "$FAILED" -gt 0 ]; then
    echo "CRITICAL: $MSG"
    exit 2
else
    echo "OK: $MSG"
    exit 0
fi
