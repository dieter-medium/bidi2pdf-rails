# frozen_string_literal: true

require "rails_helper"
require "net/http"
require "rack/handler/puma"
require "socket"

# Rails-level coverage for the Bidi2pdf::SessionWarmer adapter itself (chromedriver_manager_singleton.rb,
# pdf_browser_session.rb#run_with_session_warmer). Deliberately NOT re-testing the warmer's own
# concurrency/cleanup internals - Bidi2pdf::SessionWarmer's own spec/unit/bidi2pdf/session_warmer_spec.rb
# (57 examples) owns that; this spec only proves the two are wired together correctly.
RSpec.feature "As a developer, I want to render PDFs from a pool of pre-warmed Chrome sessions", :pdf, type: :request do
  before(:all) do
    Bidi2pdfRails.config.session_warmer_settings.enabled = true
    Bidi2pdfRails.config.session_warmer_settings.size = 1

    Bidi2pdfRails::ChromedriverManagerSingleton.initialize_manager force: true
  end

  after(:all) do
    Bidi2pdfRails::ChromedriverManagerSingleton.shutdown

    Bidi2pdfRails.config.session_warmer_settings.enabled = false
    Bidi2pdfRails.config.session_warmer_settings.size = 1
  end

  scenario "Rendering a controller view to PDF with the session warmer enabled" do
    when_ "I visit the PDF version of a report" do
      before do
        @response = get_pdf_response "/reports/1.pdf"
      end

      then_ "I receive a successful HTTP response" do
        expect(@response.code).to eq("200")
      end

      and_ "I receive a PDF file in response" do
        expect(@response['Content-Type']).to eq("application/pdf")
      end

      and_ "the PDF contains the expected number of pages" do
        expect(@response.body).to have_pdf_page_count(5)
      end
    end

    # Proves single-use slot retirement plus background replenishment actually work end-to-end
    # under Rails, not just that the first render (which could be a synchronous cold fallback) works.
    when_ "I render a second PDF right after the first" do
      before do
        get_pdf_response "/reports/1.pdf"
        @second_response = get_pdf_response "/reports/1.pdf"
      end

      then_ "the second render also succeeds" do
        expect(@second_response.code).to eq("200")
      end

      and_ "the second render also produces a real PDF" do
        expect(@second_response.body).to have_pdf_page_count(5)
      end
    end
  end
end
