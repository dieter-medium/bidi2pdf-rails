# frozen_string_literal: true

namespace :coverage do
  desc "Merge simplecov coverage reports"
  task :merge_reports do
    require "simplecov"

    SimpleCov.collate Dir["coverage/*-resultset.json"] do
      formatter SimpleCov::Formatter::MultiFormatter.new([
                                                           SimpleCov::Formatter::SimpleFormatter,
                                                           SimpleCov::Formatter::HTMLFormatter,
                                                           SimpleCov::Formatter::JSONFormatter
                                                         ])
    end
  end

  desc "Run tests with coverage"
  task :coverage do
    ENV["COVERAGE"] = "true"
    Rake::Task["spec"].execute
    puts "Coverage report generated in coverage/ directory"
  end
end


