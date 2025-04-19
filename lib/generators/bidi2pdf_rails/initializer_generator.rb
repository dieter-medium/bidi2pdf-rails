module Bidi2pdfRails
  class InitializerGenerator < Rails::Generators::Base
    source_root File.expand_path("templates", __dir__)

    def self.infer_option_type(default)
      case default
      when true, false then :boolean
      when Numeric then :numeric
      when Hash then :hash
      when Array then :array
      when Proc then :string
      else :string
      end
    end

    def self.normalize_group(key)
      key.to_s.sub(/(_settings|_options)$/, "")
    end

    def self.with_group_config
      that = self
      Bidi2pdfRails::Config::CONFIG_OPTIONS.each_pair do |group_key, group_config|
        group_prefix = that.normalize_group(group_key)
        yield group_key, group_prefix, group_config
      end
    end

    def self.with_group_option
      with_group_config do |group_key, group_prefix, group_config|
        group_config[:options].each do |opt|
          yield group_key, group_prefix, opt
        end
      end
    end

    with_group_option do |_group_key, group_prefix, opt|
      next unless opt[:ask]

      name = "#{group_prefix}_#{opt[:name]}"
      type = infer_option_type(opt[:default])
      default = opt[:default_as_str] || opt[:default]

      class_option name,
                   type: type,
                   desc: opt[:desc],
                   default: default,
                   enum: opt[:limited_to]
    end

    def ask_questions
      @answers = {}

      return if options[:quiet]

      self.class.with_group_config do |_group_key, group_prefix, group_config|
        next unless group_config[:ask]
        if group_config[:ask]
          next unless yes?(group_config[:ask], :green)
        end

        group_config[:options].select { |opt| opt[:ask] }.each do |opt|
          option_key = "#{group_prefix}_#{opt[:name]}".to_sym
          next if cli_option_set?(option_key, opt)

          @answers[option_key] = prompt_for_option(opt)
        end
      end

      @answers.compact!
    end

    def generate_config
      @config_path = "config/initializers/bidi2pdf_rails.rb"

      template "bidi2pdf_rails.rb.tt", @config_path
    end

    def inject_environment_config
      env_file = "config/environments/development.rb"
      env_path = File.join(destination_root, env_file)

      if File.exist?(env_path)
        if File.read(env_path).include?("config.x.bidi2pdf_rails")
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

    no_commands do
      def cli_option_set?(option_key, opt_def)
        return false unless options.key?(option_key.to_s)

        default = opt_def[:default_as_str] || opt_def[:default]
        options[option_key.to_s].to_s != default.to_s
      end

      def prompt_for_option(opt)
        type = self.class.infer_option_type(opt[:default])

        if type == :boolean
          question = opt[:desc].match?(/y\/n/i) ? opt[:desc] : "#{opt[:desc]} (y/n)?"
          yes?(question, opt[:color])
        else
          opts = {
            default: opt[:default_as_str] || opt[:default],
            limited_to: opt[:limited_to],
            echo: !opt[:secret]
          }.compact

          ask(opt[:desc], opt[:color], **opts)
        end
      end

      def normalize_group(key)
        self.class.normalize_group(key)
      end
    end

    private

    def changed_by_user?(full_top_level_name, option_name)
      top_level_name = normalize_group full_top_level_name

      full_qual_option_name = "#{top_level_name}_#{option_name}".to_sym
      return false unless options.key?(full_qual_option_name.to_s)

      option_def = Bidi2pdfRails::Config::CONFIG_OPTIONS.dig(full_top_level_name.to_sym, :options).find { |opt| opt[:name] == option_name.to_sym }
      default = option_def[:default_as_str] ? option_def[:default_as_str] : option_def[:default]

      current_value = get_option_value(top_level_name, option_name)

      return false if default.nil? && current_value.empty?
      return true if default.nil? && current_value.present?

      !current_value.to_s.match /#{Regexp.escape(default.to_s)}/
    end

    def get_option_value(top_level_name, option_name)
      top_level_name = top_level_name.to_s.sub(/(_settings)|(_options)$/, "")
      full_qual_option_name = "#{top_level_name}_#{option_name}".to_sym

      result = if @answers.key?(full_qual_option_name)
                 @answers[full_qual_option_name]
               elsif options.key?(full_qual_option_name.to_s)
                 options[full_qual_option_name.to_s]
               else
                 nil
               end

      if result.is_a?(String)
        if result.match(/(^\s+->\s+{)|(.*Rails\.)/) || numeric?(result)
          return result
        end
        '"' + result + '"'
      else
        result
      end
    end

    def numeric?(string)
      # Float/Integer conversion with rescue catches most numeric formats
      true if Float(string) rescue false
    end
  end
end
