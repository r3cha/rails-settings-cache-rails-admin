require "rails"
require_relative "settings_action"

module RailsAdminSettingsUi
  class Engine < ::Rails::Engine
    isolate_namespace RailsAdminSettingsUi

    # Action registration is handled by the Railtie

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
