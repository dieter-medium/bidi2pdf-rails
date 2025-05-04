class AsyncReportJob < ApplicationJob
  queue_as :default

  def perform(render_option_handler, report_id)
    pdf_content = Bidi2pdfRails::Services::PdfRenderer.new(render_option_handler).render_pdf

    report = ReportResult.new(
      report_id: report_id,
    )

    report.pdf.attach(
      io: StringIO.new(pdf_content),
      filename: "#{render_option_handler.pdf.filename}.pdf",
      content_type: "application/pdf",
      identify: false
    )

    report.save!
  end
end
