# CDP.vn Whitelabel — Design Spec

## Context

Whitelabel Chatwoot hoàn toàn bằng brand CDP.vn. Scope: **frontend user-facing không hiện "Chatwoot"**. Không cần đổi Ruby module names, không cần sửa SuperAdmin screens.

Kiến trúc: **ENV-driven** — mỗi brand deployment = bộ ENV vars riêng → seed vào `installation_configs` DB → frontend đọc qua `window.globalConfig` đã có sẵn.

---

## Architecture

```
ENV vars (brand độc lập)
    ↓  config/initializers/010_brand_config.rb (seed 1 lần lúc deploy)
installation_configs DB table
    ↓  dashboard_controller.rb đọc và đẩy vào window.globalConfig
window.globalConfig
    ↓  globalConfig.js store / useBranding.js
Vue components (BRAND_NAME, INSTALLATION_NAME, LOGO...)
```

Chatwoot đã có đầy đủ infrastructure cho việc này:
- `installation_config` DB model — key-value store cho mọi config
- `window.globalConfig` — expose config lên frontend
- `useBranding().replaceInstallationName()` — thay "Chatwoot" bằng `INSTALLATION_NAME` trong i18n strings
- SuperAdmin UI — có sẵn card "Custom Branding" (bị bug — sẽ fix)

---

## Changes

### 1. Unlock branding config keys

**File:** `config/installation_config.yml`

Đổi `locked: true` → `locked: false` cho 10 branding keys:

```yaml
INSTALLATION_NAME:
  value: 'Chatwoot'
  locked: false          # ← đổi
LOGO:
  value: '/brand-assets/logo.svg'
  locked: false         # ← đổi
LOGO_DARK:
  value: '/brand-assets/logo_dark.svg'
  locked: false         # ← đổi
LOGO_THUMBNAIL:
  value: '/brand-assets/logo_thumbnail.svg'
  locked: false         # ← đổi
BRAND_NAME:
  value: 'Chatwoot'
  locked: false         # ← đổi
BRAND_URL:
  value: 'https://www.chatwoot.com'
  locked: false         # ← đổi
WIDGET_BRAND_URL:
  value: 'https://www.chatwoot.com'
  locked: false         # ← đổi
TERMS_URL:
  value: 'https://www.chatwoot.com/terms-of-service'
  locked: false         # ← đổi
PRIVACY_URL:
  value: 'https://www.chatwoot.com/privacy-policy'
  locked: false         # ← đổi
DISPLAY_MANIFEST:
  value: true
  locked: false         # ← đổi
```

Tương tự update `enterprise/config/premium_installation_config.yml` — cùng 10 keys, unlocked.

---

### 2. Fix SuperAdmin controller

**File:** `app/controllers/super_admin/app_configs_controller.rb`

Thêm `custom_branding` vào `allowed_configs` mapping:

```ruby
def mapping
  @mapping ||= {
    'custom_branding' => %w[
      INSTALLATION_NAME LOGO LOGO_DARK LOGO_THUMBNAIL
      BRAND_NAME BRAND_URL WIDGET_BRAND_URL
      TERMS_URL PRIVACY_URL DISPLAY_MANIFEST
    ],
    'facebook' => %w[FB_APP_ID FB_VERIFY_TOKEN ...],
    # ... giữ nguyên các config khác
  }
end
```

Sau bước này, SuperAdmin → Settings → Custom Branding → ⚙️ sẽ hiện đúng 10 form fields cho branding.

---

### 3. Seed initializer (ENV → DB)

**File:** `config/initializers/010_brand_config.rb` (tạo mới)

```ruby
BRANDING_KEYS = %w[
  INSTALLATION_NAME LOGO LOGO_DARK LOGO_THUMBNAIL
  BRAND_NAME BRAND_URL WIDGET_BRAND_URL
  TERMS_URL PRIVACY_URL DISPLAY_MANIFEST
].freeze

BRANDING_KEYS.each do |key|
  env_val = ENV[key]
  next if env_val.blank?

  record = InstallationConfig.find_or_initialize_by(name: key)
  next if record.locked?

  record.value = env_val
  record.locked = false
  record.save!
end
```

Chạy 1 lần khi deploy. Sau đó SuperAdmin UI có thể override manual nếu cần.

---

### 4. Replace logo assets

**Files:** Thay nội dung (giữ nguyên filename)

| File | Thay bằng |
|---|---|
| `public/brand-assets/logo.svg` | CDP.vn logo SVG (light) |
| `public/brand-assets/logo_dark.svg` | CDP.vn logo SVG (dark) |
| `public/brand-assets/logo_thumbnail.svg` | CDP.vn logo SVG nhỏ (favicon) |
| `public/favicon.ico` | CDP.vn favicon |
| `public/android-icon-*.png` | CDP.vn icons (nếu cần) |
| `public/apple-icon*.png` | CDP.vn icons (nếu cần) |
| `app/javascript/design-system/images/logo.svg`, `logo-dark.png`, `logo-thumbnail.svg` | CDP.vn logo |
| `app/javascript/widget/assets/images/logo.svg` | CDP.vn logo widget |
| `app/javascript/dashboard/assets/images/chatwoot_bot.png` | CDP.vn bot avatar |

---

### 5. Optional: Fix 3 hardcoded Vue files

Nếu muốn clean hoàn toàn, fix 3 Vue files có hardcoded "Chatwoot":

| File | Fix |
|---|---|
| `app/javascript/survey/views/Response.vue` — `alt="Chatwoot logo"` | `alt="logo"` hoặc `:alt="brandName + ' logo'"` |
| `app/javascript/dashboard/routes/dashboard/helpcenter/components/ArticleSearch/Header.vue` — `default: 'Chatwoot'` | `default: globalConfig.installationName` |
| `app/javascript/v3/views/auth/signup/Index.vue` — `installationName === 'Chatwoot'` | Dùng `isAChatwootInstance` từ store |

---

## ENV Variables Template (per brand)

```env
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

## Verification

1. `bundle exec rails runner "puts InstallationConfig.pluck(:name, :value).select { |n, _| n.include?('BRAND') || n.include?('LOGO') || n.include?('INSTALLATION') }"` — kiểm tra DB đã có đúng giá trị
2. Restart Rails server
3. Truy cập `/app/login` → không còn thấy "Chatwoot"
4. Mở DevTools → `window.globalConfig` → kiểm tra `installationName`, `brandName`, `logo` đúng
5. `pnpm eslint` — không có linting errors
6. Kiểm tra email templates (navigate login → reset password) — "Powered by CDP.vn"
7. Kiểm tra widget embed — logo + "Powered by CDP.vn" badge
