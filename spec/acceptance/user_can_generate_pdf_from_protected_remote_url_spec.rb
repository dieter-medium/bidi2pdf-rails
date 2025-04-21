# frozen_string_literal: true

require "rails_helper"
require "net/http"
require "rack/handler/puma"
require "socket"
require "base64"

RSpec.feature "As a user, I want to generate a PDF from a protected remote URL", :pdf, type: :request do
  before(:all) do
    # Bidi2pdfRails.config.general_options.headless = false
    Bidi2pdfRails::ChromedriverManagerSingleton.initialize_manager force: true
  end

  after(:all) do
    Bidi2pdfRails::ChromedriverManagerSingleton.shutdown
  end

  scenario "Using basic auth for remote PDF rendering" do
    # Controller setup:
    #
    # You can configure basic auth in two ways:
    #
    # 1. In an initializer (global config):
    #
    #   Bidi2pdfRails.configure do |config|
    #     config.render_remote_settings.basic_auth_user = ->(_controller) { "admin" }
    #     config.render_remote_settings.basic_auth_pass = ->(_controller) { "secret" }
    #   end
    #
    # 2. Inline within controller action:
    #
    #   render pdf: 'convert-remote-url-basic-auth',
    #          url: basic_auth_endpoint_url(only_path: false),
    #          auth: { username: "admin", password: "secret" }

    when_ "I request a PDF generated from a basic-auth protected page" do
      before do
        with_render_setting :basic_auth_user, ->(_controller) { "admin" }
        # in prod better to use:
        # Bidi2pdfRails.config.render_remote_settings.basic_auth_pass = ->(_controller) { Rails.application.credentials.dig('bidi2pdf_rails', 'basic_auth_pass') }
        with_render_setting :basic_auth_pass, ->(_controller) { "secret" }

        @response = get_pdf_response "/convert-remote-url-basic-auth"
      end

      then_ "I receive a successful HTTP response" do
        expect(@response.code).to eq("200")
      end

      and_ "I receive a PDF file in response" do
        expect(@response['Content-Type']).to eq("application/pdf")
      end

      and_ "the PDF contains the expected number of pages" do
        expect(@response.body).to have_pdf_page_count(1)
      end

      and_ "the disposition header is set to attachment" do
        expect(@response['Content-Disposition']).to start_with('inline; filename="convert-remote-url-basic-auth.pdf"')
      end

      and_ "the PDF contains the expected content" do
        expect(@response.body).to contains_pdf_text("This page is secured with: HTTPBasicAuthentication").at_page(1)
      end
    end
  end

  scenario "Using a session cookie for remote PDF rendering" do
    # Controller setup:
    #
    # You can configure cookies in two ways:
    #
    # 1. In an initializer (global config):
    #
    #   Bidi2pdfRails.configure do |config|
    #     config.render_remote_settings.cookies = = ->(controller) { { "auth_token" => signed_cookie_value("valid-authentication-token", controller) } }
    #   end
    #
    # 2. Inline within controller action:
    #
    #     render pdf: 'convert-remote-url-cookie',
    #            url: cookie_endpoint_url(only_path: false),
    #            wait_for_page_loaded: false,
    #            cookies: { "auth_token" => signed_cookie_value("valid-authentication-token", controller) }
    #

    when_ "I request a PDF from a page that requires a session cookie" do
      def signed_cookie_value(value, controller)
        request = controller.request
        secret = request.key_generator.generate_key(request.signed_cookie_salt)
        # Sign the value
        verifier = ActiveSupport::MessageVerifier.new(secret)
        verifier.generate(value)
      end

      before do
        with_render_setting :cookies, ->(controller) { { "auth_token" => signed_cookie_value("valid-authentication-token", controller) } }

        @response = get_pdf_response "/convert-remote-url-cookie"
      end

      then_ "I receive a successful HTTP response" do
        expect(@response.code).to eq("200")
      end

      and_ "I receive a PDF file in response" do
        expect(@response['Content-Type']).to eq("application/pdf")
      end

      and_ "the PDF contains the expected number of pages" do
        expect(@response.body).to have_pdf_page_count(1)
      end

      and_ "the disposition header is set to attachment" do
        expect(@response['Content-Disposition']).to start_with('inline; filename="convert-remote-url-cookie.pdf"')
      end

      and_ "the PDF contains the expected content" do
        expect(@response.body).to contains_pdf_text("Protected Resource This page is secured with: CookieAuthentication").at_page(1)
      end
    end
  end

  scenario "Using custom headers for remote PDF rendering" do
    # Controller setup:
    #
    # You can configure headers in two ways:
    #
    # 1. In an initializer (global config):
    #
    #   Bidi2pdfRails.configure do |config|
    #    config.render_remote_settings.headers = ->(controller) { { "X-API-Key" => "your-secret-api-key" } }
    #   end
    #
    # 2. Inline within controller action:
    #
    #     render pdf: 'convert-remote-url-cookie',
    #            url: api_endpoint_url(only_path: false),
    #            wait_for_page_loaded: false,
    #            headers: { "X-API-Key" => "your-secret-api-key" }
    #

    when_ "I request a PDF from a page that requires an auth header" do
      before do
        @old_headers = Bidi2pdfRails.config.render_remote_settings.headers
        with_render_setting :headers, ->(_controller) { { "X-API-Key" => "your-secret-api-key" } }

        @response = get_pdf_response "/convert-remote-url-header"
      end

      then_ "I receive a successful HTTP response" do
        expect(@response.code).to eq("200")
      end

      and_ "I receive a PDF file in response" do
        expect(@response['Content-Type']).to eq("application/pdf")
      end

      and_ "the PDF contains the expected number of pages" do
        expect(@response.body).to have_pdf_page_count(1)
      end

      and_ "the disposition header is set to attachment" do
        expect(@response['Content-Disposition']).to start_with('inline; filename="convert-remote-url-cookie.pdf"')
      end

      and_ "the PDF contains the expected content" do
        expect(@response.body).to contains_pdf_text("Protected Resource This page is secured with: API KeyAuthentication").at_page(1)
      end
    end
  end
end
