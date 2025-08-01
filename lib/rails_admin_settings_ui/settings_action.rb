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
        
        def build_settings_data
          return {} unless defined?(Setting)
          
          settings_class = Setting
          
          # Debug: Let's see what methods are available
          Rails.logger.info "=== DEBUG: Setting class methods ==="
          Rails.logger.info "Available methods: #{settings_class.methods.grep(/default|field|_field/).sort}"
          Rails.logger.info "Singleton methods: #{settings_class.singleton_methods.grep(/default|field|_field/).sort}"
          
          # Handle different versions of rails-settings-cached
          defaults = if settings_class.respond_to?(:get_defaults)
            Rails.logger.info "Using get_defaults"
            settings_class.get_defaults
          elsif settings_class.respond_to?(:defaults)
            Rails.logger.info "Using defaults"
            settings_class.defaults
          elsif settings_class.respond_to?(:_defaults)
            Rails.logger.info "Using _defaults"
            settings_class._defaults
          elsif settings_class.respond_to?(:defined_fields)
            Rails.logger.info "Using defined_fields"
            settings_class.defined_fields
          elsif settings_class.respond_to?(:_defined_fields)
            Rails.logger.info "Using _defined_fields"
            settings_class._defined_fields
          else
            Rails.logger.info "No default method found, trying to extract from class"
            # Try to get field definitions from class variables or constants
            if settings_class.class_variables.any?
              Rails.logger.info "Class variables: #{settings_class.class_variables}"
            end
            if settings_class.constants.any?
              Rails.logger.info "Constants: #{settings_class.constants}"
            end
            {}
          end
          
          Rails.logger.info "Defaults found: #{defaults}"
          Rails.logger.info "Defaults class: #{defaults.class}"
          
          current_values = {}
          
          # Handle different formats of defaults (Hash vs Array)
          if defaults.is_a?(Hash)
            # Handle Hash format: {key: default_value}
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
          elsif defaults.is_a?(Array)
            # Handle Array format: might be array of field names or field objects
            Rails.logger.info "Processing Array format defaults"
            grouped_settings = {}
            
            defaults.each do |field_info|
              Rails.logger.info "Field info: #{field_info} (#{field_info.class})"
              
              # Try to extract key and default value from different possible formats
              key = nil
              default_value = nil
              
              if field_info.is_a?(Symbol) || field_info.is_a?(String)
                # Simple field name
                key = field_info.to_sym
                default_value = settings_class.public_send(key) rescue nil
              elsif field_info.is_a?(Hash)
                # Hash with field info
                key = field_info[:name] || field_info['name'] || field_info.keys.first
                default_value = field_info[:default] || field_info['default'] || field_info.values.first
              elsif field_info.respond_to?(:key) && field_info.respond_to?(:default)
                # RailsSettings::Fields object with key and default
                key = field_info.key
                default_value = field_info.default
              elsif field_info.respond_to?(:name)
                # Object with name method
                key = field_info.name
                default_value = field_info.respond_to?(:default) ? field_info.default : nil
              end
              
              Rails.logger.info "Extracted key: #{key}, default_value: #{default_value}"
              
              if key
                key = key.to_sym
                current_values[key] = settings_class.public_send(key) rescue default_value
                
                category = extract_category(key)
                grouped_settings[category] ||= []
                
                field_type = determine_field_type(default_value, current_values[key])
                
                Rails.logger.info "Adding setting: #{key} to category: #{category}, field_type: #{field_type}"
                
                grouped_settings[category] << {
                  key: key,
                  label: key.to_s.humanize,
                  default_value: default_value,
                  current_value: current_values[key],
                  field_type: field_type,
                  description: extract_description(key, settings_class)
                }
              else
                Rails.logger.info "Key extraction failed for field_info: #{field_info}"
              end
            end
          else
            Rails.logger.info "Unknown defaults format: #{defaults.class}"
            grouped_settings = {}
          end
          
          Rails.logger.info "Final grouped_settings: #{grouped_settings}"
          Rails.logger.info "Grouped settings keys: #{grouped_settings.keys}"
          
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
          
          # Get the original type from defaults using the same approach as build_settings_data
          defaults = if Setting.respond_to?(:get_defaults)
            Setting.get_defaults
          elsif Setting.respond_to?(:defaults)
            Setting.defaults
          elsif Setting.respond_to?(:_defaults)
            Setting._defaults
          else
            {}
          end
          
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
        
        @settings_data = build_settings_data
        
        if request.post?
          update_settings
          flash[:notice] = "Settings updated successfully!"
          redirect_to request.path
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

  end
end
