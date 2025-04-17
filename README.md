[![Build Status](https://github.com/dieter-medium/bidi2pdf-rails/actions/workflows/ruby.yml/badge.svg)](https://github.com/dieter-medium/bidi2pdf-rails/blob/main/.github/workflows/ruby.yml)
[![Maintainability](https://api.codeclimate.com/v1/badges/6425d9893aa3a9ca243e/maintainability)](https://codeclimate.com/github/dieter-medium/bidi2pdf-rails/maintainability)
[![Gem Version](https://badge.fury.io/rb/bidi2pdf-rails.svg)](https://badge.fury.io/rb/bidi2pdf-rails)
[![Test Coverage](https://api.codeclimate.com/v1/badges/6425d9893aa3a9ca243e/test_coverage)](https://codeclimate.com/github/dieter-medium/bidi2pdf-rails/test_coverage)
[![Open Source Helpers](https://www.codetriage.com/dieter-medium/bidi2pdf-rails/badges/users.svg)](https://www.codetriage.com/dieter-medium/bidi2pdf-rails)

# 📄 Bidi2pdfRails

**Bidi2pdfRails** is the official Rails integration for [Bidi2pdf](https://github.com/dieter-medium/bidi2pdf) – a
modern, browser-based solution for converting HTML to high-quality PDFs.  
It leverages headless browsing and offers a simple, flexible interface for PDF generation directly from your Rails
application.

> **⚠️ Note:** This project is currently **under development** and **not yet recommended for production use**.

---

## 🚀 Why Bidi2pdfRails?

- Utilizes modern browser technologies for accurate rendering (similar to `grover` or `wicked_pdf`)
- Easy to integrate into existing Rails projects
- Configurable options: URL, output path, rendering settings

---

## 🔧 Installation

Add the following lines to your `Gemfile`:

```ruby
gem "bidi2pdf-rails"
# As long as the gem is not published, use:
gem "bidi2pdf-rails", github: "dieter-medium/bidi2pdf-rails", branch: "main"
gem "bidi2pdf", github: "dieter-medium/bidi2pdf", branch: "main"

# if you want a small performance boost, you can use the following:
# gem "websocket-native"
```

Then install the dependencies:

```bash
bundle
```

Generate the initializer:

```bash
bin/rails generate bidi2pdf_rails:initializer
```

Alternatively, install it manually:

```bash
gem install bidi2pdf-rails
```

---

## 🧪 Example & Getting Started

You can find a full example inside the [`spec/dummy`](spec/dummy) directory of this repository.  
This demonstrates how to use `Bidi2pdfRails` in a realistic mini Rails application setup.

### Basic Usage

```ruby
# Render html via controller action `render_to_string`
# Any controller action:
def show
  render pdf: "invoice",
         template: "invoices/show",
         layout: "pdf",
         locals: { invoice: @invoice },
         print_options: { landscape: true },
         wait_for_network_idle: true,
         asset_host: "https://assets.example.com"
end

# Render pdf via direct url call
def show
  # See: PdfRenderer for all options
  render pdf: 'remote-report', url: "http://example.com", wait_for_page_loaded: false, print_options: { page: { format: :A4 } }
end

```

### CORS Configuration for Assets

When generating PDFs via `render_to_string`, this gem renders HTML from data URLs (e.g., `data:text/html,...`), which
are treated as unique origins with different security contexts than your application.

Chrome's security model will block access to your application's assets unless proper CORS headers are configured to
allow cross-origin requests.

Use the rack-cors gem to enable asset access:

```ruby
# In Gemfile
gem 'rack-cors'

# In config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*' # Consider restricting this in production
    resource '/assets/*', headers: :any, methods: [:get, :options]
  end
end
```

---

## 🙌 Contributing

Want to contribute?  
Pull requests, bug reports, and ideas are warmly welcome!

*Contribution guidelines will be added soon.*

---

## 📄 License

This gem is open-source and available under the terms of the [MIT License](https://opensource.org/licenses/MIT).  
Free to use – with responsibility.
