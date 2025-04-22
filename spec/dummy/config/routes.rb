Rails.application.routes.draw do
  get "reports/:id" => "reports#show", as: :report

  get "convert-remote-url" => "reports#convert_remote_url", as: :print_remote
  get "inline-html" => "reports#inline_html", as: :print_inline
  get "convert-remote-url-basic-auth" => "reports#convert_remote_url_basic_auth", as: :print_remote_basic_auth
  get "convert-remote-url-cookie" => "reports#convert_remote_url_cookie", as: :print_remote_url_cookie
  get "convert-remote-url-header" => "reports#convert_remote_url_header", as: :print_remote_url_header
  get "convert-remote-url-error/:code" => "reports#convert_remote_url_error", as: :print_error
  get "inject/:kind" => "reports#inject",
      constraints: { kind: /(raw-css|raw-js|url-css|url-js)/ },
      as: :inject_css

  get 'basic-auth', to: 'secure#basic_auth_endpoint', as: :basic_auth_endpoint
  get 'header-auth', to: 'secure#api_endpoint', as: :api_endpoint
  get 'cookie-auth', to: 'secure#cookie_endpoint', as: :cookie_endpoint

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
