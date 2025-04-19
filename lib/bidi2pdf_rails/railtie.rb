# frozen_string_literal: true

require "rails/railtie"

require_relative "services/html_renderer"
require_relative "services/pdf_renderer"
require_relative "services/pdf_browser_session"
require_relative "services/url_to_pdf_converter"
require_relative "services/html_to_pdf_converter"

module Bidi2pdfRails
  class Railtie < ::Rails::Railtie
    initializer "bidi2pdf_rails.add_mime_type" do
      Mime::Type.register "application/pdf", :pdf unless Mime::Type.lookup_by_extension(:pdf)
    end

    initializer "bidi2pdf_rails.initialize_chromedriver_manager", after: :load_config_initializers do
      Bidi2pdfRails.apply_bidi2pdf_config

      # defer the initialization of the ChromedriverManager to the ActionController::Base class load event
      ActiveSupport.on_load(:action_controller_base) do
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
        options = options.dup

        pdf_content = Services::PdfRenderer.new(filename, options, self).render_pdf

        send_data pdf_content,
                  type: Mime[:pdf],
                  filename: "#{filename}.pdf",
                  disposition: options.fetch(:disposition, "inline")
      end
    end
  end
end
