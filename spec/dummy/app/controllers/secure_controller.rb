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
    # TEMPORARY DIAGNOSTIC (PR #22 cookie-auth 401) - remove before merge.
    Rails.logger.warn "[cookie-diag] verify: host=#{request.host_with_port} pid=#{Process.pid} raw Cookie header=#{request.headers['Cookie'].inspect}"
    Rails.logger.warn "[cookie-diag] verify: cookies[:auth_token]=#{cookies[:auth_token].inspect}"
    Rails.logger.warn "[cookie-diag] verify: cookies.signed[:auth_token]=#{cookies.signed[:auth_token].inspect}"
    Rails.logger.warn "[cookie-diag] verify: secret digest=#{Digest::SHA256.hexdigest(Rails.application.secret_key_base)[0, 12]} salt=#{request.signed_cookie_salt.inspect}"

    auth_token = cookies.signed[:auth_token]
    valid_token = "valid-authentication-token"

    if auth_token.blank? || auth_token != valid_token
      render html: "<h1>Unauthorized</h1><p>Invalid or missing API key</p>".html_safe, status: :unauthorized
    end
  end
end
