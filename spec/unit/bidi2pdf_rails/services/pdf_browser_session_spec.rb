# frozen_string_literal: true

require_relative "../../../rails_helper"

# The path without the session warmer sets its session up - request to first tab - under one turn of bidi2pdf's
# session start limit (Bidi2pdf::SessionGate, bidi2pdf 0.1.26).
RSpec.describe Bidi2pdfRails::Services::PdfBrowserSession,
               skip: (defined?(Bidi2pdf::SessionGate) ? false : "this bidi2pdf has no session start limit (0.1.26 and later)") do
  let(:tab) { instance_double(Bidi2pdf::Bidi::BrowserTab, close: nil) }
  let(:window) { instance_double(Bidi2pdf::Bidi::BrowserTab, create_browser_tab: tab, close: nil) }
  let(:context) { instance_double(Bidi2pdf::Bidi::UserContext, create_browser_window: window, close: nil) }
  let(:browser) { instance_double(Bidi2pdf::Bidi::Browser, create_user_context: context) }
  let(:session) { instance_double(Bidi2pdf::Bidi::Session, browser: browser) }

  let(:renderer) do
    Class.new do
      include Bidi2pdfRails::Services::PdfBrowserSession

      def render = run_with_chromedriver_manager_singleton

      def print_and_notify(_tab) = :printed
    end.new
  end

  before do
    allow(Bidi2pdfRails::ChromedriverManagerSingleton).to receive_messages(session: session, session_close: nil)
  end

  around do |example|
    limit = Bidi2pdf.session_start_concurrency
    timeout = Bidi2pdf.session_start_timeout
    Bidi2pdf.session_start_concurrency = 1
    Bidi2pdf.session_start_timeout = 0.1
    Bidi2pdf::SessionGate.reset!
    example.run
  ensure
    Bidi2pdf.session_start_concurrency = limit
    Bidi2pdf.session_start_timeout = timeout
    Bidi2pdf::SessionGate.reset!
  end

  it "renders when a permit is free" do
    expect(renderer.render).to eq(:printed)
  end

  # Holds the only permit until the block is done - the holder says when it has it, so the render cannot get there
  # first (a sleep could not promise that under CI load; review of PR #32).
  def while_every_permit_is_taken
    held = Thread::Queue.new
    done = Thread::Queue.new
    holder = Thread.new do
      Bidi2pdf::SessionGate.with_permit do
        held << true
        done.pop
      end
    end
    held.pop
    yield
  ensure
    done << true
    holder&.join
  end

  it "fails with SessionStartTimeoutError while every permit is taken" do
    while_every_permit_is_taken do
      expect { renderer.render }.to raise_error(Bidi2pdf::SessionStartTimeoutError)
    end
  end

  it "opens no tab while every permit is taken" do
    while_every_permit_is_taken do
      renderer.render
    rescue Bidi2pdf::SessionStartTimeoutError
      nil
    end

    expect(browser).not_to have_received(:create_user_context)
  end
end
