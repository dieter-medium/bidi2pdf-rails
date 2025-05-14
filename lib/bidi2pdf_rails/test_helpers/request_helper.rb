module Bidi2pdfRails
  module TestHelpers
    require "net/http"
    module RequestHelper
      def get_pdf_response(path)
        uri = URI(path.starts_with?("http") ? path : "#{server_url}/#{path}")
        Net::HTTP.get_response(uri)
      end

      def follow_redirects(response, max_redirects = 10)
        redirect_count = 0
        while response.is_a?(Net::HTTPRedirection) && redirect_count < max_redirects
          redirect_url = response["location"]
          response = get_pdf_response redirect_url
          redirect_count += 1
        end
        response
      end
    end

    RSpec.configure do |config|
      config.include RequestHelper, pdf: true
    end
  end
end
