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
          unless defined?(Setting)
            Rails.logger.warn "Setting class not found!"
            return {}
          end
          
          settings_class = Setting
          
          # Verify the Setting class has the methods we need
          Rails.logger.info "=== SETTING CLASS VERIFICATION ==="
          Rails.logger.info "Setting class: #{settings_class}"
          Rails.logger.info "Setting ancestors: #{settings_class.ancestors.map(&:name)}"
          Rails.logger.info "Setting responds to field methods? #{settings_class.respond_to?(:field)}"
          
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

        def update_single_setting
          return unless defined?(Setting) && params[:setting_key] && params[:setting_value]
          
          key = params[:setting_key]
          value = params[:setting_value]
          
          Rails.logger.info "=== UPDATING SINGLE SETTING ==="
          Rails.logger.info "Key: #{key}, Value: #{value}"
          
          begin
            # Convert value based on the original type
            converted_value = convert_value(key, value)
            
            Rails.logger.info "Setting #{key}: #{value} -> #{converted_value} (#{converted_value.class})"
            
            # Use direct ActiveRecord approach to bypass full model validation
            # This prevents validation errors from other unrelated settings
            setting_record = Setting.find_or_initialize_by(var: key)
            
            # Serialize the value properly based on the rails-settings-cached format
            serialized_value = case converted_value
            when String
              converted_value
            when NilClass
              nil
            else
              # Use YAML serialization for complex types (same as rails-settings-cached)
              converted_value.to_yaml
            end
            
            Rails.logger.info "Serialized value: #{serialized_value}"
            
            # Update directly without triggering full model validations
            if setting_record.persisted?
              result = setting_record.update_column(:value, serialized_value)
              Rails.logger.info "Updated existing record: #{result}"
            else
              setting_record.value = serialized_value
              result = setting_record.save(validate: false) # Skip validations to avoid cross-field validation errors
              Rails.logger.info "Created new record: #{result}"
            end
            
            # Clear the settings cache so the new value is loaded
            if Setting.respond_to?(:clear_cache)
              Setting.clear_cache
            elsif Setting.respond_to?(:reload!)
              Setting.reload!
            end
            
            # Verify the setting was actually updated
            new_value = Setting.public_send(key)
            Rails.logger.info "Verification: #{key} is now #{new_value}"
            
            return { success: true, message: "Setting updated successfully", new_value: new_value }
            
          rescue => e
            Rails.logger.error "Failed to update setting #{key}: #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
            return { success: false, error: e.message }
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
          # Handle blank values
          return nil if value.nil?
          return "" if value == ""
          
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
            # Handle checkbox values - they come as "1" for checked, "0" for unchecked
            if value.is_a?(Array) && value.size == 2
              # Rails checkbox helper sends ["0", "1"] when checked, ["0"] when unchecked
              value.include?("1")
            else
              value == '1' || value == 'true' || value == true
            end
          when Integer
            value.to_s.strip.empty? ? 0 : value.to_i
          when Float
            value.to_s.strip.empty? ? 0.0 : value.to_f
          when Array
            if value.is_a?(Array)
              value
            else
              value.to_s.split(',').map(&:strip).reject(&:empty?)
            end
          when Hash
            if value.is_a?(Hash)
              value
            else
              JSON.parse(value.to_s)
            end
          else
            value.to_s
          end
        rescue JSON::ParserError => e
          Rails.logger.error "JSON parsing error for key #{key}: #{e.message}"
          value.to_s
        end
        
        Rails.logger.info "=== SETTINGS ACTION ==="
        Rails.logger.info "Request method: #{request.method}"
        Rails.logger.info "Request path: #{request.path}"
        Rails.logger.info "Params: #{params.inspect}"
        Rails.logger.info "AJAX request: #{request.xhr?}"
        
        @settings_data = build_settings_data
        
        if request.post?
          Rails.logger.info "Processing POST request for settings update"
          
          # Handle individual setting update (AJAX)
          if request.xhr? && params[:setting_key] && params[:setting_value]
            Rails.logger.info "Processing individual setting update via AJAX"
            result = update_single_setting
            render json: result
          else
            Rails.logger.info "No individual setting update parameters found"
            # Fallback for non-AJAX requests or invalid parameters
            render json: { success: false, error: "Invalid request parameters" }, status: 400
          end
        else
          Rails.logger.info "Rendering settings page with #{@settings_data.size} categories"
          render template: 'rails_admin_settings_ui/settings/index'
        end
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

    register_instance_option :visible? do
      true
    end

    register_instance_option :action_name do
      'settings_action'
    end

    # Set proper title with fallback
    register_instance_option :title do
      I18n.t('admin.actions.settings_action.title', default: 'Settings')
    end

    # Set proper menu label with fallback
    register_instance_option :menu_label do
      I18n.t('admin.actions.settings_action.menu', default: 'Settings')
    end

    # Set breadcrumb text with fallback
    register_instance_option :breadcrumb_text do
      I18n.t('admin.actions.settings_action.breadcrumb', default: 'Settings')
    end

  end
end
