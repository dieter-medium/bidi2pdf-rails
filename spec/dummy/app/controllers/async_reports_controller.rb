class AsyncReportsController < ApplicationController
  def create
    options = { layout: 'pdf' }
    filename = 'my-report'
    handler = Bidi2pdfRails::Services::RenderOptionsHandler.new(filename, options, self)
    report_id = SecureRandom.uuid

    handler.render_inline! if handler.inline_rendering_needed?

    AsyncReportJob.perform_later(handler, report_id)

    redirect_to gen_async_report_status_path(report_id)
  end

  def status
    @report_id = params[:id]
    respond_to do |format|
      format.html { render layout: "simple" }
      format.json {
        result = ReportResult.find_by(report_id: @report_id)
        if result&.pdf&.attached?
          render json: { status: 'ready', url: url_for(result.pdf) }
        else
          render json: { status: 'processing' }
        end
      }
    end
  end
end
