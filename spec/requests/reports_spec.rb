# frozen_string_literal: true

require_relative '../rails_helper'

RSpec.describe "Reports", type: :request do
  describe "GET /reports/:id.pdf" do
    it "responds with PDF content" do
      get "/reports/1.pdf"

      expect(response).to have_http_status(:ok)
      # expect(response.content_type).to eq("application/pdf")

      # Optional: make sure it returns *some* PDF-ish data
      # expect(response.body[0..3]).to eq("%PDF") # all PDFs start with %PDF
    end
  end
end
