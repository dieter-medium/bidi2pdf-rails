# frozen_string_literal: true

require "active_support/concern"

module Bidi2pdfRails
  module Configurable
    extend ActiveSupport::Concern
    included do
      include Singleton
    end

    class BaseNestedConfig
      def initialize(option_defs)
        @__options = option_defs
        define_accessors!
        reset_to_defaults!
      end

      def define_accessors!
        @__options.each do |opt|
          name = opt[:name]
          unless respond_to?(name)
            define_singleton_method(name) { instance_variable_get("@#{name}") }
            define_singleton_method("#{name}=") { |v| instance_variable_set("@#{name}", v) }

            define_singleton_method("#{name}_value") do |*args|
              value = send("#{name}")
              value.respond_to?(:call) ? value.call(*args) : value
            end
          end
        end
      end

      def reset_to_defaults!
        @__options.each do |opt|
          default = opt[:default]
          value = default
          send("#{opt[:name]}=", value)
        end
      end

      def config_options
        @__options
      end

      def configure
        yield self if block_given?
      end

      def to_h
        @__options.to_h do |opt|
          [opt[:name], send(opt[:name])]
        end
      end

      def inspect
        "#<#{self.class.name || "ConfigSection"} #{to_h.inspect}>"
      end
    end

    def configure
      yield self if block_given?
    end

    class_methods do
      def configure_with(grouped_options)
        @config_groups = grouped_options

        grouped_options.each do |group_key, group_data|
          group_class = Class.new(BaseNestedConfig)

          define_method(group_key) do
            ivar = "@#{group_key}"
            instance_variable_get(ivar) || instance_variable_set(ivar, group_class.new(group_data[:options]))
          end

          define_method("#{group_key}=") do |val|
            raise ArgumentError, "Use individual accessors, not direct assignment to config groups"
          end
        end

        define_method(:reset_to_defaults!) do
          grouped_options.each_key do |group_key|
            section = send(group_key)
            section.reset_to_defaults!
          end
        end

        define_method(:config_groups) do
          grouped_options
        end

        define_method(:to_h) do
          grouped_options.keys.to_h do |group_key|
            section = send(group_key)
            [group_key, section.to_h]
          end
        end

        define_method(:inspect) do
          "#<#{self.class.name} #{to_h.inspect}>"
        end
      end
    end
  end
end
