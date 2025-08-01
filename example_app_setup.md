# Testing the gem locally

## 1. Create a test Rails app

```bash
rails new test_app
cd test_app
```

## 2. Add gems to Gemfile

Add these gems to your `Gemfile`:

```ruby
# Add these to your Gemfile
gem 'rails_admin'
gem 'rails-settings-cached'
gem 'rails_admin_settings_ui', path: '/Users/r3cha/rails_admin_settings_ui'

# For authentication (required by rails_admin)
gem 'devise'
```

## 3. Bundle install

```bash
bundle install
```

## 4. Set up Devise (required for Rails Admin)

```bash
rails generate devise:install
rails generate devise User
```

## 5. Set up Rails Admin

```bash
rails generate rails_admin:install
```

## 6. Create Setting model

Create `app/models/setting.rb`:

```ruby
class Setting < RailsSettings::Base
  cache_prefix { "v1" }

  # General settings
  field :app_name, default: "My Test Application"
  field :maintenance_mode, default: false
  field :max_users, default: 1000
  field :welcome_message, default: "Welcome to our application!"

  # Email settings  
  field :mail_from, default: "noreply@example.com"
  field :mail_host, default: "smtp.example.com"
  field :mail_port, default: 587
  field :mail_ssl, default: true

  # API settings
  field :api_key, default: ""
  field :api_timeout, default: 30.0
  field :api_endpoints, default: ["https://api.example.com", "https://backup-api.example.com"]

  # Advanced settings
  field :feature_flags, default: { "new_ui" => false, "beta_features" => false, "analytics" => true }
  field :cache_ttl, default: 3600
  field :debug_mode, default: false
end
```

## 7. Configure Rails Admin

Edit `config/initializers/rails_admin.rb`:

```ruby
RailsAdmin.config do |config|
  config.authenticate_with do
    # Add your authentication logic here
    # For testing, you can comment this out or use a simple check
  end

  config.current_user_method(&:current_user)

  config.actions do
    dashboard                     # mandatory
    index                         # mandatory
    new
    export
    bulk_delete
    show
    edit
    delete
    show_in_app
    
    # Add the settings UI action
    settings_ui
  end

  # Hide the default Setting model from navigation
  config.model 'Setting' do
    visible false
  end
end
```

## 8. Run migrations

```bash
rails db:create
rails db:migrate
```

## 9. Create a user (if using Devise)

```bash
rails console
```

In the console:
```ruby
User.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password')
```

## 10. Start the server

```bash
rails server
```

## 11. Test the Settings UI

1. Go to `http://localhost:3000/admin`
2. Sign in with your test user
3. Click on "Settings" in the navigation
4. You should see your settings organized in tabs with a user-friendly interface!

## Testing different setting types

Try changing various settings to see the different field types in action:

- **Boolean**: `maintenance_mode`, `mail_ssl`, `debug_mode`
- **Integer**: `max_users`, `mail_port`, `cache_ttl`
- **Float**: `api_timeout`
- **String**: `app_name`, `api_key`, `mail_from`, `mail_host`
- **Text**: `welcome_message` (if you make it longer)
- **Array**: `api_endpoints`
- **JSON**: `feature_flags`

The interface will automatically categorize them into:
- **General**: `app_name`, `maintenance_mode`, `max_users`, etc.
- **Mail**: `mail_from`, `mail_host`, `mail_port`, `mail_ssl`
- **Api**: `api_key`, `api_timeout`, `api_endpoints`
