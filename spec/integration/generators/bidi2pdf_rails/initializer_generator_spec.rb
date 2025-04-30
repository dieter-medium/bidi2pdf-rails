# frozen_string_literal: true

require "rails_helper"
require "rails/generators"
require "ammeter/init"
require "generators/bidi2pdf_rails/initializer_generator"

RSpec.describe Bidi2pdfRails::InitializerGenerator, type: :generator do
  destination tmp_file("generators")

  before { prepare_destination }

  after { FileUtils.rm_rf(destination_root) }

  describe 'the generated files' do
    let(:dev_env_file) { file('config/environments/development.rb') }

    before do
      ["development.rb", "test.rb", "production.rb"].each do |env|
        env_file = file("config/environments/#{env}")
        FileUtils.mkdir_p env_file.dirname

        # write minimal file
        File.write(env_file, <<~RUBY)
          Rails.application.configure do

          end

        RUBY
      end

      run_generator %w[
      --general-verbosity medium
      --proxy-addr=127.0.0.1
      --proxy-port=8080
      --quiet
    ]
    end

    describe 'the initializer file' do
      subject(:initializer) { file('config/initializers/bidi2pdf_rails.rb') }

      it { is_expected.to be_readable }
      it { is_expected.to have_correct_syntax }

      Bidi2pdfRails::Config::CONFIG_OPTIONS.each_pair do |group_key, top_level_option|
        name = top_level_option[:name]
        it { is_expected.to contain(name) }

        top_level_option[:options].each do |option|
          option_accessor = "#{group_key}.#{option[:name]}".to_sym
          if ["proxy_settings.port", "proxy_settings.addr", "general_options.verbosity"].include?(option_accessor.to_s)
            it { is_expected.to contain("config.#{option_accessor} = ") }
          else
            it { is_expected.to contain("# config.#{option_accessor} = #{option[:default_as_str] ? option[:default_as_str] : option[:default].inspect}") }
          end
        end
      end
    end

    describe 'the development environment file' do
      subject(:dev_env_file) { file('config/environments/development.rb') }

      it { is_expected.to contain("config.x.bidi2pdf_rails.headless = false") }
    end
  end
end
