# frozen_string_literal: true

require "rails_helper"
require "bidi2pdf/test_helpers/testcontainers"

# A second, warmer-enabled sibling of user_can_connect_to_an_external_webdriver_spec.rb, kept in its
# own file rather than added as a scenario there - the session_warmer_settings.enabled flag has to be
# set before that file's own before(:each) calls initialize_manager, and reaching into a shared,
# already-passing before hook from a new context risks changing its execution order for the existing
# scenario without a way to verify that here. Duplicating just the small remote-chromedriver
# connection setup keeps both files independently readable and safe to change separately.
RSpec.feature "As a developer, I want Bidi2pdf::SessionWarmer to work against an external chromedriver", :chromedriver, :pdf, type: :request do
  def reachable?(url, timeout: 2)
    uri = URI(url)

    Net::HTTP.start(
      uri.host,
      uri.port,
      open_timeout: timeout,
      read_timeout: timeout
    ) do |http|
      response = http.get(uri.request_uri)
      response.is_a?(Net::HTTPSuccess)
    end
  rescue SocketError,
    Errno::ECONNREFUSED,
    Errno::EHOSTUNREACH,
    Net::OpenTimeout,
    Net::ReadTimeout => error
    false
  end

  before do
    url = session_url
    host = chromedriver_container.host
    port = chromedriver_container.mapped_port(chromedriver_container.port)

    url = "http://remote-chrome:#{port}/session" unless host
    url = "http://127.0.0.1:#{port}/session" unless reachable?(url)

    with_render_setting :browser_url, url
    with_session_warmer_settings :enabled, true

    Bidi2pdfRails::ChromedriverManagerSingleton.initialize_manager force: true
  end

  after do
    Bidi2pdfRails::ChromedriverManagerSingleton.shutdown force: true
  end

  scenario "Rendering a PDF through Bidi2pdf::SessionWarmer against a remote Chromedriver" do
    when_ "I visit the PDF version of a report" do
      before do
        @response = get_pdf_response "/convert-remote-url"
      end

      then_ "I receive a successful HTTP response" do
        expect(@response.code).to eq("200")
      end

      and_ "I receive a PDF file in response" do
        expect(@response['Content-Type']).to eq("application/pdf")
      end

      and_ "the PDF contains the expected number of pages" do
        expect(@response.body).to have_pdf_page_count(1)
      end
    end
  end
end
