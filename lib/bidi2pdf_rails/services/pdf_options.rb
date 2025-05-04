# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    class PdfOptions
      attr_reader :filename, :pdf_options, :controller, :bidi2pdf_rails_config

      def initialize(filename, pdf_options, controller, bidi2pdf_rails_config: Bidi2pdfRails.config)
        @filename = filename
        @pdf_options = pdf_options
        @controller = controller
        @bidi2pdf_rails_config = bidi2pdf_rails_config
      end

      def asset_host
        pdf_options.fetch(:asset_host, Bidi2pdfRails.config.pdf_settings.asset_host_value(controller))
      end

      def wait_for_network_idle
        pdf_options.fetch(:wait_for_network_idle, bidi2pdf_rails_config.general_options.wait_for_network_idle_value)
      end

      def wait_for_page_loaded
        pdf_options.fetch(:wait_for_page_loaded, bidi2pdf_rails_config.general_options.wait_for_page_loaded_value)
      end

      def wait_for_page_check_script
        pdf_options.fetch(:wait_for_page_check_script, bidi2pdf_rails_config.general_options.wait_for_page_check_script_value)
      end

      def print_options
        bidi2pdf_rails_config.pdf_settings_for_bidi_cmd(pdf_options[:print_options] || {})
      end

      def custom_css
        pdf_options.fetch(:custom_css, bidi2pdf_rails_config.pdf_settings.custom_css_value(controller))
      end

      def custom_css_url
        pdf_options.fetch(:custom_css_url, bidi2pdf_rails_config.pdf_settings.custom_css_url_value(controller))
      end

      def custom_js
        pdf_options.fetch(:custom_js, bidi2pdf_rails_config.pdf_settings.custom_js_value(controller))
      end

      def custom_js_url
        pdf_options.fetch(:custom_js_url, bidi2pdf_rails_config.pdf_settings.custom_js_url_value(controller))
      end

      def callbacks
        raw_callbacks = pdf_options.fetch(:callbacks, {})
        {
          before_navigate: wrap_callback(:before_navigate, raw_callbacks),
          after_navigate: wrap_callback(:after_navigate, raw_callbacks),
          after_wait_for_tab: wrap_callback(:after_wait_for_tab, raw_callbacks),
          after_print: wrap_callback(:after_print, raw_callbacks)
        }
      end

      private

      def wrap_callback(name, raw_callbacks)
        callback = raw_callbacks.fetch(name, bidi2pdf_rails_config.lifecycle_settings.send(name))
        return callback unless callback.is_a?(Proc)

        ->(*args) { callback.call(*args, filename, controller) }
      end
    end
  end
end
