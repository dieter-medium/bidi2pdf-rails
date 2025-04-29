# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bidi2pdfRails::Configurable::BaseNestedConfig do
  subject(:config) { described_class.new(option_definitions) }

  let(:option_definitions) { self.class.option_definitions }

  def self.option_definitions
    [
      { name: :simple_string, default: "default_string", desc: "A simple string option" },
      { name: :numeric_value, default: 42, desc: "A numeric value" },
      { name: :boolean_flag, default: true, desc: "A boolean flag" },
      { name: :lambda_value, default: -> { Date.today }, desc: "A dynamic value from lambda" },
      { name: :hash_value, default: { key: "value" }, desc: "A hash value" }
    ]
  end

  describe "#initialize" do
    option_definitions.each do |opt|
      it "creates reader methods for #{opt[:name]}" do
        expect(config).to respond_to(opt[:name])
      end

      it "creates writer methods for #{opt[:name]}" do
        expect(config).to respond_to("#{opt[:name]}=")
      end

      if !opt[:default].is_a?(Proc)
        it "sets default values for #{opt[:name]}" do
          expect(config.send(opt[:name])).to eq(opt[:default])
        end
      end
    end

    it "evaluates lambda defaults when accessed through _value methods" do
      expect(config.lambda_value_value).to eq(Date.today)
    end
  end

  describe "#reset_to_defaults!" do
    before do
      config.simple_string = "changed_value"
      config.numeric_value = 100
      config.boolean_flag = false
    end

    option_definitions.reject { |opt| opt[:name] == :lambda_value }.each do |opt|
      it "resets #{opt[:name]} to their default" do
        config.reset_to_defaults!

        expect(config.send(opt[:name])).to eq(opt[:default])
      end
    end
  end

  describe "#configure" do
    it "yields self to the provided block" do
      yielded_object = nil

      config.configure do |c|
        yielded_object = c
        c.simple_string = "configured_value"
      end

      expect(yielded_object).to eq(config)
    end

    it "applies the given values" do
      config.configure do |c|
        c.simple_string = "configured_value"
      end

      expect(config.simple_string).to eq("configured_value")
    end
  end

  describe "#to_h" do
    it "returns a hash containing all option values" do
      result = config.to_h

      expect(result).to include(
                          simple_string: "default_string",
                          numeric_value: 42,
                          boolean_flag: true,
                          lambda_value: Proc,
                          hash_value: { key: "value" }
                        )
    end
  end

  describe "#_value methods" do
    context "with regular values" do
      option_definitions.reject { |opt| opt[:name] == :lambda_value }.each do |opt|
        it "returns the value directly for #{opt[:name]}" do
          expect(config.send "#{opt[:name]}_value").to eq(config.send(opt[:name]))
        end

        it "returns updated values for #{opt[:name]}" do
          config.send "#{opt[:name]}=", "new_string"

          expect(config.send(opt[:name])).to eq("new_string")
        end
      end
    end

    context "with lambda values" do
      it "calls the lambda and returns its result" do
        today = Date.today
        expect(config.lambda_value_value).to eq(today)
      end

      it "returns updated values" do
        config.lambda_value = -> { "computed_value" }

        expect(config.lambda_value_value).to eq("computed_value")
      end

      it "accepts arguments for the _value methods" do
        args = nil
        config.lambda_value = ->(*lambda_args) { args = lambda_args }

        provided_args = [1, "a", :thing]

        config.lambda_value_value(*provided_args)

        expect(args).to eq(provided_args)
      end
    end
  end
end
