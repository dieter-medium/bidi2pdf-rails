# frozen_string_literal: true

module Bidi2pdfRails
  module TestHelpers
    module EnvironmentHelper
      # Checks if the code is running inside a Docker container.
      # @return [Boolean] true if inside a Docker container, false otherwise
      def inside_container?
        File.exist?("/.dockerenv")
      end

      # Determines the current environment type based on environment variables and context.
      # @return [Symbol] the environment type (:ci, :codespaces, :container, or :local)
      def environment_type
        if ENV["CI"]
          :ci
        elsif ENV["CODESPACES"] && ENV["CODESPACES"] == "true"
          :codespaces
        elsif inside_container?
          :container
        else
          :local
        end
      end

      # Checks if the current environment matches the given type.
      # @param [Symbol] type the environment type to check (:ci, :codespaces, :container, or :local)
      # @return [Boolean] true if the current environment matches the given type, false otherwise
      def environment_type?(type)
        environment_type == type
      end

      # Checks if the current environment is a CI environment.
      # @return [Boolean] true if the environment is CI, false otherwise
      def environment_ci?
        environment_type? :ci
      end

      # Checks if the current environment is a GitHub Codespaces environment.
      # @return [Boolean] true if the environment is Codespaces, false otherwise
      def environment_codespaces?
        environment_type? :codespaces
      end

      # Checks if the current environment is a containerized environment.
      # @return [Boolean] true if the environment is a container, false otherwise
      def environment_container?
        environment_type? :container
      end

      # Checks if the current environment is a local environment.
      # @return [Boolean] true if the environment is local, false otherwise
      def environment_local?
        environment_type? :local
      end
    end

    RSpec.configure do |config|
      # Includes the EnvironmentHelper module in RSpec examples with the `:pdf` metadata.
      config.include EnvironmentHelper, pdf: true
    end
  end
end
