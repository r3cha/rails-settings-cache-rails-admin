require "rails"
require_relative "settings_action"

module RailsAdminSettingsUi
  class Engine < ::Rails::Engine
    isolate_namespace RailsAdminSettingsUi

    # Action registration is handled by the Railtie

    # Load locale files
    config.before_configuration do
      I18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', 'locales', '*.yml')]
    end

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
