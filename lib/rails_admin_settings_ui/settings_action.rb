require "rails_admin/config/actions/base"

module RailsAdminSettingsUi
  class SettingsAction < RailsAdmin::Config::Actions::Base
    register_instance_option :root? do
      true
    end

    register_instance_option :breadcrumb_parent do
      nil
    end

    register_instance_option :controller do
      proc do
        @settings_data = build_settings_data
        
        if request.post?
          update_settings
          flash[:notice] = "Settings updated successfully!"
          redirect_to rails_admin.settings_ui_path
        end

        render template: 'rails_admin_settings_ui/settings/index'
      end
    end

    register_instance_option :route_fragment do
      'settings'
    end

    register_instance_option :link_icon do
      'fa fa-cog'
    end

    register_instance_option :http_methods do
      [:get, :post]
    end

    private

    def build_settings_data
      return {} unless defined?(Setting)
      
      settings_class = Setting
      defaults = settings_class.get_defaults
      current_values = {}
      
      # Get current values from database
      defaults.each_key do |key|
        current_values[key] = settings_class.public_send(key)
      end
      
      # Group settings by category (based on key prefix or custom logic)
      grouped_settings = {}
      defaults.each do |key, default_value|
        category = extract_category(key)
        grouped_settings[category] ||= []
        
        field_type = determine_field_type(default_value, current_values[key])
        
        grouped_settings[category] << {
          key: key,
          label: key.to_s.humanize,
          default_value: default_value,
          current_value: current_values[key],
          field_type: field_type,
          description: extract_description(key, settings_class)
        }
      end
      
      grouped_settings
    end

    def update_settings
      return unless defined?(Setting) && params[:settings]
      
      params[:settings].each do |key, value|
        # Convert value based on the original type
        converted_value = convert_value(key, value)
        Setting.public_send("#{key}=", converted_value)
      end
    end

    def extract_category(key)
      # Try to extract category from key (e.g., 'mail_from' -> 'Mail', 'api_key' -> 'API')
      parts = key.to_s.split('_')
      if parts.length > 1
        parts.first.humanize
      else
        'General'
      end
    end

    def determine_field_type(default_value, current_value)
      value = current_value || default_value
      
      case value
      when TrueClass, FalseClass
        :boolean
      when Integer
        :integer
      when Float
        :float
      when Array
        :array
      when Hash
        :json
      else
        # Check if it looks like a long text
        if value.to_s.length > 100 || value.to_s.include?("\n")
          :text
        elsif value.to_s.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
          :email
        elsif value.to_s.match?(/\Ahttps?:\/\//)
          :url
        else
          :string
        end
      end
    end

    def extract_description(key, settings_class)
      # Try to extract description from comments or documentation
      # This is a simple implementation - you might want to enhance it
      case key.to_s
      when /mail/
        "Email related configuration"
      when /api/
        "API configuration"
      when /cache/
        "Caching configuration"
      else
        nil
      end
    end

    def convert_value(key, value)
      return nil if value.blank?
      
      # Get the original type from defaults
      defaults = Setting.get_defaults
      original_value = defaults[key.to_sym] || defaults[key.to_s]
      
      case original_value
      when TrueClass, FalseClass
        value == '1' || value == 'true'
      when Integer
        value.to_i
      when Float
        value.to_f
      when Array
        value.is_a?(Array) ? value : value.split(',').map(&:strip)
      when Hash
        value.is_a?(Hash) ? value : JSON.parse(value)
      else
        value
      end
    rescue JSON::ParserError
      value
    end
  end
end
