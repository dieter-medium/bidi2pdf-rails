# frozen_string_literal: true

require "rails_helper"
require "bidi2pdf/test_helpers/testcontainers"

# The remote-chromedriver connection setup mirrors
# user_can_render_with_a_warm_session_using_remote_chromedriver_spec.rb - see there for why it is
# duplicated instead of shared.
RSpec.feature "As an operator, I want Chrome sessions left behind on the remote browser closed", :chromedriver, :pdf, type: :request do
  def reachable?(url, timeout: 2)
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, open_timeout: timeout, read_timeout: timeout) do |http|
      http.get(uri.request_uri).is_a?(Net::HTTPSuccess)
    end
  rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Net::OpenTimeout, Net::ReadTimeout
    false
  end

  def remote_session_url
    url = session_url
    port = chromedriver_container.mapped_port(chromedriver_container.port)
    url = "http://remote-chrome:#{port}/session" unless chromedriver_container.host
    url = "http://127.0.0.1:#{port}/session" unless reachable?(url.sub(%r{/session\z}, "/status"))
    url
  end

  def open_session_ids = Bidi2pdf::ChromedriverApi.new(@browser_url).sessions.map(&:id)

  before do
    @browser_url = remote_session_url
    @registry_dir = Dir.mktmpdir("bidi2pdf-rails-sweeper")

    with_render_setting :browser_url, @browser_url
    with_sweeper_settings :enabled, true
    with_sweeper_settings :scope, "all"
    with_sweeper_settings :min_age, 0
    with_sweeper_settings :registry_dir, @registry_dir

    Bidi2pdfRails::ChromedriverManagerSingleton.initialize_manager force: true
  end

  after do
    Bidi2pdfRails::ChromedriverManagerSingleton.shutdown force: true
    FileUtils.rm_rf(@registry_dir)
  end

  scenario "Rendering with the sweeper on" do
    when_ "I visit the PDF version of a report" do
      before do
        @response = get_pdf_response "/convert-remote-url"
      end

      then_ "I receive a successful HTTP response" do
        expect(@response.code).to eq("200")
      end

      and_ "the render's session is gone from the registry once it closed" do
        expect(Bidi2pdf::SessionRegistry.new(@browser_url, dir: @registry_dir).recorded).to be_empty
      end
    end
  end

  scenario "A session nobody holds any more" do
    when_ "a session was left open by a process that is gone" do
      before do
        @leaked = Bidi2pdf::Bidi::Session.new(session_url: @browser_url, chrome_args: Bidi2pdfRails.config.general_options.chrome_session_args_value)
        @leaked.start
        @leaked.browser
      end

      after do
        Bidi2pdf::ChromedriverApi.new(@browser_url).delete_session(@leaked.session_id)
      end

      then_ "a last-resort sweep closes it" do
        Bidi2pdfRails.sweep_sessions!(pressure: true)

        expect(open_session_ids).not_to include(@leaked.session_id)
      end

      and_ "a dry run only reports it" do
        result = Bidi2pdfRails.sweep_sessions!(pressure: true, dry_run: true)

        expect([result.closed.map(&:id), open_session_ids]).to match([include(@leaked.session_id), include(@leaked.session_id)])
      end
    end
  end
end
