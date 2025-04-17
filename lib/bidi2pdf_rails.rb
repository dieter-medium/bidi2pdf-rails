# frozen_string_literal: true

require "bidi2pdf"
require "bidi2pdf/bidi/commands/print_parameters_validator"
require_relative "bidi2pdf_rails/version"
require_relative "bidi2pdf_rails/railtie"
require_relative "bidi2pdf_rails/chromedriver_manager_singleton"
require_relative "bidi2pdf_rails/main_log_subscriber"
require_relative "bidi2pdf_rails/browser_console_log_subscriber"
require_relative "bidi2pdf_rails/network_log_subscriber"

module Bidi2pdfRails
  class << self
    attr_accessor :logger, :notification_service, :verbosity, :default_timeout, :remote_browser_url, :cookies,
                  :headers, :auth, :headless, :chromedriver_port, :chrome_session_args,
                  :proxy_addr, :proxy_port, :proxy_user, :proxy_pass, :install_dir,
                  :pdf_page_width, :pdf_page_height,
                  :pdf_margin_top, :pdf_margin_bottom, :pdf_margin_left, :pdf_margin_right,
                  :pdf_scale, :pdf_shrink_to_fit, :pdf_print_background, :pdf_page_format, :pdf_orientation, :verbosity,
                  :wait_for_network_idle, :wait_for_page_loaded, :wait_for_page_check_script

    # Allow configuration through a block
    def configure
      yield self if block_given?

      validate_print_options! print_options
      apply_bidi2pdf_config
    end

    def validate_print_options!(opts)
      validator = Bidi2pdf::Bidi::Commands::PrintParametersValidator.new(opts)

      validator.validate!
    end

    def print_options(overrides = {})
      overrides ||= {}
      opts = {}

      opts[:background] = pdf_print_background unless pdf_print_background.nil?
      opts[:orientation] = pdf_orientation unless pdf_orientation.nil?
      opts[:scale] = pdf_scale unless pdf_scale.nil?
      opts[:shrinkToFit] = pdf_shrink_to_fit unless pdf_shrink_to_fit.nil?

      # Margins
      margins = {
        top: @pdf_margin_top,
        bottom: @pdf_margin_bottom,
        left: @pdf_margin_left,
        right: @pdf_margin_right
      }.compact

      opts[:margin] = margins unless margins.empty?

      # Page size
      page = {
        width: @pdf_page_width,
        height: @pdf_page_height,
        format: @pdf_page_format
      }.compact

      page = overrides[:page].compact if overrides[:page]&.compact.present?

      opts[:page] = page unless page.empty?

      opts.deep_merge(overrides)
    end

    def apply_bidi2pdf_config
      # Allow configuration through a block
      Bidi2pdf.configure do |config|
        config.notification_service = notification_service

        config.logger = logger.tagged("bidi2pdf")
        config.default_timeout = default_timeout

        config.network_events_logger = Logger.new(nil)
        config.browser_console_logger = Logger.new(nil) # Disable browser console logging

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

    def use_local_chromedriver?
      !use_remote_browser?
    end

    def use_remote_browser?
      remote_browser_url.present?
    end

    def reset_to_defaults!
      @logger = nil
      @default_timeout = 10
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

      @wait_for_network_idle = true
      @wait_for_page_loaded = false
      @wait_for_page_check_script = nil

      @pdf_print_background = true
      @pdf_orientation = "portrait"
      @pdf_page_width = Bidi2pdf::PAPER_FORMATS_CM[:a4][:width]
      @pdf_page_height = Bidi2pdf::PAPER_FORMATS_CM[:a4][:height]
      @pdf_page_format = nil

      @pdf_shrink_to_fit = nil
      @pdf_scale = 1.0
    end

    def logger
      @logger ||= Rails.logger # lazy load the logger, after it exists
    end
  end

  self.reset_to_defaults!
end
