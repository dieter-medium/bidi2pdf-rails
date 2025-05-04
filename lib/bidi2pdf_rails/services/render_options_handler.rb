# frozen_string_literal: true

require_relative "pdf_options"
require_relative "print_url_options"
require_relative "html_options"

module Bidi2pdfRails
  module Services
    class RenderOptionsHandler
      PDF_OPTIONS = PdfRenderer::PDF_OPTIONS
      PRINT_URL_OPTIONS = PdfRenderer::PRINT_URL_OPTIONS

      attr_reader :pdf, :url, :html

      def initialize(filename, options, controller, bidi2pdf_rails_config: Bidi2pdfRails.config)
        pdf_opts = options.slice(*PDF_OPTIONS)
        print_url_opts = options.slice(*PRINT_URL_OPTIONS)
        html_opts = options.except(*PDF_OPTIONS + PRINT_URL_OPTIONS)

        @pdf = PdfOptions.new(filename, pdf_opts, controller, bidi2pdf_rails_config:)
        @url = PrintUrlOptions.new(print_url_opts, controller, bidi2pdf_rails_config:)
        @html = HtmlOptions.new(html_opts, @pdf, controller)
      end
    end
  end
end
