module Fission
  class Fusion

    def self.is_running?
      command = "ps -ef | grep -v grep | grep -c "
      command << "#{Fission.config.attributes['gui_bin'].gsub(' ', '\ ')} 2>&1"
      output = `#{command}`

      output.strip.to_i > 0 ? true : false
    end

  end
end
