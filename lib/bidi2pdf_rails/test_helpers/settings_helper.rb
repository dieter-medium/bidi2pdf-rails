# frozen_string_literal: true

module Bidi2pdfRails
  module TestHelpers
    module SettingsHelper
      # Temporarily overrides a render setting with a new value.
      # The original value is stored for later restoration.
      # @param [Symbol] key the setting key to override
      # @param [Object] value the new value to set
      def with_render_setting(key, value)
        overridden_render_settings[key] = Bidi2pdfRails.config.render_remote_settings.public_send(key)
        Bidi2pdfRails.config.render_remote_settings.public_send("#{key}=", value)
      end

      # Temporarily overrides a PDF setting with a new value.
      # The original value is stored for later restoration.
      # @param [Symbol] key the setting key to override
      # @param [Object] value the new value to set
      def with_pdf_settings(key, value)
        overridden_pdf_settings[key] = Bidi2pdfRails.config.pdf_settings.public_send(key)
        Bidi2pdfRails.config.pdf_settings.public_send("#{key}=", value)
      end

      # Temporarily overrides a lifecycle setting with a new value.
      # The original value is stored for later restoration.
      # @param [Symbol] key the setting key to override
      # @param [Object] value the new value to set
      def with_lifecycle_settings(key, value)
        overridden_lifecycle_settings[key] = Bidi2pdfRails.config.lifecycle_settings.public_send(key)
        Bidi2pdfRails.config.lifecycle_settings.public_send("#{key}=", value)
      end

      # Temporarily overrides a chromedriver setting with a new value.
      # The original value is stored for later restoration.
      # @param [Symbol] key the setting key to override
      # @param [Object] value the new value to set
      def with_chromedriver_settings(key, value)
        overridden_chromedriver_settings[key] = Bidi2pdfRails.config.chromedriver_settings.public_send(key)
        Bidi2pdfRails.config.chromedriver_settings.public_send("#{key}=", value)
      end

      # Temporarily overrides a proxy setting with a new value.
      # The original value is stored for later restoration.
      # @param [Symbol] key the setting key to override
      # @param [Object] value the new value to set
      def with_proxy_settings(key, value)
        overridden_proxy_settings[key] = Bidi2pdfRails.config.proxy_settings.public_send(key)
        Bidi2pdfRails.config.proxy_settings.public_send("#{key}=", value)
      end

      # Retrieves the hash of overridden render settings.
      # @return [Hash] a hash of overridden render settings
      def overridden_render_settings
        @__overridden_render_settings ||= {}
      end

      # Retrieves the hash of overridden PDF settings.
      # @return [Hash] a hash of overridden PDF settings
      def overridden_pdf_settings
        @__overridden_pdf_settings ||= {}
      end

      # Retrieves the hash of overridden lifecycle settings.
      # @return [Hash] a hash of overridden lifecycle settings
      def overridden_lifecycle_settings
        @__overridden_lifecycle_settings ||= {}
      end

      # Retrieves the hash of overridden chromedriver settings.
      # @return [Hash] a hash of overridden chromedriver settings
      def overridden_chromedriver_settings
        @__overridden_chromedriver_settings ||= {}
      end

      # Retrieves the hash of overridden proxy settings.
      # @return [Hash] a hash of overridden proxy settings
      def overridden_proxy_settings
        @__overridden_proxy_settings ||= {}
      end

      # Resets all overridden render settings to their original values.
      # Clears the overridden render settings hash.
      def reset_render_settings
        overridden_render_settings.each do |key, original_value|
          Bidi2pdfRails.config.render_remote_settings.public_send("#{key}=", original_value)
        end

        @__overridden_render_settings = {}
      end

      # Resets all overridden PDF settings to their original values.
      # Clears the overridden PDF settings hash.
      def reset_pdf_settings
        overridden_pdf_settings.each do |key, original_value|
          Bidi2pdfRails.config.pdf_settings.public_send("#{key}=", original_value)
        end

        @__overridden_pdf_settings = {}
      end

      # Resets all overridden lifecycle settings to their original values.
      # Clears the overridden lifecycle settings hash.
      def reset_lifecycle_settings
        overridden_lifecycle_settings.each do |key, original_value|
          Bidi2pdfRails.config.lifecycle_settings.public_send("#{key}=", original_value)
        end

        @__overridden_lifecycle_settings = {}
      end

      # Resets all overridden chromedriver settings to their original values.
      # Clears the overridden chromedriver settings hash.
      def reset_chromedriver_settings
        overridden_chromedriver_settings.each do |key, original_value|
          Bidi2pdfRails.config.chromedriver_settings.public_send("#{key}=", original_value)
        end

        @__overridden_chromedriver_settings = {}
      end

      # Resets all overridden proxy settings to their original values.
      # Clears the overridden proxy settings hash.
      def reset_proxy_settings
        overridden_proxy_settings.each do |key, original_value|
          Bidi2pdfRails.config.proxy_settings.public_send("#{key}=", original_value)
        end

        @__overridden_proxy_settings = {}
      end
    end

    RSpec.configure do |config|
      # Includes the SettingsHelper module in RSpec examples with the `:pdf` metadata.
      config.include SettingsHelper, pdf: true

      # Ensures that overridden settings are reset after each example with the `:pdf` metadata.
      config.after(:each, pdf: true) do
        reset_render_settings if respond_to?(:reset_render_settings)
        reset_pdf_settings if respond_to?(:reset_pdf_settings)
        reset_lifecycle_settings if respond_to?(:reset_lifecycle_settings)
        reset_chromedriver_settings if respond_to?(:reset_chromedriver_settings)
        reset_proxy_settings if respond_to?(:reset_proxy_settings)
      end
    end
  end
end
