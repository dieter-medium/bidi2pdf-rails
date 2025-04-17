class ReportsController < ApplicationController
  def show
    respond_to do |format|
      format.html
      format.pdf { render pdf: 'my-report', layout: 'pdf' }
    end
  end

  def print_remote
    render pdf: 'remote-report', url: "http://example.com", wait_for_page_loaded: false, print_options: { page: { format: :A4 } }
  end
end
