# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    module PdfInjection
      def inject_custom_css(tab, custom_css, custom_css_url)
        return unless custom_css || custom_css_url

        if custom_css
          tab.inject_style(url: nil, content: custom_css, id: nil)
        end

        if custom_css_url
          tab.inject_style(url: custom_css_url, content: nil, id: nil)
        end
      end

      def inject_custom_js(tab, custom_js, custom_js_url)
        return unless custom_js || custom_js_url

        if custom_js
          tab.inject_script(url: nil, content: custom_js, id: nil)
        end

        if custom_js_url
          tab.inject_script(url: custom_js_url, content: nil, id: nil)
        end
      end
    end
  end
end
