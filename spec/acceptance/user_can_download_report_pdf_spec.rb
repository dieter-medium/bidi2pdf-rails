# frozen_string_literal: true

require "rails_helper"
require "net/http"
require "rack/handler/puma"
require "socket"

RSpec.feature "As a devoloper, I want to generate PDF's with bidi2pdf-rails", :pdf, type: :request do
  # This feature demonstrates how to use bidi2pdf-rails to generate PDFs
  # from Rails views, remote URLs, and inline HTML. These specs double as
  # living documentation for gem users.

  before(:all) do
    # Prepare the PDF rendering engine (chromium, etc.)
    Bidi2pdfRails::ChromedriverManagerSingleton.initialize_manager force: true
  end

  after(:all) do
    Bidi2pdfRails::ChromedriverManagerSingleton.shutdown
  end

  scenario "Rendering a controller view to PDF using layout: 'pdf'" do
    # Controller example:
    #
    # def show
    #   respond_to do |format|
    #     format.html
    #     format.pdf { render pdf: 'my-report', layout: 'pdf' }
    #   end
    # end

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

      and_ "the disposition header is set to attachment" do
        expect(@response['Content-Disposition']).to start_with('inline; filename="my-report.pdf"')
      end

      and_ "the PDF contains the expected content" do
        expect(@response.body).to contains_pdf_text("Section Two").at_page(2)
      end
    end
  end

  scenario "Converting a remote URL into a PDF with custom options" do
    # Controller usage:
    #
    # def convert_remote_url
    #   render pdf: 'convert-remote-url', url: "http://example.com", wait_for_page_loaded: false, print_options: { page: { format: :A4 } }
    # end

    when_ "I visit the PDF version of a report" do
      before do
        @response = get_pdf_response "/convert-remote-url.pdf"
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
        expect(@response['Content-Disposition']).to start_with('inline; filename="convert-remote-url.pdf"')
      end
    end
  end

  scenario "Rendering inline HTML directly to PDF" do
    # Controller usage:
    #
    # def inline_html
    #   html = <<~HTML
    #   <html>
    #   <head>
    #   </head>
    #   <body>
    #    <h1>PDF Rendering Sample</h1>
    #     <p style="page-break-after: always;">Page break</p>
    #     <p>Content Page 2</p>
    #   </body>
    #  </html>
    #
    #   render pdf: 'inline-html', inline: html, wait_for_page_loaded: false, print_options: { page: { format: :A4 } }
    # end

    when_ "I visit the PDF version of a report" do
      before do
        @response = get_pdf_response "/inline-html.pdf"
      end

      then_ "I receive a successful HTTP response" do
        expect(@response.code).to eq("200")
      end

      and_ "I receive a PDF file in response" do
        expect(@response['Content-Type']).to eq("application/pdf")
      end

      and_ "the PDF contains the expected number of pages" do
        expect(@response.body).to have_pdf_page_count(2)
      end

      and_ "the disposition header is set to attachment" do
        expect(@response['Content-Disposition']).to start_with('inline; filename="inline-html.pdf"')
      end

      and_ "the PDF contains the expected content" do
        expect(@response.body).to contains_pdf_text("PDF Rendering Sample")
      end
    end
  end
end
