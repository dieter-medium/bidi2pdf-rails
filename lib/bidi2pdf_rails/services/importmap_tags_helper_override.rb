# frozen_string_literal: true

module Bidi2pdfRails
  module Services
    module ImportmapTagsHelperOverride
      def javascript_importmap_tags(*args, **opts, &block)
        def javascript_importmap_tags(entry_point = "application", importmap: Rails.application.importmap)
          safe_join [
                      javascript_inline_importmap_tag(importmap.to_json(resolver: self, cache_key: cache_key)),
                      javascript_importmap_module_preload_tags(importmap, entry_point:),
                      javascript_import_module_tag(entry_point)
                    ], "\n"
        end

        def cache_key
          asset_host = self.controller.asset_host.respond_to?(:call) ? self.controller.asset_host.call(nil, self.controller.request) : self.controller.asset_host

          asset_host || :json
        end

        def javascript_importmap_module_preload_tags(importmap = Rails.application.importmap, entry_point: "application")
          javascript_module_preload_tag(*importmap.preloaded_module_paths(resolver: self, entry_point:, cache_key: "#{entry_point}-#{cache_key}"))
        end
      end
    end
  end
end
