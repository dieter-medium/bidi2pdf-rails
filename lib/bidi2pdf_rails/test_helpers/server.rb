# frozen_string_literal: true

module Bidi2pdfRails
  module TestHelpers
    require "socket"
    require "net/http"
    require "rack/handler/puma"

    class Server
      attr_reader :app, :host, :server_boot_timeout

      def initialize(
        app: Rails.application,
        port: TestHelpers.configuration.server_port,
        host: TestHelpers.configuration.server_host,
        server_boot_timeout: TestHelpers.configuration.server_boot_timeout
      )
        @app = app
        @port = port
        @host = host
        @server_boot_timeout = server_boot_timeout
      end

      def port
        @port ||= find_available_port
      end

      def running?
        @booted && @server_thread&.alive?
      end

      def boot
        return if @booted

        @booted = true

        that = self

        @server_thread = Thread.new do
          Rack::Handler::Puma.run that.app, Port: that.port, Silent: false
        rescue Errno::EADDRINUSE => e
          puts "Port #{that.port} is already/still in use."

          raise e
        end

        wait_until_server_is_ready
      end

      def shutdown
        return unless @booted

        @booted = false

        if @server_thread&.alive?
          @server_thread.exit
          @server_thread.join
        end
      end

      private

      def wait_until_server_is_ready
        Timeout.timeout(server_boot_timeout) {
          loop do
            begin
              raise "Server not started" unless running?

              Net::HTTP.get(URI("http://#{host}:#{port}/up"))
              break
            rescue Errno::ECONNREFUSED
              sleep 0.1
            end
          end
        }
      rescue Timeout::Error => e
        puts "Server did not start within #{server_boot_timeout} seconds. Host: #{host}, Port: #{port}"
        shutdown
        raise e
      end

      def find_available_port
        server = TCPServer.new(host, 0)
        server.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
        port = server.addr[1]

        server.listen 1

        server.close

        port
      end
    end
  end
end
