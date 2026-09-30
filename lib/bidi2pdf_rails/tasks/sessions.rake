# frozen_string_literal: true

namespace :bidi2pdf_rails do
  desc "List the Chrome sessions the remote browser holds (id, age, live or not - no page content)"
  task sessions: :environment do
    sessions = Bidi2pdfRails.chrome_sessions
    puts "no sessions" if sessions.empty?
    sessions.each do |info|
      state = if info.live then "live"
              elsif info.responsive then "responsive"
              else "unresponsive"
              end
      puts format("%-34<id>s %8<age>s  %<state>s", id: info.id, age: info.age ? "#{info.age.round}s" : "?", state: state)
    end
  end

  desc "Close leaked Chrome sessions on the remote browser (PRESSURE=1: last resort, DRY_RUN=1: report only, " \
       "CHECK_INTERVAL=10: check twice first)"
  task sweep: :environment do
    check_interval = ENV["CHECK_INTERVAL"].presence&.to_f
    result = Bidi2pdfRails.sweep_sessions!(pressure: ENV["PRESSURE"] == "1", dry_run: ENV["DRY_RUN"] == "1",
                                           check_interval: check_interval)
    verb = result.dry_run ? "would close" : "closed"
    result.closed.each { |closed| puts "#{verb} #{closed.id} (#{closed.why}, #{closed.age}s old)" }
    puts "#{verb} #{result.closed.size} of #{result.sessions} session(s)"
    puts "limit #{result.limit} still exceeded" if result.limit_exceeded
    result.errors.each { |error| warn "error: #{error}" }
    exit(1) if result.errors.any? || result.limit_exceeded
  end
end
