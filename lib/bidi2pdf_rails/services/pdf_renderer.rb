# frozen_string_literal: true

require_relative "importmap_tags_helper_override"

module Bidi2pdfRails
  module Services
    # PdfRenderer is responsible for rendering a Rails view into a PDF using headless Chrome.
    #
    # It delegates option parsing and controller-aware defaults to an options handler object,
    # which splits responsibilities across HTML rendering, PDF configuration, and optional URL rendering.
    #
    # @example Basic usage
    #   options_handler = Bidi2pdfRails::Services::RenderOptionsHandler.new(options, controller)
    #   renderer = Bidi2pdfRails::Services::PdfRenderer.new(options_handler)
    #   renderer.render_pdf
    #
    # @param options_handler [RenderOptionsHandler] encapsulates all rendering options and controller context
    #   - html: HTML rendering settings (e.g., template, layout, asset host)
    #   - pdf:  PDF generation settings (e.g., print options, wait behavior, custom assets)
    #   - url:  Remote rendering settings (e.g., auth, headers, cookies, remote URL)
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

      attr_reader :options_handler

      def initialize(options_handler)
        @options_handler = options_handler
      end

      def render_pdf
        ActiveSupport::Notifications.instrument("handle_printing.bidi2pdf_rails") do
          if options_handler.url.url?
            headers = options_handler.url.headers
            cookies = options_handler.url.cookies
            auth = options_handler.url.auth

            UrlToPdfConverter.new(options_handler.url.url,
                                  headers: headers,
                                  cookies: cookies,
                                  auth: auth,
                                  print_options: options_handler.pdf.print_options,
                                  wait_for_network_idle: options_handler.pdf.wait_for_network_idle,
                                  wait_for_page_loaded: options_handler.pdf.wait_for_page_loaded,
                                  wait_for_page_check_script: options_handler.pdf.wait_for_page_check_script,
                                  custom_css: options_handler.pdf.custom_css,
                                  custom_css_url: options_handler.pdf.custom_css_url,
                                  custom_js: options_handler.pdf.custom_js,
                                  custom_js_url: options_handler.pdf.custom_js_url,
                                  callbacks: options_handler.pdf.callbacks
            ).generate
          else
            HtmlToPdfConverter.new(options_handler.html.html,
                                   print_options: options_handler.pdf.print_options,
                                   wait_for_network_idle: options_handler.pdf.wait_for_network_idle,
                                   wait_for_page_loaded: options_handler.pdf.wait_for_page_loaded,
                                   wait_for_page_check_script: options_handler.pdf.wait_for_page_check_script,
                                   custom_css: options_handler.pdf.custom_css,
                                   custom_css_url: options_handler.pdf.custom_css_url,
                                   custom_js: options_handler.pdf.custom_js,
                                   custom_js_url: options_handler.pdf.custom_js_url,
                                   callbacks: options_handler.pdf.callbacks
            ).generate
          end
        end
      end
    end
  end
end
