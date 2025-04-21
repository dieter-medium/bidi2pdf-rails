# app/controllers/secure_controller.rb
class SecureController < ApplicationController
  # Basic Auth protection for the first action
  http_basic_authenticate_with name: "admin", password: "secret", only: :basic_auth_endpoint

  before_action :authenticate_with_api_key, only: :api_endpoint
  before_action :authenticate_with_cookie, only: :cookie_endpoint

  def basic_auth_endpoint
    @auth_method = "HTTP Basic Authentication"
    @auth_description = "This endpoint requires username and password authentication."
    @auth_details = "Credentials: username: <code>admin</code>, password: <code>secret</code>"

    render :show, layout: 'simple'
  end

  def api_endpoint
    @auth_method = "API Key Authentication"
    @auth_description = "This endpoint requires an API key in the header."
    @auth_details = "Required header: <code>X-API-Key: your-secret-api-key</code>"

    render :show, layout: 'simple'
  end

  def cookie_endpoint
    @auth_method = "Cookie Authentication"
    @auth_description = "This endpoint requires an authentication cookie."
    @auth_details = "Required cookie: <code>auth_token</code> with value <code>valid-authentication-token</code>"

    render :show, layout: 'simple'
  end

  private

  def authenticate_with_api_key
    api_key = request.headers["X-API-Key"]
    valid_key = "your-secret-api-key"

    if api_key.blank? || api_key != valid_key
      render html: "<h1>Unauthorized</h1><p>Invalid or missing API key</p>".html_safe, status: :unauthorized
    end
  end

  def authenticate_with_cookie
    auth_token = cookies.signed[:auth_token]
    valid_token = "valid-authentication-token"

    if auth_token.blank? || auth_token != valid_token
      render html: "<h1>Unauthorized</h1><p>Invalid or missing API key</p>".html_safe, status: :unauthorized
    end
  end
end
