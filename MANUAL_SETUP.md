# Manual Setup Instructions

Since Rails Admin action registration can have timing issues, here's how to manually configure the gem:

## Step 1: Add to your Rails Admin initializer

In your `config/initializers/rails_admin.rb`, modify it like this:

```ruby
# Load the settings action
require 'rails_admin_settings_ui'

RailsAdmin.config do |config|
  # ... your existing config

  config.actions do
    dashboard
    index
    show  
    new
    edit
    delete
    
    # Manually register the settings action
    collection :settings_ui, RailsAdminSettingsUi::SettingsUi
  end

  # Hide the default Setting model from navigation
  config.model 'Setting' do
    visible false
  end
end
```

## Step 2: Alternative approach using register

If the above doesn't work, try this approach:

```ruby
# Load the settings action
require 'rails_admin_settings_ui'

# Register the action manually
RailsAdmin::Config::Actions.register(:settings_ui, RailsAdminSettingsUi::SettingsUi)

RailsAdmin.config do |config|
  # ... your existing config

  config.actions do
    dashboard
    index
    show  
    new
    edit
    delete
    settings_ui  # Now this should work
  end

  # Hide the default Setting model from navigation
  config.model 'Setting' do
    visible false
  end
end
```

## Step 3: Restart your Rails server

Make sure to restart your Rails server after making these changes.
