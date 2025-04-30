# frozen_string_literal: true

require "bidi2pdf"
require "bidi2pdf/bidi/commands/print_parameters_validator"
require_relative "bidi2pdf_rails/version"
require_relative "bidi2pdf_rails/config"
require_relative "bidi2pdf_rails/railtie"
require_relative "bidi2pdf_rails/chromedriver_manager_singleton"
require_relative "bidi2pdf_rails/main_log_subscriber"
require_relative "bidi2pdf_rails/browser_console_log_subscriber"
require_relative "bidi2pdf_rails/network_log_subscriber"

module Bidi2pdfRails
  class << self
    def config
      Config.instance
    end

    # Allow configuration through a block
    def configure
      yield config if block_given?

      config.validate_print_options!

      apply_bidi2pdf_config config
    end

    def apply_bidi2pdf_config(config = Config.instance)
      Bidi2pdf.configure do |bidi2pdf_config|
        bidi2pdf_config.notification_service = config.general_options.notification_service_value

        bidi2pdf_config.logger = config.general_options.logger_value&.tagged("bidi2pdf")
        bidi2pdf_config.logger.verbosity = config.general_options.verbosity_value
        bidi2pdf_config.default_timeout = config.general_options.default_timeout_value

        bidi2pdf_config.network_events_logger = Logger.new(nil)
        bidi2pdf_config.browser_console_logger = Logger.new(nil)

        bidi2pdf_config.enable_default_logging_subscriber = false
      end

      Chromedriver::Binary.configure do |chromedriver_config|
        chromedriver_config.logger = config.general_options.logger_value&.tagged("bidi2pdf")

        chromedriver_config.proxy_addr = config.proxy_settings.addr_value
        chromedriver_config.proxy_port = config.proxy_settings.port_value
        chromedriver_config.proxy_user = config.proxy_settings.user_value
        chromedriver_config.proxy_pass = config.proxy_settings.pass_value

        chromedriver_config.install_dir = config.chromedriver_settings.install_dir_value
      end
    end

    def use_local_chromedriver?
      !use_remote_browser?
    end

    def use_remote_browser?
      config.render_remote_settings.browser_url_value.present?
    end

    def logger
      config.general_options.logger_value&.tagged("bidi2pdf-rails")
    end
  end

  that = self
  ActiveSupport.on_load(:action_controller_base, run_once: true) do
    that.configure # apply the default configuration at load time
  end
end
