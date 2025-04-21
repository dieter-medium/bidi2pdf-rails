# frozen_string_literal: true

module PdfHelper
  def get_pdf_response(path)
    uri = URI("http://localhost:#{@port}#{path}")
    Net::HTTP.get_response(uri)
  end
end

RSpec.configure do |config|
  config.include PdfHelper, pdf: true
end
