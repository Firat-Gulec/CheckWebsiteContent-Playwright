#!/bin/bash
set -e
echo "Running Playwright tests..."
cd /tests/tests
# it creates JSON report in /tests/out by using playwright.config.ts
npx playwright test --config=playwright.config.ts
echo "Done. JSON report created in /tests/out"
