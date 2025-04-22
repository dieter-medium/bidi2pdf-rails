# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    class HtmlToPdfConverter
      include PdfBrowserSession
      include PdfInjection

      def initialize(html, print_options: {}, wait_for_network_idle: true, wait_for_page_loaded: true, wait_for_page_check_script: nil, custom_css: nil, custom_css_url: nil)
        @html = html
        @print_options = print_options
        @wait_for_network_idle = wait_for_network_idle
        @wait_for_page_loaded = wait_for_page_loaded
        @wait_for_page_check_script = wait_for_page_check_script
        @custom_css = custom_css
        @custom_css_url = custom_css_url
      end

      def generate
        run_browser_session
      end

      private

      def prepare_tab(tab)
        tab.render_html_content(@html)

        inject_custom_css(tab, @custom_css, @custom_css_url)

        wait_for_tab(tab)
      end
    end
  end
end
