# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    class UrlToPdfConverter
      include PdfBrowserSession
      include PdfInjection
      include Callbacks

      def initialize(url, headers: {}, cookies: {}, auth: {}, print_options: {}, wait_for_network_idle: true, wait_for_page_loaded: true, wait_for_page_check_script: nil, custom_css: nil, custom_css_url: nil, custom_js: nil, custom_js_url: nil, callbacks: nil)
        @url = url
        @headers = headers || {}
        @cookies = cookies || {}
        @auth = auth || {}
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
        after_print(@url, tab, binary_pdf_content)
      end

      def prepare_tab(tab)
        add_headers(tab)
        add_basic_auth(tab)
        add_cookies(tab)

        before_navigate(@url, tab)

        tab.navigate_to(@url)

        after_navigate(@url, tab)

        inject_custom_css(tab, @custom_css, @custom_css_url)
        inject_custom_js(tab, @custom_js, @custom_js_url)

        wait_for_tab(tab)

        after_wait_for_tab(@url, tab)
      end

      def add_cookies(tab)
        @cookies.each do |name, value|
          tab.set_cookie(
            name: name,
            value: value,
            domain: domain,
            secure: uri.scheme == "https"
          )
        end
      end

      def add_headers(tab)
        @headers.each do |name, value|
          tab.add_headers(
            url_patterns: url_patterns,
            headers: [{ name: name, value: value }]
          )
        end
      end

      def add_basic_auth(tab)
        return unless @auth[:username] && @auth[:password]

        tab.basic_auth(
          url_patterns: url_patterns,
          username: @auth[:username],
          password: @auth[:password]
        )
      end

      def uri
        @uri ||= URI(@url)
      end

      def domain
        uri.host
      end

      def url_patterns
        [{
           type: "pattern",
           protocol: uri.scheme,
           hostname: uri.host,
           port: uri.port.to_s
         }]
      end
    end
  end
end
