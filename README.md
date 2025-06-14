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

## 🌐 Architecture

```mermaid
%%{  init: {
      "theme": "base",
      "themeVariables": {
        "primaryColor":  "#E0E7FF",
        "secondaryColor":"#FEF9C3",
        "tertiaryColor": "#DCFCE7",
        "edgeLabelBackground":"#FFFFFF",
        "fontSize":"14px",
        "nodeBorderRadius":"6"
      }
    }
}%%
flowchart LR
%% ───────────────────────────────────
%% Rails world
    subgraph R["fa:fa-rails Rails World"]
        direction TB
        R1["fa:fa-gem Your&nbsp;Rails&nbsp;App"]
        R2["fa:fa-plug bidi2pdf-rails&nbsp;Engine"]
        R3["fa:fa-cog&nbsp;ActionController::Renderers<br/><code>render pdf:</code>"]
        R4["fa:fa-file-code Rails&nbsp;View&nbsp;(ERB/Haml)"]
    end

%% bidi2pdf core
    subgraph B["fa:fa-gem bidi2pdf Core"]
        direction TB
        B1["fa:fa-gem bidi2pdf"]
    end

%% Chrome env
    subgraph C["fa:fa-chrome Chrome Environment"]
        direction LR
        C1["fa:fa-chrome Local&nbsp;Chrome<br/>(sub-process)"]
        C2["fa:fa-docker Docker&nbsp;Chrome<br/>(remote)"]
    end

%% Artifact
    P[[PDF&nbsp;File]]

%% ─── Flows ─────────────────────────
R1 -- " Controller&nbsp;invokes<br/><code>render pdf:</code> " --> R3
R3 -- " HTML&nbsp;+&nbsp;Assets<br/>(via&nbsp;<code>render_to_string</code>) " --> R2
R2 -- " HTML&nbsp;/&nbsp;URL&nbsp;+&nbsp;CSS/JS " --> B1
B1 -- " WebDriver&nbsp;BiDi " --> C1
B1 -- " WebDriver&nbsp;BiDi " --> C2
C1 -- " PDF&nbsp;bytes " --> B1
C2 -- " PDF&nbsp;bytes " --> B1
B1 -- " PDF&nbsp;stream " --> R2
R2 -- " send_data " --> R1
R1 -- " Download/inline " --> P

%% ─── Styling classes ───────────────
classDef rails fill: #E0E7FF, stroke: #6366F1, color: #1E1B4B
classDef engine fill: #c7d2fe, stroke: #4338CA, color: #1E1B4B
classDef bidi fill: #E0E7FF, stroke: #4f46e5, color: #1E1B4B
classDef chrome fill: #FEF9C3, stroke: #F59E0B, color: #78350F
classDef artifact fill: #DCFCE7, stroke: #16A34A, color: #065F46

class R1 rails
class R2 engine
class R3,R4 rails
class B1 bidi
class C1,C2 chrome
class P artifact
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

## 🐛 Development Mode Considerations

> **Deadlock Warning**  
> In Rails development mode, loopback asset or page requests (e.g., when ChromeDriver or Grover fetches your own app’s
> URL) can deadlock under Rails’ autoload interlock. See Puma’s docs: https://puma.io/puma/file.rails_dev_mode.html

**Workarounds:**

1. **Precompile & serve assets statically** (in `config/environments/development.rb`):
   ```ruby
   config.public_file_server.enabled = true
   ```
2. **Run Puma with single-threaded workers:**
   ```ruby
   workers ENV.fetch("WEB_CONCURRENCY") { 2 }
   threads 1, 1
   ```

Implementing these steps helps avoid interlock-induced deadlocks when generating PDFs in development.

---

## 🧪 Acceptance Examples

This repo includes **real integration tests** that serve as usage documentation:

- [Download PDF with `.pdf` format](spec/acceptance/user_can_download_report_pdf_spec.rb)
- [Render protected remote URLs using Basic Auth, cookies, and headers](spec/acceptance/user_can_generate_pdf_from_protected_remote_url_spec.rb)
- [Inject custom CSS into a Webpage before printing](spec/acceptance/user_can_inject_css_before_pdf_printing_spec.rb)
- [Inject custom JS into a Webpage before printing](spec/acceptance/user_can_inject_js_before_pdf_printing_spec.rb)
- [Using callbacks to modify the PDF before sending](spec/acceptance/user_can_hook_into_the_pdf_printing_lifecycle_spec.rb)
- [Using a remote chromedriver](spec/acceptance/user_can_connect_to_an_external_webdriver_spec.rb)
- [Using ActiveStorage and ActiveJob to generate PDFs in the background](spec/user_can_generate_async_pdf_reports_spec.rb)

---

## 🧠 Configuration

Bidi2pdfRails is highly configurable.

See full config options in:

```bash
bin/rails generate bidi2pdf_rails:initializer
```

Or explore [Bidi2pdfRails::Config::CONFIG_OPTIONS](lib/bidi2pdf_rails/config.rb) in the source.

---

## 🧪 Test Helpers

On top of Bidi2pdf test helpers, Bidi2pdfRails provides a suite of RSpec helpers (activated with `pdf: true`) to
simplify PDF-related testing:

### EnvironmentHelper

– `inside_container?` → true if running in Docker  
– `environment_type` → one of `:ci`, `:codespaces`, `:container`, `:local`  
– `environment_…?` predicates for each type

### SettingsHelper

– `with_render_setting(key, value)`  
– `with_pdf_settings(key, value)`  
– `with_lifecycle_settings(key, value)`  
– `with_chromedriver_settings(key, value)`  
– `with_proxy_settings(key, value)`  
…plus automatic reset after each `pdf: true` example

### ServerHelper

– `server_running?`, `server_port`, `server_host`, `server_url`  
– boots a Puma test server before suite `type: :request, pdf: true` specs  
– shuts it down afterward

### RequestHelper

– `get_pdf_response(path)` → fetches raw HTTP response  
– `follow_redirects(response, max_redirects = 10)`

#### Usage

Tag your examples or example groups:

```ruby
RSpec.describe "Invoice PDF", type: :request, pdf: true do
  it "renders a complete PDF" do
    response = get_pdf_response "/invoices/123.pdf"
    expect(response['Content-Type']).to eq("application/pdf")
  end
end
```

---

## 🙌 Contributing

Pull requests, issues, and ideas are all welcome 🙏  
Want to contribute? Just fork, branch, and PR like a boss.

> Contribution guide coming soon!

---

## 📄 License

This gem is released under the [MIT License](https://opensource.org/licenses/MIT).  
Use freely — and responsibly.
