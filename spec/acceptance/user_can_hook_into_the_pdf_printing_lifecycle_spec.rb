# frozen_string_literal: true

require "rails_helper"
require "net/http"
require "rack/handler/puma"
require "socket"
require "base64"

RSpec.feature "As a user, I want to hook into the PDF printing lifecycle", :pdf, type: :request do
  before(:all) do
    # Bidi2pdfRails.config.general_options.headless = false
    Bidi2pdfRails::ChromedriverManagerSingleton.initialize_manager force: true
  end

  after(:all) do
    Bidi2pdfRails::ChromedriverManagerSingleton.shutdown
  end

  scenario "Using the before navigate callback" do
    # Controller setup:
    #
    # You can configure before navigate callback in two ways:
    #
    # 1. In an initializer (global config):
    #
    #   Bidi2pdfRails.configure do |config|
    #     config.render_remote_settings.before_navigate = ->(url_or_content, browser_tab, filename, controller) { Rails.logger.info "Navigating to #{url_or_content}" }
    #   end
    #
    # 2. Inline within controller action:
    #
    #   render pdf: 'convert-remote-url',
    #          url: "http://example.com",
    #          callbacks: {
    #            before_navigate: ->(url_or_content, browser_tab, filename, controller) { Rails.logger.info "Navigating to #{url_or_content}" }
    #          },
    #          wait_for_page_loaded: false,
    #          print_options: { page: { format: :A4 } }
    #
    #
    when_ "I request a PDF and register a `before_navigate` hook" do
      before do
        with_lifecycle_settings :before_navigate, ->(url_or_content, browser_tab, filename, controller) { @url = url_or_content; @browser_tab = browser_tab; @filename = filename; @controller = controller }

        get_pdf_response "/convert-remote-url.pdf"
      end

      then_ "I receive a url" do
        expect(@url).to eq("http://example.com")
      end

      and_ "I receive a browser tab" do
        expect(@browser_tab).to be_a(Bidi2pdf::Bidi::BrowserTab)
      end

      and_ "I receive a filename" do
        expect(@filename).to eq("convert-remote-url")
      end

      and_ "I receive a controller" do
        expect(@controller).to be_a(ActionController::Base)
      end
    end
  end

  scenario "Using the after navigate callback" do
    # Controller setup:
    #
    # You can configure after navigate callback in two ways:
    #
    # 1. In an initializer (global config):
    #
    #   Bidi2pdfRails.configure do |config|
    #     config.render_remote_settings.after_navigate = ->(url_or_content, browser_tab, filename, controller) { Rails.logger.info "Navigated to #{url_or_content}" }
    #   end
    #
    # 2. Inline within controller action:
    #
    #   render pdf: 'convert-remote-url',
    #          url: "http://example.com",
    #          callbacks: {
    #            after_navigate: ->(url_or_content, browser_tab, filename, controller) { Rails.logger.info "Navigated to #{url_or_content}" }
    #          },
    #          wait_for_page_loaded: false,
    #          print_options: { page: { format: :A4 } }
    #
    when_ "I request a PDF and register a `after_navigate` hook" do
      before do
        with_lifecycle_settings :after_navigate, ->(url_or_content, browser_tab, filename, controller) { @url = url_or_content; @browser_tab = browser_tab; @filename = filename; @controller = controller }

        get_pdf_response "/convert-remote-url.pdf"
      end

      then_ "I receive a url" do
        expect(@url).to eq("http://example.com")
      end

      and_ "I receive a browser tab" do
        expect(@browser_tab).to be_a(Bidi2pdf::Bidi::BrowserTab)
      end

      and_ "I receive a filename" do
        expect(@filename).to eq("convert-remote-url")
      end

      and_ "I receive a controller" do
        expect(@controller).to be_a(ActionController::Base)
      end
    end
  end

  scenario "Using the after print callback" do
    # With the `after_print` callback, you can perform actions after the PDF has been printed/generated.
    # This is useful for tasks like logging, saving the PDF to a specific location, or modifying the PDF content.
    # For example, you can add a watermark, sign the PDF, or store it in a database.
    # Because of the modification of the PDF content, you need to return the binary content of the PDF.
    #
    # Controller setup:
    #
    # You can configure after print callback in two ways:
    #
    # 1. In an initializer (global config):
    #
    #   Bidi2pdfRails.configure do |config|
    #     config.render_remote_settings.after_print = ->(url_or_content, browser_tab, binary_pdf_content, filename, controller) { Rails.logger.info "Printed #{url_or_content}"; binary_pdf_content }
    #   end
    #
    # 2. Inline within controller action:
    #
    #   render pdf: 'convert-remote-url',
    #          url: "http://example.com",
    #          callbacks: {
    #            after_print: ->(url_or_content, browser_tab, binary_pdf_content, filename, controller) { Rails.logger.info "Printed #{url_or_content}"; binary_pdf_content }
    #          },
    #          wait_for_page_loaded: false,
    #          print_options: { page: { format: :A4 } }
    #
    when_ "I request a PDF and register a `after_print` hook" do
      before do
        with_lifecycle_settings :after_print, ->(url_or_content, browser_tab, binary_pdf_content, filename, controller) { @url = url_or_content; @browser_tab = browser_tab; @binary_pdf_content = binary_pdf_content; @filename = filename; @controller = controller; binary_pdf_content }

        get_pdf_response "/convert-remote-url.pdf"
      end

      then_ "I receive a url" do
        expect(@url).to eq("http://example.com")
      end

      and_ "I receive a browser tab" do
        expect(@browser_tab).to be_a(Bidi2pdf::Bidi::BrowserTab)
      end

      and_ "I receive a binary pdf content" do
        expect(@binary_pdf_content).to be_a(String)
      end

      and_ "I receive a filename" do
        expect(@filename).to eq("convert-remote-url")
      end

      and_ "I receive a controller" do
        expect(@controller).to be_a(ActionController::Base)
      end
    end
  end
end
