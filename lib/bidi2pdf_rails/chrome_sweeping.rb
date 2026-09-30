# frozen_string_literal: true

module Bidi2pdfRails
  # Connects bidi2pdf's leased session registry and Bidi2pdf::ChromeSweeper to the Rails settings
  # (sweeper_settings) - remote browser only, there is no shared chromedriver otherwise.
  #
  # Every remote session a render opens is leased in the registry (#registry), sweeper or not: a
  # sweeper in another process - another Puma worker, a job worker - then knows it is in use. With
  # sweeper_settings.enabled, each process gets one sweeper (#sweeper): it sweeps every
  # sweeper_settings.interval seconds when set, and #with_retry makes it the last resort for a
  # render that failed for lack of resources.
  module ChromeSweeping
    # sweeper_settings keys passed to Bidi2pdf::ChromeSweeper as they are.
    # Bidi2pdf::ChromeSweeper's lease_ttl option is deliberately not passed: every lease carries the
    # TTL its owner's heartbeat promises, and that option only covers entries written by bidi2pdf
    # 0.1.18.
    PASSED_THROUGH = %i[orphan_age min_age unresponsive_checks pids_limit registry_dir].freeze

    # With the warmer, a refused session was already swept for and retried by the warmer itself -
    # retrying the whole render on top would stack a second pair of attempts.
    RETRYABLE_WITH_WARMER = ->(error) { !error.is_a?(Bidi2pdf::SessionNotStartedError) && Bidi2pdf::ChromeSweeper::RETRYABLE.call(error) }

    class << self
      def enabled?
        Bidi2pdfRails.use_remote_browser? && settings.enabled_value
      end

      # The registry remote sessions are leased in; nil without a remote browser.
      def registry
        return unless Bidi2pdfRails.use_remote_browser?

        Bidi2pdf::SessionRegistry.new(browser_url, dir: settings.registry_dir_value)
      end

      # Bidi2pdf::ChromeSweeper settings from sweeper_settings (without the background interval).
      def options
        PASSED_THROUGH.to_h { |key| [key, settings.public_send("#{key}_value")] }
                      .merge(scope: settings.scope_value.to_s.to_sym, max_sessions: max_sessions)
      end

      # The sweeper settings for Bidi2pdf::SessionWarmer - nil unless it should retry a refused
      # session, which is all its own sweeper does (background sweeps belong to #sweeper).
      def warmer_sweeper_options
        options if enabled? && settings.retry_on_failure_value
      end

      # This process's sweeper, nil when sweeping is off. Built on first use, never before - that is
      # a render or a sweep in a worker, not the Puma master that forks it, whose background thread
      # would not survive the fork. A forked process builds its own.
      def sweeper
        return unless enabled?

        @mutex.synchronize do
          reset_after_fork
          @sweeper ||= build_sweeper
        end
      end

      # Runs a render; when it fails for lack of resources, sweeps under pressure and runs it once
      # more (Bidi2pdf::ChromeSweeper#with_retry). Without sweeping, or with retry_on_failure off,
      # just runs it.
      def with_retry(&)
        current = settings.retry_on_failure_value ? sweeper : nil
        return yield unless current

        retry_on = ChromedriverManagerSingleton.session_warmer_active? ? RETRYABLE_WITH_WARMER : Bidi2pdf::ChromeSweeper::RETRYABLE
        current.with_retry(retry_on: retry_on, &)
      end

      # One sweep now, with the configured rules - whether or not sweeper_settings.enabled.
      #
      # @param pressure [Boolean] the last resort: close everything nobody holds past min_age.
      # @param dry_run [Boolean] report what would be closed, close nothing.
      # @param check_interval [Numeric, nil] check twice this many seconds apart first, so the
      #   unresponsive rule applies too.
      # @return [Bidi2pdf::ChromeSweeper::Result]
      def sweep!(pressure: false, dry_run: false, check_interval: nil)
        one_shot(dry_run: dry_run).sweep!(reason: :manual, pressure: pressure, check_interval: check_interval)
      end

      # Every session on the remote chromedriver in the configured scope; live ones are marked.
      #
      # @return [Array<Bidi2pdf::ChromeSweeper::Inspector::SessionInfo>]
      def sessions
        one_shot.sessions
      end

      # Stops the background sweeps of this process.
      def stop
        current = @mutex.synchronize { @sweeper.tap { @sweeper = nil } }
        current&.stop
      end

      private

      def settings
        Bidi2pdfRails.config.sweeper_settings
      end

      def browser_url
        Bidi2pdfRails.config.render_remote_settings.browser_url_value
      end

      def max_sessions
        value = settings.max_sessions_value
        value.to_s == "auto" ? :auto : value&.to_i
      end

      def build_sweeper
        Bidi2pdf::ChromeSweeper.new(browser_url, interval: settings.interval_value, **options).tap do |built|
          built.start if built.interval
        end
      end

      def one_shot(dry_run: false)
        raise ArgumentError, "sweeping needs render_remote_settings.browser_url" unless Bidi2pdfRails.use_remote_browser?

        Bidi2pdf::ChromeSweeper.new(browser_url, dry_run: dry_run, **options)
      end

      # A forked child starts without the parent's sweeper - its thread did not survive the fork.
      def reset_after_fork
        return if @pid == Process.pid

        @pid = Process.pid
        @sweeper = nil
      end
    end

    @mutex = Mutex.new
  end
end
