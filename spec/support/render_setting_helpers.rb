# frozen_string_literal: true

#
module RenderSettingHelpers
  def with_render_setting(key, value)
    overridden_render_settings[key] = Bidi2pdfRails.config.render_remote_settings.public_send(key)
    Bidi2pdfRails.config.render_remote_settings.public_send("#{key}=", value)
  end

  def overridden_render_settings
    @__overridden_render_settings ||= {}
  end

  def reset_render_settings
    overridden_render_settings.each do |key, original_value|
      Bidi2pdfRails.config.render_remote_settings.public_send("#{key}=", original_value)
    end
    @__overridden_render_settings = {}
  end
end

RSpec.configure do |config|
  config.include RenderSettingHelpers, type: :request

  config.after(:each, type: :request) do
    reset_render_settings if defined?(reset_render_settings)
  end
end
