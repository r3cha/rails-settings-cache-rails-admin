require "rails"
require_relative "settings_action"

module RailsAdminSettingsUi
  class Engine < ::Rails::Engine
    isolate_namespace RailsAdminSettingsUi

    initializer "rails_admin_settings_ui.setup" do |app|
      # Register the custom action with RailsAdmin
      ActiveSupport.on_load(:after_initialize) do
        RailsAdmin::Config::Actions.register(:settings_ui, RailsAdminSettingsUi::SettingsAction)
      end
    end

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
