# RailsAdminSettingsUi

A user-friendly interface for managing application settings in Rails Admin, designed to work seamlessly with the `rails-settings-cached` gem.

## Features

- **User-friendly interface**: Replace the confusing default Rails Admin table view with an intuitive settings form
- **Automatic field type detection**: Smart field rendering based on your setting values (boolean, integer, email, URL, JSON, etc.)
- **Categorized settings**: Automatically groups settings by prefix for better organization
- **Default value management**: Shows default values and allows easy reset to defaults
- **Tab-based interface**: Clean, organized display with categories in separate tabs
- **Real-time validation**: Immediate feedback for invalid JSON and other field types

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-settings-cached-rails-admin'
```

And then execute:

```bash
$ bundle install
```

## Prerequisites

This gem requires:
- `rails_admin` gem
- `rails-settings-cached` gem
- A `Setting` model that inherits from `RailsSettings::Base`

## Usage

### 1. Set up your Setting model

Make sure you have a Setting model with default values:

```ruby
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  # General settings
  field :app_name, default: "My Application"
  field :maintenance_mode, default: false
  field :max_users, default: 1000

  # Email settings  
  field :mail_from, default: "noreply@example.com"
  field :mail_host, default: "smtp.example.com"
  field :mail_port, default: 587

  # API settings
  field :api_key, default: ""
  field :api_timeout, default: 30.0
  field :api_endpoints, default: ["https://api.example.com"]

  # Advanced settings
  field :feature_flags, default: { "new_ui" => false, "beta_features" => false }
end
```

### 2. Configure Rails Admin

In your Rails Admin configuration, enable the settings action:

```ruby
# config/initializers/rails_admin.rb
RailsAdmin.config do |config|
  # ... your existing configuration

  # Enable the settings UI action
  config.actions do
    dashboard
    index
    show
    new
    edit
    delete
    settings_ui  # Add this line
  end

  # Optional: Hide the default Setting model from the navigation
  config.model 'Setting' do
    visible false
  end
end
```

### 3. Access the Settings UI

Once configured, you'll see a "Settings" tab in your Rails Admin dashboard. Click it to access the user-friendly settings interface.

## How it works

### Automatic categorization

Settings are automatically grouped into categories based on their key prefixes:
- `mail_*` settings → "Mail" category
- `api_*` settings → "API" category  
- Other settings → "General" category

### Smart field types

The gem automatically detects appropriate field types:
- `Boolean` values → Checkbox
- `Integer` values → Number field
- `Float` values → Number field with decimals
- `Array` values → Comma-separated text field
- `Hash` values → JSON text area
- Email-like strings → Email field
- URL-like strings → URL field
- Long text → Text area
- Everything else → Text field

### Default value handling

- Shows current vs. default values
- Provides "Reset to Default" buttons for modified settings
- Displays default values as help text

## Customization

### Custom categorization

Override the `extract_category` method for custom grouping logic:

```ruby
RailsAdminSettingsUi::SettingsAction.class_eval do
  private

  def extract_category(key)
    case key.to_s
    when /notification|email|mail/
      'Notifications'
    when /payment|billing|stripe/
      'Payments' 
    when /social|oauth|auth/
      'Authentication'
    else
      super
    end
  end
end
```

## Development

After checking out the repo, run:

```bash
bundle install
```

To test the gem locally before publishing:

1. Build the gem:
```bash
gem build rails_admin_settings_ui.gemspec
```

2. Install locally:
```bash
gem install rails_admin_settings_ui-0.1.0.gem
```

3. Or use it directly from your Gemfile:
```ruby
gem 'rails_admin_settings_ui', path: '/path/to/rails_admin_settings_ui'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/rails_admin_settings_ui.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
