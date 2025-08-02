require_relative "rails_admin_settings_ui/version"
require_relative "rails_admin_settings_ui/engine"
require_relative "rails_admin_settings_ui/railtie"

module RailsAdminSettingsUi
  class Error < StandardError; end
  
  # Register the action immediately if Rails Admin is available
  if defined?(RailsAdmin) && defined?(RailsAdmin::Config::Actions)
    RailsAdmin::Config::Actions.register(:settings_ui, RailsAdminSettingsUi::SettingsUi)
  end
end
