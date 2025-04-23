# frozen_string_literal: true

require "rails_helper"
require "bidi2pdf/test_helpers/testcontainers"

RSpec.feature "As a developer, I want to generate PDF's with bidi2pdf-rails, using an external chromedriver", :chromedriver, :pdf, type: :request do
  before do
    with_render_setting :browser_url, session_url
    Bidi2pdfRails::ChromedriverManagerSingleton.initialize_manager force: true
  end

  after do
    Bidi2pdfRails::ChromedriverManagerSingleton.shutdown
  end

  # Using Remote Chromedriver with Bidi2pdfRails
  #
  # 1. Configuration in initializer:
  #
  #    Bidi2pdfRails.configure do |config|
  #      # Set the URL for remote Chrome session
  #      config.render_remote_settings.browser_url = "http://localhost:3001/session"
  #
  #      # Important settings
  #      config.general_options.headless = true
  #      config.general_options.default_timeout = 30 # Increase timeout for network latency (if needed)
  #    end
  #
  #    # In config/environments/*.rb (when set):
  #    config.x.bidi2pdf_rails.headless = true
  #
  # 2. Running a remote Chromedriver:
  #
  #    # Docker (recommended):
  #    docker run -d -p 3001:3000 dieters877565/chromedriver:latest
  #
  #    # Important: Network considerations
  #    # - Chrome container must be able to reach your Rails app
  #    # - Use host IP instead of localhost when starting Rails
  #    # - If using Docker compose, configure proper networking
  #
  # 3. OSX Firewall Configuration:
  #    # If using RVM and macOS firewall is active:
  #    RUBY_BIN="$(rvm which ruby)"
  #    sudo codesign --force --sign - $RUBY_BIN
  #    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add "$RUBY_BIN"
  #    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp "$RUBY_BIN"
  #
  # 4. Starting Rails server with correct host binding:
  #    ./bin/rails s -b $(ipconfig getifaddr en0) # Use your network interface
  #
  # 5. Debugging tips:
  #    - Check network connectivity between containers/services
  #    - Monitor Chrome logs with: Bidi2pdfRails::BrowserConsoleLogSubscriber.attach_to "bidi2pdf"
  #    - Increase verbosity: config.general_options.verbosity = :high
  scenario "Rendering a PDF using a remote/docker Chromedriver" do
    when_ "I visit the PDF version of a report" do
      before do
        @response = get_pdf_response "/convert-remote-url"
      end

      then_ "I receive a successful HTTP response" do
        expect(@response.code).to eq("200")
      end

      and_ "I receive a PDF file in response" do
        expect(@response['Content-Type']).to eq("application/pdf")
      end

      and_ "the PDF contains the expected number of pages" do
        expected_page_count = 1
        expect(@response.body).to have_pdf_page_count(expected_page_count)
      end

      and_ "the disposition header is set to attachment" do
        expect(@response['Content-Disposition']).to start_with('inline; filename="convert-remote-url.pdf"')
      end

      and_ "the PDF contains the expected content" do
        expect(@response.body).to contains_pdf_text("Example Domain This domain is for use in illustrative examples in documents").at_page(1)
      end
    end
  end
end
