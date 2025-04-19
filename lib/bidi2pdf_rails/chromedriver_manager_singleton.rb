# frozen_string_literal: true

module Bidi2pdfRails
  module ChromedriverManagerSingleton
    class << self
      attr_reader :manager, :session

      def initialize_manager
        return unless running_as_server?

        @mutex ||= Mutex.new
        @mutex.synchronize do
          return if @manager && @session

          msg = Bidi2pdfRails.use_remote_browser? ? "Remote session" : "ChromeDriver manager"

          Bidi2pdfRails.logger.info "Initializing Bidi2pdf #{msg}"

          if Bidi2pdfRails.use_remote_browser?
            @session = Bidi::Session.new(
              session_url: Bidi2pdfRails.config.render_remote_settings.browser_url_value,
              headless: Bidi2pdfRails.config.general_options.headless_value,
              chrome_args: Bidi2pdfRails.config.general_options.chrome_session_args_value
            )
          else
            @manager = Bidi2pdf::ChromedriverManager.new(
              port: Bidi2pdfRails.config.chromedriver_settings.port_value,
              headless: Bidi2pdfRails.config.general_options.headless_value,
              chrome_args: Bidi2pdfRails.config.general_options.chrome_session_args_value
            )
            @manager.start
            @session = @manager.session
          end

          @session.start
          @session.client.on_close { Bidi2pdfRails.logger.info "WebSocket session closed" }
        end
      end

      def shutdown
        return unless running_as_server?

        @mutex ||= Mutex.new
        @mutex.synchronize do
          msg = Bidi2pdfRails.use_remote_browser? ? "Remote session" : "ChromeDriver manager"
          Bidi2pdfRails.logger.info "Shutting down Bidi2pdf #{msg}"
          @session&.close
          @manager&.stop
          @session = nil
          @manager = nil
        end
      end

      def running_as_server?
        return false if Rails.const_defined?(:Console)
        return false if defined?(Rails::Generators)

        return false if File.basename($0) == "rake"

        # Covers common Rails server entrypoints
        server_commands = %w[server puma unicorn passenger thin webrick rackup]
        cmdline = File.basename($0)

        server_commands.any? { |s| cmdline.include?(s) } ||
          Rails.const_defined?("Server")
      end
    end
  end
end
