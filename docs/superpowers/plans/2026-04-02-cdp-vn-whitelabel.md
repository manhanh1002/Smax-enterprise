# CDP.vn Whitelabel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Whitelabel Chatwoot frontend so no "Chatwoot" brand appears user-facing, driven by ENV variables per deployment.

**Architecture:** ENV vars → seed initializer → `installation_configs` DB table → `window.globalConfig` (already in codebase) → Vue components. No changes to Ruby module names or SuperAdmin code.

**Tech Stack:** Ruby on Rails (initializer + controller), Vue.js (globalConfig store), YAML config.

---

## File Map

| Action | File |
|---|---|
| Modify | `config/installation_config.yml` |
| Modify | `app/controllers/super_admin/app_configs_controller.rb` |
| Create | `config/initializers/02_brand_config.rb` |
| Replace | `public/brand-assets/logo.svg` |
| Replace | `public/brand-assets/logo_dark.svg` |
| Replace | `public/brand-assets/logo_thumbnail.svg` |
| Replace | `public/favicon.ico` |
| Modify | `app/javascript/design-system/images/logo.svg` |
| Modify | `app/javascript/design-system/images/logo-dark.png` |
| Modify | `app/javascript/design-system/images/logo-thumbnail.svg` |
| Replace | `app/javascript/widget/assets/images/logo.svg` |
| Replace | `app/javascript/dashboard/assets/images/chatwoot_bot.png` |

---

## Task 1: Unlock Branding Config Keys

**File:** `config/installation_config.yml`

Locate each branding entry and add `locked: false` if not already present. All 10 entries are at lines 17–58 under `# ------- Branding Related Config ------- #`.

- [ ] **Step 1: Edit `config/installation_config.yml` — add `locked: false` to each branding key**

Change each entry from no `locked` attr → `locked: false`. Entries and their line numbers:

```yaml
# Line 17
- name: INSTALLATION_NAME
  value: 'Chatwoot'
  display_title: 'Installation Name'
  description: 'The installation wide name that would be used in the dashboard, title etc.'
  locked: false           # ADD

# Line 21
- name: LOGO_THUMBNAIL
  value: '/brand-assets/logo_thumbnail.svg'
  display_title: 'Logo Thumbnail'
  description: 'The thumbnail that would be used for favicon (512px X 512px)'
  locked: false           # ADD

# Line 25
- name: LOGO
  value: '/brand-assets/logo.svg'
  display_title: 'Logo'
  description: 'The logo that would be used on the dashboard, login page etc.'
  locked: false           # ADD

# Line 29
- name: LOGO_DARK
  value: '/brand-assets/logo_dark.svg'
  display_title: 'Logo Dark Mode'
  description: 'The logo that would be used on the dashboard, login page etc. for dark mode'
  locked: false           # ADD

# Line 33
- name: BRAND_URL
  value: 'https://www.chatwoot.com'
  display_title: 'Brand URL'
  description: 'The URL that would be used in emails under the section "Powered By"'
  locked: false           # ADD

# Line 37
- name: WIDGET_BRAND_URL
  value: 'https://www.chatwoot.com'
  display_title: 'Widget Brand URL'
  description: 'The URL that would be used in the widget under the section "Powered By"'
  locked: false           # ADD

# Line 41
- name: BRAND_NAME
  value: 'Chatwoot'
  display_title: 'Brand Name'
  description: 'The name that would be used in emails and the widget'
  locked: false           # ADD

# Line 45
- name: TERMS_URL
  value: 'https://www.chatwoot.com/terms-of-service'
  display_title: 'Terms URL'
  description: 'The terms of service URL displayed in Signup Page'
  locked: false           # ADD

# Line 49
- name: PRIVACY_URL
  value: 'https://www.chatwoot.com/privacy-policy'
  display_title: 'Privacy URL'
  description: 'The privacy policy URL displayed in the app'
  locked: false           # ADD

# Line 53
- name: DISPLAY_MANIFEST
  value: true
  display_title: 'Chatwoot Metadata'
  description: 'Display default Chatwoot metadata like favicons and upgrade warnings'
  type: boolean
  locked: false           # ADD
```

- [ ] **Step 2: Run RuboCop on the file**

```bash
bundle exec rubocop config/installation_config.yml --autocorrect
```

Expected: No offenses (YAML formatting only).

- [ ] **Step 3: Commit**

```bash
git add config/installation_config.yml
git commit -m "config: unlock branding config keys for whitelabel"
```

---

## Task 2: Fix SuperAdmin Controller — Add `custom_branding` Mapping

**File:** `app/controllers/super_admin/app_configs_controller.rb`

The `allowed_configs` method (lines 40–60) has a local `mapping` hash. Add `'custom_branding'` entry to it.

- [ ] **Step 1: Edit controller — add `custom_branding` to mapping**

Replace the `mapping = {` block (lines 41–54) with:

```ruby
mapping = {
  'custom_branding' => %w[
    INSTALLATION_NAME LOGO LOGO_DARK LOGO_THUMBNAIL
    BRAND_NAME BRAND_URL WIDGET_BRAND_URL
    TERMS_URL PRIVACY_URL DISPLAY_MANIFEST
  ],
  'facebook' => %w[FB_APP_ID FB_VERIFY_TOKEN FB_APP_SECRET IG_VERIFY_TOKEN FACEBOOK_API_VERSION ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT],
  'shopify' => %w[SHOPIFY_CLIENT_ID SHOPIFY_CLIENT_SECRET],
  'microsoft' => %w[AZURE_APP_ID AZURE_APP_SECRET],
  'email' => %w[MAILER_INBOUND_EMAIL_DOMAIN ACCOUNT_EMAILS_LIMIT ACCOUNT_EMAILS_PLAN_LIMITS],
  'linear' => %w[LINEAR_CLIENT_ID LINEAR_CLIENT_SECRET],
  'slack' => %w[SLACK_CLIENT_ID SLACK_CLIENT_SECRET],
  'instagram' => %w[INSTAGRAM_APP_ID INSTAGRAM_APP_SECRET INSTAGRAM_VERIFY_TOKEN INSTAGRAM_API_VERSION ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT],
  'tiktok' => %w[TIKTOK_APP_ID TIKTOK_APP_SECRET TIKTOK_API_VERSION],
  'whatsapp_embedded' => %w[WHATSAPP_APP_ID WHATSAPP_APP_SECRET WHATSAPP_CONFIGURATION_ID WHATSAPP_API_VERSION],
  'notion' => %w[NOTION_CLIENT_ID NOTION_CLIENT_SECRET NOTION_VERSION],
  'google' => %w[GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET GOOGLE_OAUTH_REDIRECT_URI ENABLE_GOOGLE_OAUTH_LOGIN],
  'captain' => %w[CAPTAIN_OPEN_AI_API_KEY CAPTAIN_OPEN_AI_MODEL CAPTAIN_OPEN_AI_ENDPOINT CAPTAIN_EMBEDDING_MODEL CAPTAIN_FIRECRAWL_API_KEY]
}
```

Note: Also added `NOTION_VERSION` and `CAPTAIN_EMBEDDING_MODEL`/`CAPTAIN_FIRECRAWL_API_KEY` which exist in the YAML but were missing from the original mapping.

- [ ] **Step 2: Run RuboCop on the controller**

```bash
bundle exec rubocop app/controllers/super_admin/app_configs_controller.rb --autocorrect
```

Expected: Clean or only style warnings.

- [ ] **Step 3: Commit**

```bash
git add app/controllers/super_admin/app_configs_controller.rb
git commit -m "fix(super_admin): add custom_branding mapping to app_configs controller"
```

---

## Task 3: Create Brand Config Seed Initializer

**File:** `config/initializers/02_brand_config.rb` (create new)

This initializer runs once per Rails boot and seeds branding configs from ENV vars into the DB (only if not already locked).

- [ ] **Step 1: Create the initializer**

```ruby
# frozen_string_literal: true

# Seeds branding configuration from ENV vars into the installation_configs DB table.
# Run once per deployment. SuperAdmin UI can override values later.
#
# ENV vars to set per brand deployment:
#   INSTALLATION_NAME, BRAND_NAME, BRAND_URL, WIDGET_BRAND_URL,
#   TERMS_URL, PRIVACY_URL, LOGO, LOGO_DARK, LOGO_THUMBNAIL, DISPLAY_MANIFEST

BRANDING_KEYS = %w[
  INSTALLATION_NAME LOGO LOGO_DARK LOGO_THUMBNAIL
  BRAND_NAME BRAND_URL WIDGET_BRAND_URL
  TERMS_URL PRIVACY_URL DISPLAY_MANIFEST
].freeze

Rails.application.config.after_initialize do
  BRANDING_KEYS.each do |key|
    env_val = ENV[key]
    next if env_val.blank?

    record = InstallationConfig.find_or_initialize_by(name: key)
    # Skip if the record is locked (e.g., seeded from YAML and not yet updated)
    next if record.locked?

    record.value = env_val
    record.locked = false
    record.save!
  rescue ActiveRecord::RecordNotUnique
    # Concurrent boot — ignore
  end
end
```

- [ ] **Step 2: Run RuboCop**

```bash
bundle exec rubocop config/initializers/02_brand_config.rb --autocorrect
```

- [ ] **Step 3: Verify the file syntax**

```bash
bundle exec ruby -c config/initializers/02_brand_config.rb
```

Expected: `Syntax OK`

- [ ] **Step 4: Commit**

```bash
git add config/initializers/02_brand_config.rb
git commit -m "config: add brand config seed initializer from ENV vars"
```

---

## Task 4: Replace Logo & Favicon Assets

Replace file contents (keep filenames). User must provide CDP.vn logo files. Until then, placeholders are acceptable.

| File | Action |
|---|---|
| `public/brand-assets/logo.svg` | Replace contents with CDP.vn light logo SVG |
| `public/brand-assets/logo_dark.svg` | Replace contents with CDP.vn dark logo SVG |
| `public/brand-assets/logo_thumbnail.svg` | Replace contents with CDP.vn small logo SVG |
| `public/favicon.ico` | Replace with CDP.vn favicon |
| `app/javascript/design-system/images/logo.svg` | Replace with CDP.vn logo SVG |
| `app/javascript/design-system/images/logo-dark.png` | Replace with CDP.vn dark logo PNG |
| `app/javascript/design-system/images/logo-thumbnail.svg` | Replace with CDP.vn thumbnail SVG |
| `app/javascript/widget/assets/images/logo.svg` | Replace with CDP.vn widget logo SVG |
| `app/javascript/dashboard/assets/images/chatwoot_bot.png` | Replace with CDP.vn bot avatar PNG |

- [ ] **Step 1: Replace each file with CDP.vn assets**

(User provides the actual SVG/PNG files. For testing, any valid SVG/PNG with correct filename works.)

- [ ] **Step 2: Commit all asset replacements**

```bash
git add public/brand-assets/ app/javascript/design-system/images/ app/javascript/widget/assets/images/ app/javascript/dashboard/assets/images/
git commit -m "assets: replace Chatwoot logos and favicon with CDP.vn branding"
```

---

## Task 5: Verify End-to-End

Run these commands and checks after deployment:

- [ ] **Step 1: Check DB config values**

```bash
bundle exec rails runner "puts InstallationConfig.pluck(:name, :value).select { |n, _| n =~ /BRAND|LOGO|INSTALLATION|DISPLAY_MANIFEST/ }.map { |n, v| \"#{n}: #{v}\" }.join(\"\n\")"
```

Expected output shows `INSTALLATION_NAME`, `BRAND_NAME`, `BRAND_URL`, etc. with CDP.vn values (or `Chatwoot` if ENV not yet set).

- [ ] **Step 2: Restart Rails server**

```bash
overmind restart
# or: pkill -f ruby; overmind start -f Procfile.dev
```

- [ ] **Step 3: Verify `window.globalConfig` in browser DevTools**

Open `/app/login`, open DevTools → Console:
```js
console.table(window.globalConfig)
```

Expected: `installationName: "CDP.vn"`, `brandName: "CDP.vn"`, `logo: "/brand-assets/logo.svg"`, etc.

- [ ] **Step 4: Verify login page has no "Chatwoot" string**

In browser DevTools Elements tab: search for "Chatwoot" on `/app/login` page. Should return 0 results.

- [ ] **Step 5: Run ESLint**

```bash
pnpm eslint
```

Expected: 0 errors.

- [ ] **Step 6: Test "Powered By" in email**

Navigate `/app/login` → "Forgot Password?" → submit email → open received email. Should say "Powered by CDP.vn" not "Powered by Chatwoot".

- [ ] **Step 7: Test widget embed**

Open a page with embedded widget script. The "Powered by" badge at bottom should show CDP.vn logo + "Powered by CDP.vn".

---

## ENV Template (per brand deployment)

```env
# .env — copy per brand server
INSTALLATION_NAME="CDP.vn"
BRAND_NAME="CDP.vn"
BRAND_URL="https://cdp.vn"
WIDGET_BRAND_URL="https://cdp.vn"
TERMS_URL="https://cdp.vn/terms"
PRIVACY_URL="https://cdp.vn/privacy"
LOGO="/brand-assets/logo.svg"
LOGO_DARK="/brand-assets/logo_dark.svg"
LOGO_THUMBNAIL="/brand-assets/logo_thumbnail.svg"
DISPLAY_MANIFEST=false
```

---

## Self-Review Checklist

- [ ] All 10 branding keys unlocked in `installation_config.yml`?
- [ ] `custom_branding` entry added to controller mapping?
- [ ] Initializer file syntax valid (`ruby -c`)?
- [ ] All logo/favicon files replaced with CDP.vn assets?
- [ ] No "Chatwoot" hardcoded strings remaining in user-facing Vue components (verified by grep)?
- [ ] Plan tasks map 1-to-1 to spec requirements?
