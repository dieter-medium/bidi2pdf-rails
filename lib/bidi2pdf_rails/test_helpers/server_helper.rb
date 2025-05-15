require_relative "server"

module Bidi2pdfRails
  module TestHelpers
    # This module provides helper methods for handling PDF files in tests.
    # It includes methods for debugging, storing, and managing PDF files.
    module ServerHelper
      def server_running?
        Bidi2pdfRails::TestHelpers.configuration.server&.running?
      end

      def server_port
        Bidi2pdfRails::TestHelpers.configuration.server&.port
      end

      def server_host
        Bidi2pdfRails::TestHelpers.configuration.server&.host
      end

      def request_host
        Bidi2pdfRails::TestHelpers.configuration.request_host
      end

      def first_private_ip
        Socket.ip_address_list.detect(&:ipv4_private?).ip_address
      end

      def server_url
        "http://#{request_host}:#{server_port}"
      end
    end

    RSpec.configure do |config|
      config.include ServerHelper, pdf: true

      config.before(:suite, type: :request) do
        next unless Bidi2pdfRails::TestHelpers.configuration.run_server

        Bidi2pdfRails::TestHelpers.configuration.server ||= Bidi2pdfRails::TestHelpers::Server.new

        Bidi2pdfRails::TestHelpers.configuration.server.boot
      end

      config.after(:suite, type: :request) do
        Bidi2pdfRails::TestHelpers.configuration.server&.shutdown
      end
    end
  end
end
