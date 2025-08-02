require "rails"
require_relative "settings_ui"
require_relative "helper"

module RailsAdminSettingsUi
  class Engine < ::Rails::Engine
    isolate_namespace RailsAdminSettingsUi

    # Action registration is handled by the Railtie

    # Load locale files
    config.before_configuration do
      I18n.load_path += Dir[File.join(File.dirname(__FILE__), '..', 'locales', '*.yml')]
    end

    # Include helpers in Rails Admin
    initializer "rails_admin_settings_ui.helpers" do
      ActiveSupport.on_load(:action_view) do
        ActionView::Base.include RailsAdminSettingsUi::Helper
      end
    end

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
