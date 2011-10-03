module Fission
  class Fusion

    def self.is_running?
      command = "ps -ef | grep -v grep | grep -c "
      command << "#{Fission.config['gui_bin'].gsub(' ', '\ ')} 2>&1"
      output = `#{command}`

      response = Fission::Response.new :code => 0

      output.strip.to_i > 0 ? response.data = true : response.data = false

      response
    end

  end
end
