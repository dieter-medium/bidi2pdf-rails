# frozen_string_literal: true

#
module Bidi2pdfRails
  module Services
    module AssetHostManager
      Thread.attr_accessor :bidi2pdf_rails_current_asset_host, :bidi2pdf_rails_current_importmap

      class << self
        attr_accessor :original_asset_host

        # this method has to be called within the initializer block or environment files
        # to ensure that the asset host is overridden before any assets gems are loaded and
        # copy the asset host from the config e.g. propshaft-rails, importmap-rails ...
        def override_asset_host!(config)
          self.original_asset_host = config.action_controller.asset_host

          Bidi2pdfRails.logger.warn "Overriding asset host #{original_asset_host}" if original_asset_host

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

          Bidi2pdfRails.logger.info "Setting asset host to #{host_from_options || fallback_host_from_request} chosen #{Thread.current.bidi2pdf_rails_current_asset_host}"

          if defined?(Importmap::Map)
            Thread.current.bidi2pdf_rails_current_importmap = Importmap::Map.new

            Rails.application.config.importmap.each_pin do |pin|
              Thread.current.bidi2pdf_rails_current_importmap.pin(pin.name, to: pin.to, preload: pin.preload)
            end
          end
        end

        def reset_asset_host
          Thread.current.bidi2pdf_rails_current_asset_host = nil
          Thread.current.bidi2pdf_rails_current_importmap = nil
        end

        def pdf_aware_import_map
          Thread.current.bidi2pdf_rails_current_importmap || Rails.application.config.importmap
        end
      end
    end
  end
end
