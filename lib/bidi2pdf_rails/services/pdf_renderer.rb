# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    # PdfRenderer is responsible for rendering a Rails view into a PDF using headless Chrome.
    #
    # It accepts a mix of HTML rendering options (passed to `render_to_string`) and PDF generation options.
    #
    # @example Basic usage
    #   renderer = Bidi2pdfRails::Services::PdfRenderer.new("invoice", { template: "invoices/show" }, controller)
    #   renderer.render_pdf
    #
    # @param filename [String] the base filename for the generated PDF (used for download naming)
    # @param options [Hash] rendering options including both HTML and PDF-specific options
    # @option options [String] :template The template to render (or other render_to_string keys like :partial, :layout, etc.)
    # @option options [String] :asset_host Optional asset host override
    # @option options [Hash] :print_options Options passed to the Chrome PDF print API
    # @option options [Boolean] :wait_for_network_idle Wait for network to go idle before generating PDF (default: config default)
    # @option options [Boolean] :wait_for_page_loaded Wait for page load event before generating PDF (default: config default)
    # @option options [String] :wait_for_page_check_script JavaScript condition to wait for before generating PDF
    #
    class PdfRenderer
      PDF_OPTIONS = %i[
        print_options
        asset_host
        wait_for_network_idle
        wait_for_page_loaded
        wait_for_page_check_script
        html
      ].freeze

      PRINT_URL_OPTIONS = %i[
        url
        auth
        headers
        cookies
      ].freeze

      def initialize(filename, options, controller)
        @filename = filename
        @pdf_options = options.slice(*PDF_OPTIONS)
        @print_url_options = options.slice(*PRINT_URL_OPTIONS)
        @html_options = options.except(*(PDF_OPTIONS + PRINT_URL_OPTIONS))
        @controller = controller
      end

      def render_pdf
        ActiveSupport::Notifications.instrument("handle_printing.bidi2pdf_rails") do
          print_options = Bidi2pdfRails.config.pdf_settings_for_bidi_cmd(@pdf_options[:print_options] || {})
          wait_for_network_idle = @pdf_options.fetch(:wait_for_network_idle, Bidi2pdfRails.config.general_options.wait_for_network_idle_value)
          wait_for_page_loaded = @pdf_options.fetch(:wait_for_page_loaded, Bidi2pdfRails.config.general_options.wait_for_page_loaded_value)
          wait_for_page_check_script = @pdf_options.fetch(:wait_for_page_check_script, Bidi2pdfRails.config.general_options.wait_for_page_check_script_value)

          if @print_url_options[:url]
            headers = @print_url_options[:headers] || Bidi2pdfRails.config.render_remote_settings.headers_value
            cookies = @print_url_options[:cookies] || Bidi2pdfRails.config.render_remote_settings.cookies_value
            auth = @print_url_options[:auth] || { username: Bidi2pdfRails.config.render_remote_settings.basic_auth_user_value, password: Bidi2pdfRails.config.render_remote_settings.basic_auth_pass_value }

            UrlToPdfConverter.new(@print_url_options[:url],
                                  headers: headers,
                                  cookies: cookies,
                                  auth: auth,
                                  print_options: print_options,
                                  wait_for_network_idle: wait_for_network_idle,
                                  wait_for_page_loaded: wait_for_page_loaded,
                                  wait_for_page_check_script: wait_for_page_check_script
            ).generate
          else
            html = @html_options.fetch(:html, HtmlRenderer.new(@controller, @html_options).render)

            HtmlToPdfConverter.new(html,
                                   print_options: print_options,
                                   wait_for_network_idle: wait_for_network_idle,
                                   wait_for_page_loaded: wait_for_page_loaded,
                                   wait_for_page_check_script: wait_for_page_check_script
            ).generate
          end
        end
      end
    end
  end
end
