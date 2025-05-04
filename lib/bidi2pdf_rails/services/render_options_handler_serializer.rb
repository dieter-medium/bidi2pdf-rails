# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    class RenderOptionsHandlerSerializer < ActiveJob::Serializers::ObjectSerializer
      def serialize(options_handler)
        raise ArgumentError, "Inline HTML rendering must be performed with render_inline! before enqueueing the job. Without a URL specified, the HTML content cannot be generated in the background job context." if options_handler.inline_rendering_needed?

        super(
          "options" => options_handler.job_options,
          "filename" => options_handler.pdf.filename,
        )
      end

      def deserialize(hash)
        ::Bidi2pdfRails::Services::RenderOptionsHandler.new(hash["filename"], hash["options"], nil)
      end

      private

      def klass
        ::Bidi2pdfRails::Services::RenderOptionsHandler
      end
    end
  end
end
