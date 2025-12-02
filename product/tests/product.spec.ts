import { test, expect } from '@playwright/test';
test('Firat Gulec Website Check', async ({ page }) => {
  await page.goto('www.webpagecheck.com');
  let buttonCheck = 'Skipped';
  let textCheck = 'Failed';
  let contentCheck = 'Skipped';
  let cssCheck = 'Skipped';
  try {
    await expect(page.getByText('checktext_script')).toBeVisible();
    textCheck = 'Passed';
  } catch {
    textCheck = 'Failed';
  }
  try {
    const body = await page.textContent('body');
    if (body && body.includes("checktext_script")) {
      contentCheck = 'Passed';
    } else {
      contentCheck = 'Failed';
    }
  } catch {
    contentCheck = 'Failed';
  }
  console.log("RESULT_JSON:" + JSON.stringify({
    buttonCheck,
    textCheck,
    contentCheck,
    cssCheck
  }));
});
