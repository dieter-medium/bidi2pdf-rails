# frozen_string_literal: true

require "rails_helper"

RSpec.feature "As a user, I want to generate PDF reports asynchronously", :pdf, type: :request do
  include ActiveJob::TestHelper

  before do
    ReportResult.destroy_all
    Bidi2pdfRails::ChromedriverManagerSingleton.initialize_manager force: true
  end

  after do
    Bidi2pdfRails::ChromedriverManagerSingleton.shutdown
  end

  # Asynchronous PDF Generation with Bidi2pdfRails
  #
  # 1. Overview:
  #    This feature allows generating PDFs in the background using ActiveJob,
  #    which is useful for large reports that would timeout in a regular request.
  #
  # 2. Controller implementation:
  #    ```ruby
  #    def create
  #      options = { layout: 'pdf' }
  #      filename = 'my-report'
  #      handler = Bidi2pdfRails::Services::RenderOptionsHandler.new(filename, options, self)
  #      report_id = SecureRandom.uuid
  #
  #      # Required step: render HTML content in the controller context
  #      handler.render_inline! if handler.inline_rendering_needed?
  #
  #      # Enqueue background job with handler and unique report ID
  #      AsyncReportJob.perform_later(handler, report_id)
  #
  #      redirect_to status_path(report_id)
  #    end
  #    ```
  #
  #
  scenario "Requesting and retrieving an asynchronous PDF report" do
    when_ "I request an asynchronous PDF report" do
      before do
        @response = get_pdf_response gen_async_report_path
        # Store the report ID from the redirect URL
        @report_id = @response.header["Location"].split("/").last
      end

      then_ "I am redirected to the status page" do
        expect(@response.code).to eq("302")
      end

      and_ "the location header contains the report ID" do
        expect(@response["Location"]).to include("/async-report-status/#{@report_id}")
      end

      and_ "an AsyncReportJob is enqueued" do
        expect {
          get_pdf_response(gen_async_report_path)
        }.to have_enqueued_job(AsyncReportJob)
      end

      when_ "I check the report status after processing" do
        before do
          perform_enqueued_jobs

          @status_response = get_pdf_response gen_async_report_status_path(@report_id, format: :json)
          @status_data = JSON.parse(@status_response.body)
        end

        then_ "the status indicates the report is ready" do
          expect(@status_data).to include("status" => "ready", "url" => be_present)
        end

        when_ "I download the generated PDF" do
          before do
            @pdf_response = follow_redirects(get_pdf_response(@status_data["url"]))
          end

          then_ "I receive a PDF file" do
            expect(@pdf_response["Content-Type"]).to eq("application/pdf")
          end

          and_ "the PDF contains the expected content" do
            # Adjust the page count and content expectations as needed
            expect(@pdf_response.body).to have_pdf_page_count(1)
          end
        end
      end
    end
  end
end
