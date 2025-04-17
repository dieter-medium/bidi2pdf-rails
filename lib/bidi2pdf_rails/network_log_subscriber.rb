# frozen_string_literal: true

require "bidi2pdf/bidi/network_event_formatters/network_event_console_formatter"

module Bidi2pdfRails
  class NetworkLogSubscriber < ActiveSupport::LogSubscriber
    def network_event_received(event)
      payload = event.payload

      return if payload[:method] == "network.responseStarted" || payload[:method] == "network.beforeRequestSent"

      logger.tagged("bidi2pdf_rails", "network") do |tagged_logger|
        verbose_logger = Bidi2pdf::VerboseLogger.new(tagged_logger, Bidi2pdfRails.verbosity)
        formatter = Bidi2pdf::Bidi::NetworkEventFormatters::NetworkEventConsoleFormatter.new(logger: verbose_logger)

        formatter.log [payload[:event]]
      end
    end
  end
end
