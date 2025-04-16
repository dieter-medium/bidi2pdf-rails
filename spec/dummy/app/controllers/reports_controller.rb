class ReportsController < ApplicationController
  def show
    respond_to do |format|
      format.html
      format.pdf { render pdf: 'my-report', layout: 'pdf' }
    end
  end
end
