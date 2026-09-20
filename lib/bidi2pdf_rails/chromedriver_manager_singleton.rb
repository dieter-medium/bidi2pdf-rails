# frozen_string_literal: true

module Bidi2pdfRails
  module ChromedriverManagerSingleton
    Thread.attr_accessor :bidi2pdf_rails_session

    class << self
      attr_reader :manager

      def initialize_manager(force: false)
        return unless running_as_server? || force

        @mutex ||= Mutex.new
        @mutex.synchronize do
          # Initialized once per process: both on_load hooks in the railtie call this, and a second
          # pass must never start a second chromedriver (or a warmer next to a running manager).
          # force: true asks for a clean re-initialization instead - what is running is torn down
          # first, never orphaned.
          if @active_mode
            unless force
              warn_if_session_warmer_settings_changed if @active_mode == :warmer
              next
            end

            teardown
          end

          if session_warmer_enabled?
            configure_session_warmer
            @active_mode = :warmer
            next
          end

          msg = Bidi2pdfRails.use_remote_browser? ? "Remote session" : "ChromeDriver manager"

          Bidi2pdfRails.logger.info "Initializing Bidi2pdf #{msg}"

          unless Bidi2pdfRails.use_remote_browser?
            @manager = Bidi2pdf::ChromedriverManager.new(
              port: Bidi2pdfRails.config.chromedriver_settings.port_value,
              headless: Bidi2pdfRails.config.general_options.headless_value,
              chrome_args: Bidi2pdfRails.config.general_options.chrome_session_args_value
            )
            @manager.start
          end

          @active_mode = :manager
        end
      end

      # Whether PdfBrowserSession should take a tab from Bidi2pdf::SessionWarmer instead of this
      # singleton's own ChromedriverManager/thread-local Session - default-off, see
      # bidi2pdf's docs/plans/faster-pdf-generation.md for why.
      def session_warmer_enabled?
        Bidi2pdfRails.config.session_warmer_settings.enabled_value
      end

      # Whether the warmer is what this process actually initialized - the render path asks this, not
      # the setting: with the setting flipped after boot (or never initialized at all),
      # Bidi2pdf::SessionWarmer would lazily build itself from its own defaults and ignore headless,
      # chrome args and the remote browser URL configured here.
      def session_warmer_active?
        @active_mode == :warmer
      end

      def session
        Thread.current.bidi2pdf_rails_session ||= begin
                                                    if Bidi2pdfRails.use_remote_browser?
                                                      session = Bidi2pdf::Bidi::Session.new(
                                                        session_url: Bidi2pdfRails.config.render_remote_settings.browser_url_value,
                                                        headless: Bidi2pdfRails.config.general_options.headless_value,
                                                        chrome_args: Bidi2pdfRails.config.general_options.chrome_session_args_value
                                                      )
                                                    else
                                                      session = @manager.session
                                                    end

                                                    session.start
                                                    session.client.on_close { Bidi2pdfRails.logger.info "WebSocket session closed" }
                                                    session
                                                  end
      end

      def session_close
        Thread.current.bidi2pdf_rails_session&.close
        Thread.current.bidi2pdf_rails_session = nil
      end

      # force: true mirrors #initialize_manager - outside a server process (a spec run, a console)
      # nothing else would ever stop what a forced initialize started.
      def shutdown(force: false)
        return unless running_as_server? || force

        @mutex ||= Mutex.new
        @mutex.synchronize { teardown }
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

      private

      # Tears down the mode actually initialized (@active_mode), never whatever
      # session_warmer_enabled? says right now - a setting flipped in between must not leave the
      # thing that is really running alive. Callers hold @mutex.
      def teardown
        case @active_mode
        when :warmer
          Bidi2pdfRails.logger.info "Shutting down Bidi2pdf::SessionWarmer"
          Bidi2pdf::SessionWarmer.shutdown
        when :manager
          msg = Bidi2pdfRails.use_remote_browser? ? "Remote session" : "ChromeDriver manager"
          Bidi2pdfRails.logger.info "Shutting down Bidi2pdf #{msg}"
          session_close
          @manager&.stop
          @manager = nil
        end

        @active_mode = nil
      end

      def configure_session_warmer
        # A warmer slot's chromedriver stays alive while its replacement warms in the background
        # (checkout replenishes immediately) - at least two chromedrivers are alive at once even at
        # size = 1, so a fixed port is not merely unimplemented, it is unusable. Fail fast instead of
        # silently ignoring it (chromedriver_settings.port has no effect on the warmer path at all).
        if nonzero_chromedriver_port?
          raise ArgumentError, <<~MSG.squish
            chromedriver_settings.port is set to #{Bidi2pdfRails.config.chromedriver_settings.port_value},
            but Bidi2pdf::SessionWarmer cannot honor a fixed port: it keeps a replacement chromedriver
            warming while a checked-out slot's chromedriver is still running, so at least two
            chromedrivers are alive at once even at session_warmer_settings.size = 1. Leave
            chromedriver_settings.port at its default (0) when session_warmer_settings.enabled is true.
          MSG
        end

        Bidi2pdfRails.logger.info "Configuring Bidi2pdf::SessionWarmer"

        @session_warmer_settings_snapshot = current_session_warmer_settings

        Bidi2pdf::SessionWarmer.configure do |c|
          c.size = @session_warmer_settings_snapshot[:size]
          c.max_idle_age = @session_warmer_settings_snapshot[:max_idle_age]
          c.headless = @session_warmer_settings_snapshot[:headless]
          c.chrome_args = @session_warmer_settings_snapshot[:chrome_args]
          c.remote_browser_url = @session_warmer_settings_snapshot[:remote_browser_url] if Bidi2pdfRails.use_remote_browser?
        end
      end

      def nonzero_chromedriver_port?
        !Bidi2pdfRails.config.chromedriver_settings.port_value.to_i.zero?
      end

      # Bidi2pdf::SessionWarmer is configured once, at the first initialize_manager call - later
      # calls (e.g. the second on_load hook at boot) are a no-op by design, not a bug, but that means
      # a settings change made after boot is silently ignored unless something says so.
      def current_session_warmer_settings
        {
          size: Bidi2pdfRails.config.session_warmer_settings.size_value,
          max_idle_age: Bidi2pdfRails.config.session_warmer_settings.max_idle_age_value,
          headless: Bidi2pdfRails.config.general_options.headless_value,
          chrome_args: Bidi2pdfRails.config.general_options.chrome_session_args_value,
          remote_browser_url: Bidi2pdfRails.use_remote_browser? ? Bidi2pdfRails.config.render_remote_settings.browser_url_value : nil
        }
      end

      def warn_if_session_warmer_settings_changed
        current = current_session_warmer_settings
        return if current == @session_warmer_settings_snapshot

        Bidi2pdfRails.logger.warn(
          "Bidi2pdf::SessionWarmer is already configured; session_warmer_settings/general_options/" \
            "render_remote_settings changes are boot-time immutable and were ignored. Call " \
            "ChromedriverManagerSingleton.shutdown then .initialize_manager to apply them."
        )
      end
    end
  end
end
