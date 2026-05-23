import { test, expect } from '@playwright/test';

// Template: add a specific user flow on top of the auto-generated suite.
// Copy this file into ~/.tester/specs/<projectKey>/tests/<your-flow>.spec.ts and edit.
// The playwright.config.ts in the same directory already loads baseURL + storageState.

test('TODO_FLOW_NAME — describe what the user is doing', async ({ page }) => {
  // 1. Navigate to the entry point.
  await page.goto('/your-entry-path');

  // 2. Interact. Prefer role-based locators — they survive markup changes.
  await page.getByRole('button', { name: /TODO action label/i }).click();

  // 3. Fill any forms. The tester crawler records form field names — check
  //    routes/elements in the API to see what's available on each route.
  await page.getByLabel('Email').fill('test@example.com');
  await page.getByLabel('Password').fill(process.env.TEST_PASSWORD ?? '');

  // 4. Assert the expected outcome. Be specific — `toHaveURL` + a visible-text check
  //    is far more durable than a generic `toBeVisible`.
  await page.getByRole('button', { name: /submit/i }).click();
  await expect(page).toHaveURL(/.*dashboard/);
  await expect(page.getByRole('heading', { name: /welcome/i })).toBeVisible();
});
