# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    class HtmlToPdfConverter
      include PdfBrowserSession

      def initialize(html, print_options: {}, wait_for_network_idle: true, wait_for_page_loaded: true, wait_for_page_check_script: nil)
        @html = html
        @print_options = print_options
        @wait_for_network_idle = wait_for_network_idle
        @wait_for_page_loaded = wait_for_page_loaded
        @wait_for_page_check_script = wait_for_page_check_script
      end

      def generate
        run_browser_session
      end

      private

      def prepare_tab(tab)
        tab.render_html_content(@html)
        wait_for_tab(tab)
      end
    end
  end
end
