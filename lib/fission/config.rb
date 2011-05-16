module Fission
  class Config
    attr_accessor :attributes

    CONF_FILE = '~/.fissionrc'

    def initialize
      @attributes = {}
      load_from_file

      if @attributes['vm_dir'].blank?
        @attributes['vm_dir'] = File.expand_path('~/Documents/Virtual\ Machines.localized/')
      end
    end

    private
    def load_from_file
      if File.file?(CONF_FILE)
        @attributes.merge!(YAML.load_file(CONF_FILE))
      end
    end

  end
end
