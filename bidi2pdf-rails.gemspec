require_relative "lib/bidi2pdf_rails/version"

Gem::Specification.new do |spec|
  spec.name = "bidi2pdf-rails"
  spec.version = Bidi2pdfRails::VERSION
  spec.authors = ["Dieter S."]
  spec.email = ["101627195+dieter-medium@users.noreply.github.com"]

  spec.summary = "Rails integration for PDF generation using Chrome/Chromium headless browser"
  spec.description = <<~DESC
    Bidi2pdf Rails provides a seamless integration between Rails and the Bidi2pdf gem for#{' '}
    generating high-quality PDFs using Chrome/Chromium's headless browser. It supports#{' '}
    rendering PDFs from controller actions, remote URLs, or HTML strings with configurable#{' '}
    options for orientation, margins, page size, and more. The gem handles browser lifecycle#{' '}
    management and provides a clean API for PDF generation with proper asset handling.
  DESC

  spec.homepage = "https://github.com/dieter-medium/bidi2pdf-rails"
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

  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.2.2.1", "< 8.0.3.0"
  spec.add_dependency "bidi2pdf", ">= 0.1.9"

  spec.add_development_dependency "rubocop-rake", "~> 0.7"
  spec.add_development_dependency "rubocop-rspec", "~> 3.5"
  spec.add_development_dependency "rspec-rails", "~> 8.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "puma"
  spec.add_development_dependency "websocket-native", "~> 1.0"
  spec.add_development_dependency "pdf-reader", "~> 2.14"
  spec.add_development_dependency "unicode_utils", "~> 1.4"
  spec.add_development_dependency "testcontainers", "~> 0.2"
end
