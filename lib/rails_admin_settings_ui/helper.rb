module RailsAdminSettingsUi
  module Helper
    def badge_color_for_type(field_type)
      case field_type
      when :boolean
        'success'
      when :integer, :float
        'info'
      when :text, :json
        'warning'
      when :email, :url
        'primary'
      when :array
        'dark'
      else # :string
        'dark'
      end
    end
  end
end