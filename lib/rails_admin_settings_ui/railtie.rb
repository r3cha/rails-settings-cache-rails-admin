module RailsAdminSettingsUi
  class Railtie < Rails::Railtie
    railtie_name :rails_admin_settings_ui

    initializer "rails_admin_settings_ui.register_action", before: :load_config_initializers do
      # This will run before the Rails Admin config initializer
      Rails.application.config.to_prepare do
        if defined?(RailsAdmin) && defined?(RailsAdmin::Config::Actions)
          RailsAdmin::Config::Actions.register(:settings_ui, RailsAdminSettingsUi::SettingsAction)
        end
      end
    end
  end
end
