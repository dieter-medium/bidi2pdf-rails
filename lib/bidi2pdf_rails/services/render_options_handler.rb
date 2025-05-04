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
        @original_options = options.deep_dup # Store original options

        pdf_opts = options.slice(*PDF_OPTIONS)
        print_url_opts = options.slice(*PRINT_URL_OPTIONS)
        html_opts = options.except(*PDF_OPTIONS + PRINT_URL_OPTIONS)

        @pdf = PdfOptions.new(filename, pdf_opts, controller, bidi2pdf_rails_config:)
        @url = PrintUrlOptions.new(print_url_opts, controller, bidi2pdf_rails_config:)
        @html = HtmlOptions.new(html_opts, @pdf, controller)
      end

      def inline_rendering_needed?
        !(@url.url? || @original_options[:inline])
      end

      # Call this method to render the HTML inline, within the controller, in cases where you want to render
      # within the current controller context.
      def render_inline!
        return unless inline_rendering_needed?

        @original_options[:inline] = html.html
      end

      def job_options
        @original_options
      end
    end
  end
end
