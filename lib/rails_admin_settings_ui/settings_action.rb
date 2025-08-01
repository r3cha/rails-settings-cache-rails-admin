require "rails_admin/config/actions/base"

module RailsAdminSettingsUi
  module RailsAdminSettingsUiHelperMethods
    def render_setting_field(setting)
      field_name = "settings[#{setting[:key]}]"
      field_id = "setting_#{setting[:key]}"
      current_value = setting[:current_value]
      
      case setting[:field_type]
      when :boolean
        content_tag :div, class: 'form-check' do
          check_box_tag(field_name, '1', current_value, 
                       id: field_id, 
                       class: 'form-check-input') +
          hidden_field_tag(field_name, '0') +
          label_tag(field_id, 'Enabled', class: 'form-check-label')
        end
        
      when :integer
        number_field_tag(field_name, current_value, 
                        id: field_id, 
                        class: 'form-control',
                        step: 1)
                        
      when :float
        number_field_tag(field_name, current_value, 
                        id: field_id, 
                        class: 'form-control',
                        step: 0.01)
                        
      when :text
        text_area_tag(field_name, current_value, 
                     id: field_id, 
                     class: 'form-control',
                     rows: 4)
                     
      when :email
        email_field_tag(field_name, current_value, 
                       id: field_id, 
                       class: 'form-control')
                       
      when :url
        url_field_tag(field_name, current_value, 
                     id: field_id, 
                     class: 'form-control')
                     
      when :array
        render_array_field(field_name, field_id, current_value)
        
      when :json
        render_json_field(field_name, field_id, current_value)
        
      else # :string
        text_field_tag(field_name, current_value, 
                      id: field_id, 
                      class: 'form-control')
      end
    end
    
    private
    
    def render_array_field(field_name, field_id, current_value)
      array_value = current_value.is_a?(Array) ? current_value.join(', ') : current_value.to_s
      
      content_tag :div do
        text_field_tag(field_name, array_value, 
                      id: field_id, 
                      class: 'form-control',
                      placeholder: 'Enter comma-separated values') +
        content_tag(:small, 'Separate multiple values with commas', 
                   class: 'form-text text-muted')
      end
    end
    
    def render_json_field(field_name, field_id, current_value)
      json_value = current_value.is_a?(String) ? current_value : current_value.to_json
      
      content_tag :div do
        text_area_tag(field_name, json_value, 
                     id: field_id, 
                     class: 'form-control font-monospace',
                     rows: 6,
                     placeholder: '{"key": "value"}') +
        content_tag(:small, 'Enter valid JSON', 
                   class: 'form-text text-muted')
      end
    end
  end

  class SettingsAction < RailsAdmin::Config::Actions::Base
    register_instance_option :root? do
      true
    end

    register_instance_option :breadcrumb_parent do
      nil
    end

    register_instance_option :controller do
      proc do
        # Include helper methods in the controller context
        extend RailsAdminSettingsUiHelperMethods
        
        def build_settings_data
          return {} unless defined?(Setting)
          
          settings_class = Setting
          
          # Handle different versions of rails-settings-cached
          defaults = if settings_class.respond_to?(:get_defaults)
            settings_class.get_defaults
          elsif settings_class.respond_to?(:defaults)
            settings_class.defaults
          elsif settings_class.respond_to?(:_defaults)
            settings_class._defaults
          else
            # Fallback: try to get defaults from field definitions
            {}
          end
          
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
