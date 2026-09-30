# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bidi2pdfRails::ChromeSweeping, :pdf do
  # Nothing listens there: a sweep fails open at once (logged, in Result#errors), which is all
  # these examples need from the chromedriver.
  let(:browser_url) { "http://127.0.0.1:1/session" }
  let(:registry_dir) { Dir.mktmpdir }

  before do
    with_render_setting(:browser_url, browser_url)
    with_sweeper_settings(:registry_dir, registry_dir)
  end

  after do
    described_class.stop
    FileUtils.rm_rf(registry_dir)
  end

  def a_render_failing_once(error)
    attempts = 0
    lambda do
      attempts += 1
      raise error if attempts == 1

      :rendered
    end
  end

  describe "the session registry" do
    it "leases remote sessions in the configured directory" do
      expect(described_class.registry.path).to start_with(registry_dir)
    end

    it "does not exist without a remote browser" do
      with_render_setting(:browser_url, nil)

      expect(described_class.registry).to be_nil
    end
  end

  describe "the sweeper settings" do
    it "turns the scope into the sweeper's symbol" do
      with_sweeper_settings(:scope, "all")

      expect(described_class.options[:scope]).to eq(:all)
    end

    it "derives the session limit from the pids limit with \"auto\"" do
      with_sweeper_settings(:max_sessions, "auto")

      expect(described_class.options[:max_sessions]).to eq(:auto)
    end

    it "takes a numeric session limit as a count" do
      with_sweeper_settings(:max_sessions, "3")

      expect(described_class.options[:max_sessions]).to eq(3)
    end

    it "passes the rules through unchanged" do
      with_sweeper_settings(:orphan_age, 900)

      expect(described_class.options).to include(orphan_age: 900, registry_dir: registry_dir)
    end
  end

  describe "the per-process sweeper" do
    it "does not exist while sweeping is off" do
      expect(described_class.sweeper).to be_nil
    end

    it "does not exist without a remote browser" do
      with_sweeper_settings(:enabled, true)
      with_render_setting(:browser_url, nil)

      expect(described_class.sweeper).to be_nil
    end

    it "is built once per process" do
      with_sweeper_settings(:enabled, true)

      expect(described_class.sweeper).to equal(described_class.sweeper)
    end

    it "sweeps every sweeper_settings.interval seconds" do
      with_sweeper_settings(:enabled, true)
      with_sweeper_settings(:interval, 3600)

      expect(described_class.sweeper.interval).to eq(3600)
    end

    it "is built anew in a forked child - the parent's thread does not survive a fork" do
      with_sweeper_settings(:enabled, true)
      parent = described_class.sweeper

      pid = fork { exit!(described_class.sweeper.equal?(parent) ? 1 : 0) }
      Process.wait(pid)

      expect(Process.last_status.exitstatus).to eq(0)
    end
  end

  describe "retrying a failed render" do
    before { with_sweeper_settings(:enabled, true) }

    it "runs the render once more after a resource error" do
      render = a_render_failing_once(Bidi2pdf::SessionNotStartedError.new("session not created"))

      expect(described_class.with_retry { render.call }).to eq(:rendered)
    end

    it "does not retry with retry_on_failure off" do
      with_sweeper_settings(:retry_on_failure, false)
      render = a_render_failing_once(Bidi2pdf::SessionNotStartedError.new("session not created"))

      expect { described_class.with_retry { render.call } }.to raise_error(Bidi2pdf::SessionNotStartedError)
    end

    it "does not retry while sweeping is off" do
      with_sweeper_settings(:enabled, false)
      render = a_render_failing_once(Bidi2pdf::SessionNotStartedError.new("session not created"))

      expect { described_class.with_retry { render.call } }.to raise_error(Bidi2pdf::SessionNotStartedError)
    end

    it "leaves a refused session to the warmer, which already swept and retried for it" do
      allow(Bidi2pdfRails::ChromedriverManagerSingleton).to receive(:session_warmer_active?).and_return(true)
      render = a_render_failing_once(Bidi2pdf::SessionNotStartedError.new("session not created"))

      expect { described_class.with_retry { render.call } }.to raise_error(Bidi2pdf::SessionNotStartedError)
    end

    it "retries a Chrome that died mid-render with the warmer too" do
      allow(Bidi2pdfRails::ChromedriverManagerSingleton).to receive(:session_warmer_active?).and_return(true)
      render = a_render_failing_once(Bidi2pdf::WebsocketError.new("connection closed"))

      expect(described_class.with_retry { render.call }).to eq(:rendered)
    end

    it "does not retry an error the page caused" do
      error = Bidi2pdf::NavigationError.new("page not found")

      expect { described_class.with_retry { raise error } }.to raise_error(Bidi2pdf::NavigationError)
    end
  end

  describe "sweeping on demand" do
    it "needs a remote browser" do
      with_render_setting(:browser_url, nil)

      expect { described_class.sweep! }.to raise_error(ArgumentError, /browser_url/)
    end

    it "works while automatic sweeping is off and never raises for an unreachable chromedriver" do
      expect(described_class.sweep!(dry_run: true).errors).not_to be_empty
    end
  end

  it "is reachable as Bidi2pdfRails.sweep_sessions!" do
    expect(Bidi2pdfRails.sweep_sessions!(dry_run: true)).to be_a(Bidi2pdf::ChromeSweeper::Result)
  end
end
