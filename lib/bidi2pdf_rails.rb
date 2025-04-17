# frozen_string_literal: true

require "bidi2pdf"
require_relative "bidi2pdf_rails/version"
require_relative "bidi2pdf_rails/railtie"
require_relative "bidi2pdf_rails/chromedriver_manager_singleton"
require_relative "bidi2pdf_rails/main_log_subscriber"
require_relative "bidi2pdf_rails/browser_console_log_subscriber"
require_relative "bidi2pdf_rails/network_log_subscriber"

module Bidi2pdfRails
  class << self
    attr_accessor :logger, :notification_service, :verbosity, :default_timeout, :log_network_events, :log_browser_console, :remote_browser_url, :cookies,
                  :headers, :auth, :headless, :chromedriver_port, :chrome_session_args,
                  :proxy_addr, :proxy_port, :proxy_user, :proxy_pass, :install_dir,
                  :viewport_width, :viewport_height,
                  :pdf_margin_top, :pdf_margin_bottom, :pdf_margin_left, :pdf_margin_right,
                  :pdf_scale, :pdf_print_background, :pdf_format, :pdf_orientation, :verbosity

    # Allow configuration through a block
    def configure
      yield self if block_given?

      apply_bidi2pdf_config
    end

    def apply_bidi2pdf_config
      # Allow configuration through a block
      Bidi2pdf.configure do |config|
        config.notification_service = notification_service

        config.logger = logger.tagged("bidi2pdf")
        config.default_timeout = default_timeout

        if log_network_events
          config.network_events_logger = logger.tagged("bidi2pdf", "network")
        else
          config.network_events_logger = Logger.new(nil) # Disable network events logging
        end

        if log_browser_console
          config.browser_console_logger = logger.tagged("bidi2pdf", "browser_console")
        else
          config.browser_console_logger = Logger.new(nil) # Disable browser console logging
        end

        config.enable_default_logging_subscriber = false
      end

      Chromedriver::Binary.configure do |config|
        config.logger = logger

        config.proxy_addr = proxy_addr
        config.proxy_port = proxy_port
        config.proxy_user = proxy_user
        config.proxy_pass = proxy_pass

        config.install_dir = install_dir
      end
    end

    def reset_to_defaults!
      @logger = nil
      @default_timeout = 10
      @log_network_events = false
      @log_browser_console = true
      @verbosity = 0
      @remote_browser_url = nil
      @cookies = {}
      @headers = {}
      @auth = nil
      @headless = !Rails.env.development?
      @chromedriver_port = 0
      @chrome_session_args = Bidi2pdf::Bidi::Session::DEFAULT_CHROME_ARGS

      @proxy_addr = nil
      @proxy_port = nil
      @proxy_user = nil
      @proxy_pass = nil
      @install_dir = nil
    end

    def logger
      @logger ||= Rails.logger # lazy load the logger, after it exists
    end
  end

  self.reset_to_defaults!
end
