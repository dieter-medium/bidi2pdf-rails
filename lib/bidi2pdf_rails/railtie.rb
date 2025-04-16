# frozen_string_literal: true

module Bidi2pdfRails
  class Railtie < ::Rails::Railtie
    initializer "bidi2pdf_rails.add_mime_type" do
      Mime::Type.register "application/pdf", :pdf unless Mime::Type.lookup_by_extension(:pdf)
    end

    initializer "bidi2pdf_rails.initialize_chromedriver_manager", after: :load_config_initializers do
      Bidi2pdfRails.apply_bidi2pdf_config

      Rails.application.config.after_initialize do
        ChromedriverManagerSingleton.initialize_manager
      end
    end

    config.after_initialize do
      # Set up shutdown hook for when the application stops
      at_exit do
        ChromedriverManagerSingleton.shutdown
      end
    end

    initializer "bidi2pdf_rails.add_pdf_renderer" do
      ActionController::Renderers.add :pdf do |filename, options|
        pdf_data = ""
        options = options.dup

        original_asset_host = ActionController::Base.asset_host

        if options[:asset_host]
          ActionController::Base.asset_host = options[:asset_host]
        elsif !Rails.application.config.action_controller.asset_host
          # Use request base URL as fallback if no asset host configured
          ActionController::Base.asset_host = request.base_url
        end

        html = render_to_string(options.merge(formats: [ :html ]))

        Bidi2pdf.default_timeout = 30

        thread = Thread.new {
          Rails.application.executor.wrap do
            browser = ChromedriverManagerSingleton.session.browser
            context = browser.create_user_context
            window = context.create_browser_window
            tab = window.create_browser_tab

            tab.render_html_content html

            tab.wait_until_network_idle

            # sleep 60

            tab.wait_until_page_loaded

            pdf_data = tab.print
          ensure
            tab&.close
            window&.close
            context&.close
          end
        }

        thread.join

        send_data Base64.decode64(pdf_data),
                  type: Mime[:pdf],
                  filename: "#{filename}.pdf",
                  disposition: options.fetch(:disposition, "inline")
      ensure

        ActionController::Base.asset_host = original_asset_host
      end
    end
  end
end
