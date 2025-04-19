# frozen_string_literal: true

require "securerandom"
module DefaultDirsHelper
  def spec_dir
    RSpec.configuration.spec_dir
  end

  def tmp_dir
    RSpec.configuration.tmp_dir
  end

  def tmp_file(*)
    File.join(tmp_dir, *)
  end

  def random_tmp_dir(*dirs, prefix: "tmp_")
    all_dirs = [tmp_dir] + (dirs || []).compact

    File.join(*all_dirs, "#{prefix}#{SecureRandom.hex(8)}")
  end
end

RSpec.configure do |config|
  config.add_setting :spec_dir, default: File.expand_path("..", __dir__)

  config.add_setting :tmp_dir, default: File.join(config.spec_dir, "..", "tmp")
  config.add_setting :docker_dir, default: File.join(config.spec_dir, "..", "docker")

  config.include DefaultDirsHelper
  config.extend DefaultDirsHelper
end
