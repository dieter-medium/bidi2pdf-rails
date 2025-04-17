# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    # app/services/html_renderer.rb
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
        original_asset_host = ActionController::Base.asset_host

        if @options[:asset_host]
          ActionController::Base.asset_host = @options[:asset_host]
        elsif !Rails.application.config.action_controller.asset_host
          ActionController::Base.asset_host = @controller.request.base_url
        end

        yield
      ensure
        ActionController::Base.asset_host = original_asset_host
      end
    end
  end
end
