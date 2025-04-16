require_relative "lib/bidi2pdf_rails/version"

Gem::Specification.new do |spec|
  spec.name        = "bidi2pdf-rails"
  spec.version     = Bidi2pdfRails::VERSION
  spec.authors = [ "Dieter S." ]
  spec.email = [ "101627195+dieter-medium@users.noreply.github.com" ]

  spec.summary = "A Ruby gem that generates PDF"
  # rubocop:enable Layout/LineLength
  spec.description = <<~DESC
    Bidi2pdf Rails is a powerful PDF generation tool.
  DESC
  spec.homepage = "https://github.com/dieter-medium/bidi2pdf"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)

  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.test_files = Dir["spec/**/*"]

  spec.require_paths = [ "lib" ]

  spec.add_dependency "rails", ">= 7.2.2.1", "< 8.0.3.0"
  spec.add_dependency "bidi2pdf"

  spec.add_development_dependency "rubocop-rake", "~> 0.7"
  spec.add_development_dependency "rubocop-rspec", "~> 3.5"
  spec.add_development_dependency "rspec-rails", "~> 7.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "puma"
end
