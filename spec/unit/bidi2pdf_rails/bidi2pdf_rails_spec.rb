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
end
