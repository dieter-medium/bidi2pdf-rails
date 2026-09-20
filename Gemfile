source "https://rubygems.org"

# Specify your gem's dependencies in bidi2pdf-rails.gemspec.
gemspec

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

gem "ammeter", "~> 1.1.5", require: false
gem "propshaft"
gem "rack-cors"
gem "sqlite3", ">= 2.1"

# json 3 only accepts keyword options; Rails 8.1.3.1 still hands JSON.parse a positional options
# hash when it reads a JSON-coded column (ActiveStorage::Blob#metadata), which raises
# "wrong number of arguments (given 2, expected 1)". No Gemfile.lock is committed, so CI would
# otherwise resolve json 3. Drop this once the allowed Rails range handles json 3.
gem "json", "< 3"
