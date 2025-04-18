# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    class UrlToPdfConverter
      include PdfBrowserSession

      def initialize(url, headers: {}, cookies: {}, auth: {}, print_options: {}, wait_for_network_idle: true, wait_for_page_loaded: true, wait_for_page_check_script: nil)
        @url = url
        @headers = headers || {}
        @cookies = cookies || {}
        @auth = auth || {}
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
        add_headers(tab)
        add_basic_auth(tab)
        add_cookies(tab)

        tab.navigate_to(@url)
        wait_for_tab(tab)
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
