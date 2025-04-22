class ReportsController < ApplicationController
  def show
    respond_to do |format|
      format.html
      format.pdf { render pdf: 'my-report', layout: 'pdf' }
    end
  end

  def convert_remote_url
    render pdf: 'convert-remote-url', url: "http://example.com", wait_for_page_loaded: false, print_options: { page: { format: :A4 } }
  end

  def inline_html
    html = <<~HTML
      <html>
      <head>
      </head>
      <body>
        <h1>PDF Rendering Sample</h1>
        <p style="page-break-after: always;">Page break</p>
        <p>Content Page 2</p>
      </body>
      </html>
    HTML
    render pdf: 'inline-html', inline: html, wait_for_page_loaded: false, print_options: { page: { format: :A4 } }
  end

  def convert_remote_url_basic_auth
    render pdf: 'convert-remote-url-basic-auth',
           url: basic_auth_endpoint_url(only_path: false),
           wait_for_page_loaded: false
  end

  def convert_remote_url_cookie
    render pdf: 'convert-remote-url-cookie',
           url: cookie_endpoint_url(only_path: false),
           wait_for_page_loaded: false
  end

  def convert_remote_url_header
    render pdf: 'convert-remote-url-cookie',
           url: api_endpoint_url(only_path: false),
           wait_for_page_loaded: false
  end

  def convert_remote_url_error
    render pdf: 'convert-remote-url-cookie',
           url: "https://httpstat.us/#{params[:code]}",
           wait_for_page_loaded: false
  end
end
