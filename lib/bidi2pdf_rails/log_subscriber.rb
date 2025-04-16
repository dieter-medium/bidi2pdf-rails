# frozen_string_literal: true

module Bidi2pdfRails
  class LogSubscriber < ActiveSupport::LogSubscriber
    include Bidi2pdf::Notifications::LoggingSubscriberActions

    def logger
      Bidi2pdf::VerboseLogger.new(super.tagged("bidi2pdf_rails"), Bidi2pdfRails.verbosity)
    end
  end
end

Bidi2pdfRails::LogSubscriber.attach_to "bidi2pdf", inherit_all: true
