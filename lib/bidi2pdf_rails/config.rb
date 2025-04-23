# frozen_string_literal: true

require_relative "configurable"

module Bidi2pdfRails
  class Config
    include Bidi2pdfRails::Configurable

    CONFIG_OPTIONS = {
      general_options: {
        name: "General Options",
        ask: "Configure general options? (y/n)",
        options: [
          { name: :logger, desc: "The logger", default: -> { Rails.logger || ActiveSupport::TaggedLogging.new(Logger.new(nil)) }, default_as_str: "Rails.logger", ask: false, color: :yellow },
          { name: :verbosity, desc: "How verbose to be", default: Bidi2pdf::VerboseLogger::VERBOSITY_LEVELS.keys.sort_by { |k| Bidi2pdf::VerboseLogger::VERBOSITY_LEVELS[k] }.first.to_s, limited_to: Bidi2pdf::VerboseLogger::VERBOSITY_LEVELS.keys.sort_by { |k| Bidi2pdf::VerboseLogger::VERBOSITY_LEVELS[k] }.map(&:to_s), ask: true, color: :yellow },
          { name: :headless, desc: "Run Chrome in headless mode", default: -> { !Rails.env.development? }, default_as_str: "!Rails.env.development?", ask: true, color: :green },
          { name: :wait_for_network_idle, desc: "Wait for network idle", default: true, ask: true, color: :green },
          { name: :wait_for_page_loaded, desc: "Wait for page loaded", default: false, ask: true, color: :green },
          { name: :wait_for_page_check_script, desc: "Wait for page check script", default: nil, ask: false },
          { name: :notification_service, desc: "Notification service", default: -> { ActiveSupport::Notifications }, default_as_str: "-> { ActiveSupport::Notifications }", ask: false },
          { name: :default_timeout, desc: "Default timeout for various Bidi commands", default: 10, ask: true, color: :yellow },
          { name: :chrome_session_args, desc: "Chrome session arguments", default: Bidi2pdf::Bidi::Session::DEFAULT_CHROME_ARGS, ask: false }
        ]
      },

      chromedriver_settings: {
        name: "Chromedriver Settings (when chromedriver run within your app)",
        ask: "Configure chromedriver settings? (y/n)",
        options: [
          { name: :install_dir, desc: "Chromedriver install directory", default: nil, ask: false, color: :yellow },
          { name: :port, desc: "Chromedriver port", default: 0, ask: true, color: :yellow }
        ]
      },

      proxy_settings: {
        name: "Proxy Settings",
        ask: "Use a proxy server? (y/n)",
        options: [
          { name: :addr, desc: "Proxy address (e.g., 127.0.0.1)", default: nil, ask: true, color: :yellow },
          { name: :port, desc: "Proxy port (e.g., 8080)", default: nil, ask: true, color: :yellow },
          { name: :user, desc: "Proxy user", default: nil, ask: true, color: :yellow },
          {
            name: :pass,
            desc: "Proxy password",
            default: -> { -> { Rails.application.credentials.dig("bidi2pdf_rails", "proxy_pass") } },
            default_as_str: "-> { Rails.application.credentials.dig('bidi2pdf_rails', 'proxy_pass') }",
            secret: true,
            ask: true,
            color: :yellow
          }
        ]
      },

      pdf_settings: {
        name: "PDF Settings",
        ask: "Configure custom PDF settings? (y/n)",
        options: [
          { name: :orientation, desc: "PDF orientation (portrait/landscape)", default: "portrait", limited_to: %w[portrait landscape], ask: true },
          { name: :margins, desc: "Configure PDF margins?", default: false, ask: true, color: :green },
          { name: :margin_top, desc: "PDF margin top (cm)", default: 2.5, ask: true, color: :yellow },
          { name: :margin_bottom, desc: "PDF margin bottom (cm)", default: 2, ask: true, color: :yellow },
          { name: :margin_left, desc: "PDF margin left (cm)", default: 2, ask: true, color: :yellow },
          { name: :margin_right, desc: "PDF margin right (cm)", default: 2, ask: true, color: :yellow },
          { name: :page_format, desc: "PDF page format (e.g., A4)", default: nil, limited_to: Bidi2pdf::PAPER_FORMATS_CM.keys.map(&:to_s), ask: true },
          { name: :page_width, desc: "PDF page width (cm, not needed when format is specified)", default: Bidi2pdf::PAPER_FORMATS_CM[:a4][:width], ask: true, color: :yellow },
          { name: :page_height, desc: "PDF page height (cm, not needed when format is specified)", default: Bidi2pdf::PAPER_FORMATS_CM[:a4][:height], ask: true, color: :yellow },
          { name: :print_background, desc: "Print background graphics?", default: true, ask: true, color: :green },
          { name: :scale, desc: "PDF scale (e.g., 1.0)", default: 1.0, ask: true, color: :yellow },
          { name: :shrink_to_fit, desc: "Shrink to fit?", default: false, ask: true, color: :green },
          { name: :custom_js, desc: "Raw JavaScript code to inject before PDF generation (without <script> tags)", default: nil, ask: false, color: :yellow },
          { name: :custom_css, desc: "Raw CSS styles to inject before PDF generation (without <style> tags)", default: nil, ask: false, color: :yellow },
          { name: :custom_js_url, desc: "URL to JavaScript file to load before PDF generation", default: nil, ask: false, color: :yellow },
          { name: :custom_css_url, desc: "URL to CSS file to load before PDF generation", default: nil, ask: false, color: :yellow }
        ]
      },

      render_remote_settings: {
        name: "Remote URL Settings",
        ask: false,
        options: [
          { name: :browser_url, desc: "Remote browser URL (e.g. http://localhost:3001/sesion)", default: nil, ask: true, color: :yellow },
          { name: :basic_auth_user, desc: "Basic auth user", default: nil },
          { name: :basic_auth_pass, desc: "Basic auth password", default: nil, default_as_str: "-> { Rails.application.credentials.dig('bidi2pdf_rails', 'basic_auth_pass') }", secret: true },
          { name: :headers, desc: "Headers to be send when allong an url", default: {}, default_as_str: '{"X-API-INFO" => "my info"}' },
          { name: :cookies, desc: "Cookies to be send when alling an url", default: {}, default_as_str: '{"session_id" => "my session"}' }
        ]
      },

      lifecycle_settings: {
        name: "Lifecycle Settings",
        ask: false,
        options: [
          { name: :before_navigate, desc: "Hook to be called before navigating to a URL", default: nil, default_as_str: '->(url_or_content, browser_tab, filename, controller) { Rails.logger.info "Navigating to #{url_or_content}" }', ask: false },
          { name: :after_navigate, desc: "Hook to be called after navigating to a URL", default: nil, default_as_str: '->(url_or_content, browser_tab, filename, controller) { Rails.logger.info "Navigated to #{url_or_content}" }', ask: false },
          { name: :after_wait_for_tab, desc: "Hook to be called after waiting for a tab  (when waiting is enabled)", default: nil, default_as_str: '->(url_or_content, browser_tab, filename, controller) { Rails.logger.info "Waited for #{url_or_content}" }', ask: false },
          { name: :after_print, desc: "Hook to be called after printing, needs to return the pdf-binary-content. Here you can store the content into a file, sign it, or add meta data.", default: nil, default_as_str: '->(url_or_content, browser_tab, binary_pdf_content, filename, controller) { Rails.logger.info "Printed #{url_or_content}"; binary_pdf_content }', ask: false }
        ]
      }

    }.freeze

    configure_with(CONFIG_OPTIONS)

    def initialize
      reset_to_defaults!
    end

    def pdf_settings_for_bidi_cmd(overrides = {})
      overrides ||= {}
      opts = {}

      opts[:background] = pdf_settings.print_background_value
      opts[:orientation] = pdf_settings.orientation_value
      opts[:scale] = pdf_settings.scale_value
      opts[:shrinkToFit] = pdf_settings.shrink_to_fit_value

      # Margins
      margins = {
        top: pdf_settings.margin_top_value,
        bottom: pdf_settings.margin_bottom_value,
        left: pdf_settings.margin_left_value,
        right: pdf_settings.margin_right_value
      }.compact

      opts[:margin] = margins unless margins.empty?

      # Page size
      page = {
        width: pdf_settings.page_width_value,
        height: pdf_settings.page_height_value,
        format: pdf_settings.page_format_value
      }.compact

      page = overrides[:page].compact if overrides[:page]&.compact.present?
      page = { format: page[:format] } if page[:format]

      opts[:page] = page unless page.empty?

      opts.deep_merge(overrides).compact
    end

    def validate_print_options!
      validator = Bidi2pdf::Bidi::Commands::PrintParametersValidator.new(pdf_settings_for_bidi_cmd)

      validator.validate!
    end
  end
end
