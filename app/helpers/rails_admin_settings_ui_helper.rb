module RailsAdminSettingsUiHelper
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
