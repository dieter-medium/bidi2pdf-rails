# frozen_string_literal: true

module Bidi2pdfRails
  module TestHelpers
    class Configuration < Bidi2pdf::TestHelpers::Configuration
      # @!attribute [rw] run_server
      #   @return [Boolean] whether to run the server during tests
      attr_accessor :run_server

      # @!attribute [rw] server_host
      #   @return [String] the host address for the server
      attr_accessor :server_host

      # @!attribute [w] request_host
      #  @return [String] the host address for requests
      attr_writer :request_host

      # @!attribute [rw] server_port
      #   @return [Integer, nil] the port for the server (nil if not set => random port)
      attr_accessor :server_port

      # @!attribute [rw] server_boot_timeout
      #   @return [Integer] the timeout in seconds for server boot
      attr_accessor :server_boot_timeout

      # @!attribute [rw] server (for internal use only)
      #   @return [Object, nil] the server instance (nil if not set)
      attr_accessor :server

      def initialize
        super
        @run_server = true
        @server_host = "localhost"
        @request_host = "localhost"
        @server_port = nil
        @server_boot_timeout = 15
      end

      def request_host
        @request_host.respond_to?(:call) ? @request_host.call : @request_host
      end
    end

    class << self
      # Retrieves the current configuration object for TestHelpers.
      # @return [Configuration] the configuration object
      def configuration
        @configuration ||= Configuration.new
      end

      # Allows configuration of TestHelpers by yielding the configuration object.
      # @yieldparam [Configuration] configuration the configuration object to modify
      def configure
        yield(configuration)
      end
    end
  end

  Bidi2pdf::TestHelpers.configuration = TestHelpers.configuration

  # Configures RSpec to include and extend SpecPathsHelper for examples with the `:pdf` metadata.
  RSpec.configure do |config|
    # Adds a custom RSpec setting for TestHelpers configuration.
    config.add_setting :bidi2pdf_rails_test_helpers_config, default: TestHelpers.configuration
  end
end
