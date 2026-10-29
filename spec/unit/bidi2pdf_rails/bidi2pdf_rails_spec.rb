# frozen_string_literal: true

require_relative "../../rails_helper"

RSpec.describe Bidi2pdfRails do
  it "has a version number" do
    expect(Bidi2pdfRails::VERSION).not_to be_nil
  end

  # bidi2pdf 0.1.15 settings. apply_bidi2pdf_config owns the Bidi2pdf.configure call, so these are
  # only reachable for an app if Bidi2pdfRails hands them through.
  describe ".apply_bidi2pdf_config" do
    around do |example|
      log_level = described_class.config.chromedriver_settings.log_level
      truncate_limit = described_class.config.general_options.log_truncate_limit
      example.run
    ensure
      described_class.config.chromedriver_settings.log_level = log_level
      described_class.config.general_options.log_truncate_limit = truncate_limit
      described_class.apply_bidi2pdf_config
    end

    it "leaves chromedriver's log level following the logger by default" do
      described_class.apply_bidi2pdf_config

      expect(Bidi2pdf.chromedriver_log_level).to be_nil
    end

    it "hands chromedriver_settings.log_level through to bidi2pdf" do
      described_class.config.chromedriver_settings.log_level = "WARNING"
      described_class.apply_bidi2pdf_config

      expect(Bidi2pdf.chromedriver_log_level).to eq("WARNING")
    end

    it "defaults log_truncate_limit to bidi2pdf's own default" do
      described_class.apply_bidi2pdf_config

      expect(Bidi2pdf.log_truncate_limit).to eq(200)
    end

    it "hands general_options.log_truncate_limit through to bidi2pdf" do
      described_class.config.general_options.log_truncate_limit = 50
      described_class.apply_bidi2pdf_config

      expect(Bidi2pdf.log_truncate_limit).to eq(50)
    end
  end

  # bidi2pdf 0.1.26: the session start limit (README "Session start limit" in bidi2pdf).
  describe ".apply_bidi2pdf_config with the session start limit",
           skip: (Bidi2pdf.respond_to?(:session_start_concurrency=) ? false : "this bidi2pdf has no session start limit (0.1.26 and later)") do
    around do |example|
      options = described_class.config.general_options
      limit = options.session_start_concurrency
      timeout = options.session_start_timeout
      example.run
    ensure
      options.session_start_concurrency = limit
      options.session_start_timeout = timeout
      described_class.apply_bidi2pdf_config
    end

    it "allows two session setups at once by default, like bidi2pdf" do
      described_class.apply_bidi2pdf_config

      expect(Bidi2pdf.session_start_concurrency).to eq(2)
    end

    it "hands general_options.session_start_concurrency and session_start_timeout through to bidi2pdf" do
      described_class.config.general_options.session_start_concurrency = 1
      described_class.config.general_options.session_start_timeout = 5
      described_class.apply_bidi2pdf_config

      expect([Bidi2pdf.session_start_concurrency, Bidi2pdf.session_start_timeout]).to eq([1, 5])
    end
  end
end
