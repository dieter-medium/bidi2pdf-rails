# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    class HtmlRenderer
      def initialize(controller, options)
        @controller = controller
        @options = options.dup
      end

      def render
        with_overridden_asset_host { @controller.render_to_string(@options.merge(formats: [:html])) }
      end

      private

      def with_overridden_asset_host
        AssetHostManager.set_current_asset_host @options[:asset_host], @controller.request.base_url

        yield
      ensure
        Thread.current.bidi2pdf_rails_current_asset_host = nil
      end
    end
  end
end
