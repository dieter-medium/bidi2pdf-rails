# frozen_string_literal: true

module Bidi2pdfRails
  class MainLogSubscriber < ActiveSupport::LogSubscriber
    @silenced_events = []

    class << self
      attr_accessor :silenced_events

      def silence(event)
        self.silenced_events << event
      end

      def silenced?(event)
        self.silenced_events.any? { |silenced_event| silenced_event === event }
      end
    end

    include Bidi2pdf::Notifications::LoggingSubscriberActions

    def logger
      Bidi2pdf::VerboseLogger.new(super.tagged("bidi2pdf_rails"), Bidi2pdfRails.verbosity)
    end

    def silenced?(event)
      MainLogSubscriber.silenced?(event) || super(event)
    end
  end
end
