# frozen_string_literal: true

# Seeds branding configuration from ENV vars into the installation_configs DB table.
# Run on every Rails boot; skips records that are locked (seeded from YAML).
# SuperAdmin UI can override values later via /super_admin/app_config?config=custom_branding
#
# ENV vars to set per brand deployment:
#   INSTALLATION_NAME  - e.g. "CDP.vn"
#   BRAND_NAME         - e.g. "CDP.vn"
#   BRAND_URL          - e.g. "https://cdp.vn"
#   WIDGET_BRAND_URL   - e.g. "https://cdp.vn"
#   TERMS_URL          - e.g. "https://cdp.vn/terms"
#   PRIVACY_URL        - e.g. "https://cdp.vn/privacy"
#   LOGO               - e.g. "/brand-assets/logo.svg"
#   LOGO_DARK          - e.g. "/brand-assets/logo_dark.svg"
#   LOGO_THUMBNAIL     - e.g. "/brand-assets/logo_thumbnail.svg"
#   DISPLAY_MANIFEST   - "true" or "false"

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
    next if record.locked?

    record.value = env_val
    record.locked = false
    record.save!
  rescue ActiveRecord::RecordNotUnique
    # Concurrent boot — ignore
  end
end
