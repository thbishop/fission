module Fission
  class Fusion

    # Public: Determines if the VMware Fusion GUI application is running.
    #
    # Examples
    #
    #   Fission::Fusion.running?
    #   # => true
    #
    # Returns a Fission Response object.
    # If the Response object is successful, the data attribute will be a
    # Boolean.  If the Response object is unsuccessful, the data attribute will
    # be nil.
    def self.running?
      command = "ps -ef | grep -v grep | grep -c "
      command << "#{Fission.config['gui_bin'].gsub(' ', '\ ')} 2>&1"
      output = `#{command}`

      response = Response.new :code => 0

      output.strip.to_i > 0 ? response.data = true : response.data = false

      response
    end

  end
end
