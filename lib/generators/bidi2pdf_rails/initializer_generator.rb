module Bidi2pdfRails
  class InitializerGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)
    desc "Generates a config/initializers/bidi2pdf.rb config file"

    class_option :force, type: :boolean, default: false, desc: "Overwrite existing file"
    class_option :quiet, type: :boolean, default: false, desc: "Skip prompts"

    def ask_questions
      return if options[:quiet]

      @log_network_events = yes?("Log network traffic? (y/n)", :green)
      @log_browser_console = yes?("Log browser console output? (y/n)", :green)
      @headless = yes?("Run Chrome in headless mode? (y/n)", :green)
      @proxy = yes?("Use a proxy server? (y/n)", :green)

      if @proxy
        @proxy_addr = ask("Proxy address (e.g., 127.0.0.1):", :yellow)
        @proxy_port = ask("Proxy port (e.g., 8080):", :yellow)
      end

      @configure_pdf = yes?("Configure custom PDF settings? (y/n)", :green)
      if @configure_pdf
        @pdf_orientation = ask("PDF orientation (portrait/landscape):", :yellow)
        @pdf_margins = yes?("Configure PDF margins? (y/n)", :green)
        if @pdf_margins
          @pdf_margin_top = ask("PDF margin top (mm):", :yellow)
          @pdf_margin_bottom = ask("PDF margin bottom (mm):", :yellow)
          @pdf_margin_left = ask("PDF margin left (mm):", :yellow)
          @pdf_margin_right = ask("PDF margin right (mm):", :yellow)
        end
        @pdf_page = yes?("Configure PDF page size? (y/n)", :green)
        if @pdf_page
          @pdf_page_width = ask("PDF page width (mm):", :yellow)
          @pdf_page_height = ask("PDF page height (mm):", :yellow)
        end

        @pdf_print_background = yes?("Print background graphics? (y/n)", :green)
        @pdf_scale = ask("PDF scale (e.g., 1.0):", :yellow)
        @shrink_to_fit = ask("Shrink to fit? (y/n)", :green)
      end
    end

    def generate_config
      @config_path = "config/initializers/bidi2pdf_rails.rb"

      template "bidi2pdf_rails.rb.tt", @config_path
    end

    def inject_environment_config
      env_file = "config/environments/development.rb"

      if File.exist?(env_file)
        if File.read(env_file).include?("config.x.bidi2pdf_rails")
          say_status :skipped, "Bidi2PDF settings already present in #{env_file}", :yellow
        else
          content = <<~RUBY.gsub(/^(?=[\w#])/, "  ")
            # Custom Bidi2PDF settings, check config/initializers/bidi2pdf_rails.rb for hints
            config.x.bidi2pdf_rails.headless = false
            config.x.bidi2pdf_rails.verbosity = :high
            # config.x.bidi2pdf_rails.log_browser_console = true
            # config.x.bidi2pdf_rails.default_timeout = 60
          RUBY

          inject_into_file env_file, content, before: /^end\s*$/

          say_status :modified, env_file, :green
        end
      else
        say_status :error, "Could not find #{env_file}", :red
      end
    end
  end
end
