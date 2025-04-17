# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    module PdfBrowserSession
      def run_browser_session
        pdf_data = nil

        thread = Thread.new do
          Rails.application.executor.wrap do
            browser = ChromedriverManagerSingleton.session.browser
            context = browser.create_user_context
            window = context.create_browser_window
            tab = window.create_browser_tab

            begin
              prepare_tab(tab)
              pdf_data = tab.print(print_options: @print_options)
            ensure
              tab&.close
              window&.close
              context&.close
            end
          end
        end

        thread.join
        Base64.decode64(pdf_data)
      end

      private

      def wait_for_tab(tab)
        tab.wait_until_network_idle if @wait_for_network_idle
        tab.wait_until_page_loaded(check_script: @wait_for_page_check_script) if @wait_for_page_loaded
      end
    end
  end
end
