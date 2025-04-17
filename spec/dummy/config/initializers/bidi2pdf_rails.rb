# frozen_string_literal: true

Bidi2pdfRails.configure do |config|
  overrides = Rails.application.config.x.bidi2pdf_rails

  config.notification_service = ActiveSupport::Notifications

  config.logger = Rails.logger
  config.verbosity = overrides.verbosity.nil? ? :none : overrides.verbosity
  config.default_timeout = 10

  # Logging options
  config.log_network_events = false
  config.log_browser_console = false

  # Chrome & BiDi
  # config.remote_browser_url = nil
  config.headless = overrides.headless.nil? ? false : overrides.headless
  # config.chromedriver_port = 0
  # config.chrome_session_args = [
  #   "--disable-gpu",
  #   "--no-sandbox"
  # ]

  # config.proxy_addr = nil
  # config.proxy_port = nil
  # config.proxy_user = nil
  # config.proxy_pass = nil

  # Viewport settings
  # config.viewport_width = 1920
  # config.viewport_height = 1080

  # PDF settings
  # config.pdf_orientation = "portrait"
  # config.pdf_margin_top = 10
  # config.pdf_margin_bottom = 10
  # config.pdf_margin_left = 10
  # config.pdf_margin_right = 10
  # config.pdf_print_background = true
  # config.pdf_scale = 1.0

  # config.cookies = [
  #   { name: "session", value: "abc123", domain: "example.com" }
  # ]

  # config.headers = {
  #   "X-API-KEY" => "topsecret"
  # }

  # config.auth = {
  #   username: "admin",
  #   password: "secret"
  # }

  # chromedriver install dir
  # config.install_dir = Rails.root.join("tmp", "bidi2pdf").to_s
end

Rails.application.config.after_initialize do
  Bidi2pdfRails::MainLogSubscriber.attach_to "bidi2pdf", inherit_all: true # needed for imported methods
  Bidi2pdfRails::BrowserConsoleLogSubscriber.attach_to "bidi2pdf"
  Bidi2pdfRails::NetworkLogSubscriber.attach_to "bidi2pdf"

  Bidi2pdfRails::MainLogSubscriber.silence /network_event_.*\.bidi2pdf/
end
