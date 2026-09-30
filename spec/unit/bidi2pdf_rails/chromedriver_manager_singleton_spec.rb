# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bidi2pdfRails::ChromedriverManagerSingleton, :pdf do
  # Bidi2pdf::SessionWarmer.configure eagerly pre-warms real Chrome sessions - stub it so this stays
  # a unit spec, but yield a REAL Configuration so a renamed/removed upstream attribute fails this
  # spec instead of silently passing against a loose double.
  let(:warmer_config) { Bidi2pdf::SessionWarmer::Configuration.new }
  let(:fake_logger) { instance_double(Logger, info: nil, warn: nil) }

  before do
    # Before the stubs on purpose: whatever an earlier spec file left running gets a real teardown.
    described_class.shutdown(force: true)

    allow(Bidi2pdf::SessionWarmer).to receive(:configure).and_yield(warmer_config)
    allow(Bidi2pdf::SessionWarmer).to receive(:shutdown)
    allow(Bidi2pdfRails).to receive(:logger).and_return(fake_logger)

    with_session_warmer_settings(:enabled, true)
  end

  # force: true - outside a server process a plain #shutdown returns early, and the state this
  # module keeps would leak into the next example.
  after do
    described_class.shutdown(force: true)
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

        expect(warmer_config.headless).to be(false)
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

    context "with a remote browser and sweeping on" do
      before do
        with_render_setting(:browser_url, "http://remote-chrome:3000/session")
        with_sweeper_settings(:enabled, true)
        with_sweeper_settings(:registry_dir, "/tmp/bidi2pdf-shared")
      end

      it "hands the sweeper rules to the warmer, so it sweeps and retries when a session is refused" do
        described_class.initialize_manager(force: true)

        expect(warmer_config.sweeper).to eq(Bidi2pdfRails::ChromeSweeping.options)
      end

      it "hands the shared registry directory to the warmer" do
        described_class.initialize_manager(force: true)

        expect(warmer_config.registry_dir).to eq("/tmp/bidi2pdf-shared")
      end
    end

    context "with a remote browser, sweeping on and retry_on_failure off" do
      before do
        with_render_setting(:browser_url, "http://remote-chrome:3000/session")
        with_sweeper_settings(:enabled, true)
        with_sweeper_settings(:retry_on_failure, false)
      end

      it "gives the warmer no sweeper, so it does not retry a refused session either" do
        described_class.initialize_manager(force: true)

        expect(warmer_config.sweeper).to be_nil
      end
    end

    it "gives the warmer no sweeper while sweeping is off" do
      with_render_setting(:browser_url, "http://remote-chrome:3000/session")

      described_class.initialize_manager(force: true)

      expect(warmer_config.sweeper).to be_nil
    end

    # The railtie calls #initialize_manager from two on_load hooks, without force.
    context "when a server process calls it a second time" do
      before do
        allow(described_class).to receive(:running_as_server?).and_return(true)
        described_class.initialize_manager
      end

      it "configures the warmer only once" do
        described_class.initialize_manager

        expect(Bidi2pdf::SessionWarmer).to have_received(:configure).once
      end

      it "warns instead of silently ignoring a settings change made after boot" do
        with_session_warmer_settings(:size, 99)

        described_class.initialize_manager

        expect(fake_logger).to have_received(:warn).with(/boot-time immutable/)
      end

      it "does not warn when the settings are unchanged" do
        described_class.initialize_manager

        expect(fake_logger).not_to have_received(:warn)
      end
    end

    context "when it is forced a second time" do
      before { described_class.initialize_manager(force: true) }

      it "shuts the running warmer down before configuring a new one" do
        described_class.initialize_manager(force: true)

        expect(Bidi2pdf::SessionWarmer).to have_received(:shutdown).once
      end

      it "applies the settings of the second call" do
        with_session_warmer_settings(:size, 5)

        described_class.initialize_manager(force: true)

        expect(warmer_config.size).to eq(5)
      end
    end

    context "with the session warmer disabled" do
      let(:manager) { instance_double(Bidi2pdf::ChromedriverManager, start: nil, stop: nil) }

      before do
        with_session_warmer_settings(:enabled, false)
        allow(Bidi2pdf::ChromedriverManager).to receive(:new).and_return(manager)
        allow(described_class).to receive(:running_as_server?).and_return(true)
      end

      it "starts only one chromedriver when both on_load hooks call it" do
        2.times { described_class.initialize_manager }

        expect(Bidi2pdf::ChromedriverManager).to have_received(:new).once
      end
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

  describe "#session with a remote browser" do
    let(:remote_session) { instance_double(Bidi2pdf::Bidi::Session, start: nil, close: nil, client: instance_double(Bidi2pdf::Bidi::Client, on_close: nil)) }

    before do
      with_session_warmer_settings(:enabled, false)
      with_render_setting(:browser_url, "http://remote-chrome:3000/session")
      allow(Bidi2pdf::Bidi::Session).to receive(:new).and_return(remote_session)
    end

    after { described_class.session_close }

    # A session nobody leases is fair game for another process's sweeper - even mid-render.
    it "leases the session in the registry while it is open" do
      described_class.session

      expect(Bidi2pdf::Bidi::Session).to have_received(:new).with(hash_including(registry: an_instance_of(Bidi2pdf::SessionRegistry)))
    end
  end

  describe "#shutdown" do
    it "shuts down the warmer that was actually initialized, even if the setting is flipped off first" do
      described_class.initialize_manager(force: true)
      with_session_warmer_settings(:enabled, false)

      described_class.shutdown(force: true)

      expect(Bidi2pdf::SessionWarmer).to have_received(:shutdown)
    end

    it "does nothing outside a server process unless forced" do
      described_class.initialize_manager(force: true)

      described_class.shutdown

      expect(Bidi2pdf::SessionWarmer).not_to have_received(:shutdown)
    end
  end

  # What the render path branches on - the setting alone is not enough.
  describe "#session_warmer_active?" do
    it "is false while the warmer is only enabled, not initialized" do
      expect(described_class).not_to be_session_warmer_active
    end

    it "is true once the warmer was initialized" do
      described_class.initialize_manager(force: true)

      expect(described_class).to be_session_warmer_active
    end

    it "stays true when the setting is flipped off after boot" do
      described_class.initialize_manager(force: true)
      with_session_warmer_settings(:enabled, false)

      expect(described_class).to be_session_warmer_active
    end

    it "is false again after shutdown" do
      described_class.initialize_manager(force: true)
      described_class.shutdown(force: true)

      expect(described_class).not_to be_session_warmer_active
    end
  end
end
