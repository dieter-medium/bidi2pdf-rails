# frozen_string_literal: true

require "bidi2pdf/bidi/browser_console_logger"

module Bidi2pdfRails
  class BrowserConsoleLogSubscriber < ActiveSupport::LogSubscriber
    def browser_console_log_received(event)
      payload = event.payload
      timestamp = Bidi2pdf::Bidi::BrowserConsoleLogger.format_timestamp(payload[:timestamp])

      logger.tagged("bidi2pdf_rails", "browser_console", timestamp) do |tagged_logger|
        verbose_logger = Bidi2pdf::VerboseLogger.new(tagged_logger, Bidi2pdfRails.config.general_options.verbosity_value)
        Bidi2pdf::Bidi::BrowserConsoleLogger.new(verbose_logger)
                                            .builder
                                            .with_level(payload[:level])
                                            .with_prefix("")
                                            .with_text(payload[:text])
                                            .with_args(payload[:args])
                                            .with_stack_trace(payload[:stack_trace])
                                            .log_event
      end
    end
  end
end
