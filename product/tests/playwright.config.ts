import { defineConfig } from '@playwright/test';
export default defineConfig({
  reporter: [
    ['json', { outputFile: '/tests/out/product-result.json' }]
  ],
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
});
package.json
{
  "devDependencies": {
    "@playwright/test": "1.56.1"
  }
}
