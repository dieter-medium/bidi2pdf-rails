# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    module Callbacks
      def before_navigate(url_or_content, browser_tab)
        @callbacks[:before_navigate]&.call(url_or_content, browser_tab)
      end

      def after_navigate(url_or_content, browser_tab)
        @callbacks[:after_navigate]&.call(url_or_content, browser_tab)
      end

      def after_wait_for_tab(url_or_content, browser_tab)
        @callbacks[:after_wait_for_tab]&.call(url_or_content, browser_tab)
      end

      def after_print(url_or_content, browser_tab, binary_pdf_content)
        return binary_pdf_content unless @callbacks[:after_print] # important to return the binary content if no callback is provided

        @callbacks[:after_print].call(url_or_content, browser_tab, binary_pdf_content)
      end
    end
  end
end
