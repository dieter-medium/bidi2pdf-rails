# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    class PrintUrlOptions
      attr_reader :print_url_options, :controller, :bidi2pdf_rails_config

      def initialize(print_url_options, controller, bidi2pdf_rails_config: Bidi2pdfRails.config)
        @print_url_options = print_url_options
        @controller = controller
        @bidi2pdf_rails_config = bidi2pdf_rails_config
      end

      def url
        print_url_options[:url]
      end

      def url?
        print_url_options.key?(:url)
      end

      def headers
        print_url_options.fetch(:headers) { |_key| bidi2pdf_rails_config.render_remote_settings.headers_value(controller) }
      end

      def cookies
        print_url_options.fetch(:cookies) { |_key| bidi2pdf_rails_config.render_remote_settings.cookies_value(controller) }
      end

      def auth
        print_url_options.fetch(:auth) do |_key|
          {
            username: bidi2pdf_rails_config.render_remote_settings.basic_auth_user_value(controller),
            password: bidi2pdf_rails_config.render_remote_settings.basic_auth_pass_value(controller)
          }
        end
      end
    end
  end
end
