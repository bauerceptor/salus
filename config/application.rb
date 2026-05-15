require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Salus
  class Application < Rails::Application
    config.load_defaults 8.0

    config.time_zone = "Europe/Paris"

    config.active_record.encryption.primary_key = ENV.fetch(
      "ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY", nil
    )
    config.active_record.encryption.deterministic_key = ENV.fetch(
      "ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY", nil
    )
    config.active_record.encryption.key_derivation_salt = ENV.fetch(
      "ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT", nil
    )

    config.i18n.load_path += Rails.root.glob("config/locales/**/*.{rb,yml}")
    config.active_record.schema_format = :sql
  end
end
