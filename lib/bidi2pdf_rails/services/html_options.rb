# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    class HtmlOptions
      attr_reader :html_options, :pdf_options, :controller

      def initialize(html_options, pdf_options, controller)
        @html_options = html_options
        @pdf_options = pdf_options
        @controller = controller
      end

      def asset_host
        html_options.fetch(:asset_host) { |_key| pdf_options.asset_host }
      end

      def html
        html_options.fetch(:inline) { |_key| HtmlRenderer.new(controller, html_options.merge({ asset_host: asset_host })).render }
      end
    end
  end
end
