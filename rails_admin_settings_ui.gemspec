require_relative "lib/rails_admin_settings_ui/version"

Gem::Specification.new do |spec|
  spec.name          = "rails_admin_settings_ui"
  spec.version       = RailsAdminSettingsUi::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "User-friendly settings interface for Rails Admin with rails-settings-cached"
  spec.description   = "Provides a clean, intuitive UI for managing application settings in Rails Admin, integrating seamlessly with rails-settings-cached gem"
  spec.homepage      = "https://github.com/yourusername/rails_admin_settings_ui"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "rails_admin", ">= 2.0"
  spec.add_dependency "rails-settings-cached", ">= 2.0"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
