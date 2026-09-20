# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    module PdfBrowserSession
      def run_browser_session
        future = Concurrent::Promises.future do
          Rails.application.executor.wrap do
            if ChromedriverManagerSingleton.session_warmer_active?
              run_with_session_warmer
            else
              run_with_chromedriver_manager_singleton
            end
          end
        end

        future.value!
      end

      private

      # Bidi2pdf::SessionWarmer#with_tab already checks out, closes the tab/window/user_context, and
      # retires the underlying Chrome session on its own - nothing left for this method to clean up.
      def run_with_session_warmer
        Bidi2pdf::SessionWarmer.with_tab { |tab| print_and_notify(tab) }
      end

      def run_with_chromedriver_manager_singleton
        browser = ChromedriverManagerSingleton.session.browser
        context = browser.create_user_context
        window = context.create_browser_window
        tab = window.create_browser_tab

        begin
          print_and_notify(tab)
        ensure
          tab&.close
          window&.close
          context&.close
          ChromedriverManagerSingleton.session_close
        end
      end

      def print_and_notify(tab)
        prepare_tab(tab)
        base64_data = tab.print(print_options: @print_options)
        binary_pdf_content = Base64.decode64(base64_data)

        notify_after_print(tab, binary_pdf_content)
      end

      def wait_for_tab(tab)
        tab.wait_until_network_idle if @wait_for_network_idle
        tab.wait_until_page_loaded(check_script: @wait_for_page_check_script) if @wait_for_page_loaded
      end

      def with_interlock_warning(&block)
        ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
          block.call
        end
      rescue StandardError => e
        warn_interlock
        raise e
      end

      def warn_interlock
        return unless Rails.env.development?

        Bidi2pdfRails.logger.warn <<~MSG
          [DEADLOCK WARNING] In development mode, PDF rendering may hang due to Rails’ autoload interlock
          on “loopback” asset or page requests (see https://puma.io/puma/file.rails_dev_mode.html).

          Quick Fixes:
            1. Precompile & serve assets statically (config.public_file_server.enabled = true)
               → avoids dynamic asset serving
            2. Or run Puma with WEB_CONCURRENCY=n and RAILS_MAX_THREADS=1
               → isolates requests in separate processes :contentReference[oaicite:9]{index=9}
        MSG
      end
    end
  end
end
