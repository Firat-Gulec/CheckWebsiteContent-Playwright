# 🎭 Playwright-Based Nagios Content Monitoring Plugin

This project creates a custom Nagios plugin leveraging **Playwright** to monitor the **actual page content and element visibility** of modern websites, moving beyond traditional HTTP status checks.

Playwright is a fast and reliable end-to-end testing library that supports Chromium, Firefox, and WebKit browsers. This plugin runs Playwright tests inside a Docker container to ensure monitoring environment consistency and outputs structured results compatible with Nagios.

## ✨ Features

* **End-to-End Content Verification:** Checks for the visibility of specific text (`getByText`), content inside elements found by a CSS selector, and general text presence within the page body.
* **Dynamic Test Generation:** Automatically generates the Playwright test file (`.spec.ts`) based on command-line arguments provided by Nagios.
* **Docker Isolation:** Runs Playwright and all its dependencies inside a Docker container, preventing dependency conflicts on the host machine.
* **Nagios-Compatible Output:** Returns `OK` or `CRITICAL` statuses with a detailed message following Nagios standards.

