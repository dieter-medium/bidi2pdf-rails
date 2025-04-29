# frozen_string_literal: true

#
module Bidi2pdfRails
  module Services
    module AssetHostManager
      Thread.attr_accessor :bidi2pdf_rails_current_asset_host

      class << self
        attr_accessor :original_asset_host

        def override_asset_host!(config)
          self.original_asset_host = config.action_controller.asset_host

          Rails.logger.warn "Overriding asset host #{original_asset_host}" if original_asset_host

          config.action_controller.asset_host = lambda do |source, request|
            thread_host = Thread.current.bidi2pdf_rails_current_asset_host
            if thread_host
              thread_host
            elsif original_asset_host.respond_to?(:call)
              original_asset_host.call(source, request)
            else
              original_asset_host
            end
          end
        end

        def set_current_asset_host(host_from_options, fallback_host_from_request)
          Thread.current.bidi2pdf_rails_current_asset_host = if host_from_options
                                                               host_from_options
                                                             elsif self.original_asset_host
                                                               self.original_asset_host
                                                             else
                                                               fallback_host_from_request
                                                             end
        end
      end
    end
  end
end
