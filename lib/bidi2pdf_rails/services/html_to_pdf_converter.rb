# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    class HtmlToPdfConverter
      include PdfBrowserSession
      include PdfInjection
      include Callbacks

      def initialize(html, print_options: {}, wait_for_network_idle: true, wait_for_page_loaded: true, wait_for_page_check_script: nil, custom_css: nil, custom_css_url: nil, custom_js: nil, custom_js_url: nil, callbacks: nil)
        @html = html
        @print_options = print_options
        @wait_for_network_idle = wait_for_network_idle
        @wait_for_page_loaded = wait_for_page_loaded
        @wait_for_page_check_script = wait_for_page_check_script
        @custom_css = custom_css
        @custom_css_url = custom_css_url
        @custom_js = custom_js
        @custom_js_url = custom_js_url
        @callbacks = callbacks || {}
      end

      def generate
        run_browser_session
      end

      private

      def notify_after_print(tab, binary_pdf_content)
        after_print(@html, tab, binary_pdf_content)
      end

      def prepare_tab(tab)
        before_navigate(@html, tab)

        with_interlock_warning { tab.render_html_content(@html) }

        after_navigate(@html, tab)

        inject_custom_css(tab, @custom_css, @custom_css_url)
        inject_custom_js(tab, @custom_js, @custom_js_url)

        wait_for_tab(tab)

        after_wait_for_tab(@html, tab)
      end
    end
  end
end
