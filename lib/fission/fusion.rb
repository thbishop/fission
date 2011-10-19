module Fission
  class Fusion

    # Public: Determines if the VMware Fusion GUI application is running.
    #
    # Examples
    #
    #   Fission::Fusion.running?
    #   # => true
    #
    # Returns a Boolean.
    def self.running?
      command = "ps -ef | grep -v grep | grep -c "
      command << "#{Fission.config['gui_bin'].gsub(' ', '\ ')} 2>&1"
      output = `#{command}`

      output.strip.to_i > 0
    end

  end
end
