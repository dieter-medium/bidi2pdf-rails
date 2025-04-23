[![Build Status](https://github.com/dieter-medium/bidi2pdf-rails/actions/workflows/ruby.yml/badge.svg)](https://github.com/dieter-medium/bidi2pdf-rails/blob/main/.github/workflows/ruby.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/6425d9893aa3a9ca243e/maintainability)](https://codeclimate.com/github/dieter-medium/bidi2pdf-rails/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/6425d9893aa3a9ca243e/test_coverage)](https://codeclimate.com/github/dieter-medium/bidi2pdf-rails/test_coverage)
[![Gem Version](https://badge.fury.io/rb/bidi2pdf-rails.svg)](https://badge.fury.io/rb/bidi2pdf-rails)
[![Open Source Helpers](https://www.codetriage.com/dieter-medium/bidi2pdf-rails/badges/users.svg)](https://www.codetriage.com/dieter-medium/bidi2pdf-rails)

# 📄 Bidi2pdfRails

**Bidi2pdfRails** is the official Rails integration for [Bidi2pdf](https://github.com/dieter-medium/bidi2pdf) — a
modern, headless-browser-based PDF rendering engine.  
Generate high-fidelity PDFs directly from your Rails views or external URLs with minimal setup.

---

## ✨ Features

- 🔍 Accurate PDF rendering using a real browser engine
- 💾 Supports both HTML string rendering and remote URL conversion
- 🔐 Built-in support for authentication (Basic Auth, cookies, headers)
- 🧰 Full test suite with examples for Rails controller integration
- 🧠 Sensible defaults, yet fully configurable

---

## 🔧 Installation

Add to your Gemfile:

```ruby
gem "bidi2pdf-rails"
# for development only
# gem "bidi2pdf-rails", github: "dieter-medium/bidi2pdf-rails", branch: "main"

# Optional for performance:
# gem "websocket-native"
```

Install it:

```bash
bundle install
```

Generate the config initializer:

```bash
bin/rails generate bidi2pdf_rails:initializer
```

---

## 📦 Usage Examples

### 📄 Rendering a Rails View as PDF

```ruby
# app/controllers/invoices_controller.rb

def show
  render pdf: "invoice",
         template: "invoices/show",
         layout: "pdf",
         locals: { invoice: @invoice },
         print_options: { landscape: true },
         wait_for_network_idle: true
end
```

### 🌐 Rendering a Remote URL to PDF

```ruby

def convert
  render pdf: "external-report",
         url: "https://example.com/dashboard",
         wait_for_page_loaded: false,
         print_options: { page: { format: :A4 } }
end
```

---

## 🛡️ Authentication Support

Need to convert pages that require authentication? No problem. Use:

- `auth: { username:, password: }`
- `cookies: { session_key: value }`
- `headers: { "Authorization" => "Bearer ..." }`

Example:

```ruby
render pdf: "secure",
       url: secure_report_url,
       auth: { username: "admin", password: "secret" }
```

Or use global config in `bidi2pdf_rails.rb` initializer:

```ruby
config.render_remote_settings.basic_auth_user = ->(_) { "admin" }
config.render_remote_settings.basic_auth_pass = ->(_) { Rails.application.credentials.dig(:pdf, :auth_pass) }
```

---

## 📂 Asset Access via CORS

When rendering HTML with `render_to_string`, Chromium needs access to your assets (CSS, images, fonts).  
Enable CORS for `/assets` using `rack-cors`:

```ruby
# Gemfile
gem 'rack-cors'

# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/assets/*', headers: :any, methods: [:get, :options]
  end
end
```

---

## 🧪 Acceptance Examples

This repo includes **real integration tests** that serve as usage documentation:

- [Download PDF with `.pdf` format](spec/acceptance/user_can_download_report_pdf_spec.rb)
- [Render protected remote URLs using Basic Auth, cookies, and headers](spec/acceptance/user_can_generate_pdf_from_protected_remote_url_spec.rb)
- [Inject custom CSS into a Webpage before printing](spec/acceptance/user_can_inject_css_before_pdf_printing_spec.rb)
- [Inject custom JS into a Webpage before printing](spec/acceptance/user_can_inject_js_before_pdf_printing_spec.rb)
- [Using callbacks to modify the PDF before sending](spec/acceptance/user_can_hook_into_the_pdf_printing_lifecycle_spec.rb)
- [Using a remote chromedriver](spec/acceptance/user_can_connect_to_an_external_webdriver_spec.rb)

---

## 🧠 Configuration

Bidi2pdfRails is highly configurable.

See full config options in:

```bash
bin/rails generate bidi2pdf_rails:initializer
```

Or explore [Bidi2pdfRails::Config::CONFIG_OPTIONS](lib/bidi2pdf_rails/config.rb) in the source.

---

## 🙌 Contributing

Pull requests, issues, and ideas are all welcome 🙏  
Want to contribute? Just fork, branch, and PR like a boss.

> Contribution guide coming soon!

---

## 📄 License

This gem is released under the [MIT License](https://opensource.org/licenses/MIT).  
Use freely — and responsibly.
