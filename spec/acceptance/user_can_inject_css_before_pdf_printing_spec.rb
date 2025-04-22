# frozen_string_literal: true

require "rails_helper"
require "net/http"
require "rack/handler/puma"
require "socket"
require "base64"

RSpec.feature "As a user, I want to inject css into a website before printing a PDF", :pdf, type: :request do
  before(:all) do
    # Bidi2pdfRails.config.general_options.headless = false
    Bidi2pdfRails::ChromedriverManagerSingleton.initialize_manager force: true
  end

  after(:all) do
    Bidi2pdfRails::ChromedriverManagerSingleton.shutdown
  end

  scenario "Using raw CSS" do
    # Controller setup:
    #
    # You can configure basic auth in two ways:
    #
    # 1. In an initializer (global config):
    #
    #   Bidi2pdfRails.configure do |config|
    #     config.pdf_settings.custom_css = <<~CSS
    #       p {
    #         page-break-after: always;
    #       }
    #     CSS
    #   end
    #
    # 2. Inline within controller action:
    #   css = <<~CSS
    #     p {
    #       page-break-after: always;
    #     }
    #   CSS
    #   render pdf: 'inject-css-raw',
    #          custom_css: css,
    #          layout: 'simple',
    #          template: 'reports/simple',
    #          wait_for_page_loaded: false,
    #          print_options: { page: { format: :A4 } }
    #

    when_ "I request a PDF from a page and inject raw css" do
      before do
        with_pdf_settings :custom_css, <<-CSS
          p {
             page-break-after: always;
          }
        CSS

        @response = get_pdf_response "/inject/raw-css"
      end

      then_ "I receive a successful HTTP response" do
        expect(@response.code).to eq("200")
      end

      and_ "I receive a PDF file in response" do
        expect(@response['Content-Type']).to eq("application/pdf")
      end

      and_ "the PDF contains the expected number of pages" do
        expected_page_count = 6
        expect(@response.body).to have_pdf_page_count(expected_page_count)
      end

      and_ "the disposition header is set to attachment" do
        expect(@response['Content-Disposition']).to start_with('inline; filename="inject-raw-css.pdf"')
      end

      and_ 'the last page contains the expected content ("6")' do
        expect(@response.body).to contains_pdf_text("6").at_page(6)
      end
    end
  end

  scenario "Using an external stylesheet" do
    # Controller setup:
    #
    # You can configure cookies in two ways:
    #
    # 1. In an initializer (global config):
    #
    #   Bidi2pdfRails.configure do |config|
    #     config.pdf_settings.custom_css_url = ->(controller) { controller.view_context.asset_url 'stylesheets/simple.css' }
    #   end
    #
    # 2. Inline within controller action:
    #
    #   render pdf: 'inject-css-url',
    #          custom_css_url: view_context.asset_url('stylesheets/simple.css'),
    #          layout: 'simple',
    #          template: 'reports/simple',
    #          wait_for_page_loaded: false,
    #          print_options: { page: { format: :A4 } }
    #

    when_ "I request a PDF from a page and inject an external stylesheet" do
      before do
        with_pdf_settings :custom_css_url, ->(controller) { controller.view_context.asset_url 'stylesheets/simple.css' }

        @response = get_pdf_response "/inject/url-css"
      end

      then_ "I receive a successful HTTP response" do
        expect(@response.code).to eq("200")
      end

      and_ "I receive a PDF file in response" do
        expect(@response['Content-Type']).to eq("application/pdf")
      end

      and_ "the PDF contains the expected number of pages" do
        expected_page_count = 6
        expect(@response.body).to have_pdf_page_count(expected_page_count)
      end

      and_ "the disposition header is set to attachment" do
        expect(@response['Content-Disposition']).to start_with('inline; filename="inject-url-css.pdf"')
      end

      and_ 'the last page contains the expected content ("6")' do
        expect(@response.body).to contains_pdf_text(6).at_page(6)
      end
    end
  end
end
