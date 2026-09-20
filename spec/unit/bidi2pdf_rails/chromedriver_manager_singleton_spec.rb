# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bidi2pdfRails::ChromedriverManagerSingleton, :pdf do
  # Bidi2pdf::SessionWarmer.configure eagerly pre-warms real Chrome sessions - stub it so this stays
  # a unit spec, but yield a REAL Configuration so a renamed/removed upstream attribute fails this
  # spec instead of silently passing against a loose double.
  let(:warmer_config) { Bidi2pdf::SessionWarmer::Configuration.new }
  let(:fake_logger) { instance_double(Logger, info: nil, warn: nil) }

  before do
    allow(Bidi2pdf::SessionWarmer).to receive(:configure).and_yield(warmer_config)
    allow(Bidi2pdf::SessionWarmer).to receive(:shutdown)
    allow(Bidi2pdfRails).to receive(:logger).and_return(fake_logger)

    with_session_warmer_settings(:enabled, true)
  end

  after do
    described_class.shutdown
  end

  describe "#initialize_manager" do
    it "hands session_warmer_settings.size through to the warmer configuration" do
      with_session_warmer_settings(:size, 3)

      described_class.initialize_manager(force: true)

      expect(warmer_config.size).to eq(3)
    end

    it "hands session_warmer_settings.max_idle_age through to the warmer configuration" do
      with_session_warmer_settings(:max_idle_age, 42)

      described_class.initialize_manager(force: true)

      expect(warmer_config.max_idle_age).to eq(42)
    end

    it "hands general_options.headless through to the warmer configuration" do
      # No settings-helper pair covers general_options (see settings_helper.rb) - save/restore
      # directly, matching bidi2pdf_rails_spec.rb's own pattern for this same config group.
      original_headless = Bidi2pdfRails.config.general_options.headless
      Bidi2pdfRails.config.general_options.headless = false

      begin
        described_class.initialize_manager(force: true)

        expect(warmer_config.headless).to eq(false)
      ensure
        Bidi2pdfRails.config.general_options.headless = original_headless
      end
    end

    it "hands general_options.chrome_session_args through to the warmer configuration" do
      described_class.initialize_manager(force: true)

      expect(warmer_config.chrome_args).to eq(Bidi2pdfRails.config.general_options.chrome_session_args_value)
    end

    it "leaves remote_browser_url unset when no remote browser is configured" do
      described_class.initialize_manager(force: true)

      expect(warmer_config.remote_browser_url).to be_nil
    end

    it "sets remote_browser_url when a remote browser is configured" do
      with_render_setting(:browser_url, "http://remote-chrome:3000/session")

      described_class.initialize_manager(force: true)

      expect(warmer_config.remote_browser_url).to eq("http://remote-chrome:3000/session")
    end

    it "configures the warmer only once across repeated calls" do
      described_class.initialize_manager(force: true)
      described_class.initialize_manager(force: true)

      expect(Bidi2pdf::SessionWarmer).to have_received(:configure).once
    end

    it "warns instead of silently ignoring a settings change made after boot" do
      described_class.initialize_manager(force: true)
      with_session_warmer_settings(:size, 99)

      described_class.initialize_manager(force: true)

      expect(fake_logger).to have_received(:warn).with(/boot-time immutable/)
    end

    it "does not warn when settings are unchanged across repeated calls" do
      described_class.initialize_manager(force: true)

      described_class.initialize_manager(force: true)

      expect(fake_logger).not_to have_received(:warn)
    end

    it "raises when chromedriver_settings.port is non-zero" do
      with_chromedriver_settings(:port, 9515)

      expect { described_class.initialize_manager(force: true) }.to raise_error(ArgumentError, /chromedriver_settings\.port/)
    end

    it "does not configure the warmer when the port is rejected" do
      with_chromedriver_settings(:port, 9515)

      described_class.initialize_manager(force: true)
    rescue ArgumentError
      expect(Bidi2pdf::SessionWarmer).not_to have_received(:configure)
    end
  end

  describe "#shutdown" do
    it "shuts down the warmer that was actually initialized, even if the setting is flipped off first" do
      described_class.initialize_manager(force: true)
      with_session_warmer_settings(:enabled, false)

      described_class.shutdown

      expect(Bidi2pdf::SessionWarmer).to have_received(:shutdown)
    end
  end
end
