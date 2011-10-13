module Fission
  class Lease

    # Public: Get/set the IP address for the lease.
    attr_accessor :ip_address

    # Public: Get/set the MAC address for the lease.
    attr_accessor :mac_address

    # Public: Get/set the start DateTime for the lease.
    attr_accessor :start

    # Public: Get/set the end DateTime for the lease.
    attr_accessor :end

    def initialize(args={})
      @ip_address = args[:ip_address]
      @mac_address = args[:mac_address]
      @start = args[:start]
      @end = args[:end]
    end

    # Public: Determine if the lease has expired or not.
    #
    # Examples:
    #
    #   @lease.expired?
    #   # => true
    #
    # Returns a Boolean.  The Boolean is determined by comparing the end
    # attribute to the current date/time.
    def expired?
      @end < DateTime.now
    end

    # Public: Provides all of the known leases.
    #
    # Examples:
    #
    #   Fission::Lease.all
    #
    # Returns a Response object.  If the Response is successful, the data
    # attribute of the Response will be an Array of Lease objects.  If the
    # Response is successful and there are no leases found, then the data
    # attribute of the Response will be an empty Array.
    def self.all
      leases = []
      response = Response.new

      if File.file? Fission.config['lease_file']
        content = File.read Fission.config['lease_file']

        content.split('}').each do |entry|
          lease = Lease.new

          entry.split("\n").each do |line|
            next if line =~ /^#/

              line.gsub! ';', ''

            case line.strip
            when /^lease/
              lease.ip_address = line.split(' ')[1]
            when /^starts/
              lease.start = DateTime.parse(line.split(' ')[2..3].join(' '))
            when /^end/
            lease.end = DateTime.parse(line.split(' ')[2..3].join(' '))
            when /^hardware/
              lease.mac_address = line.split(' ')[2]
            end

          end

          leases << lease
        end

        content = nil

        response.code = 0
        response.data = leases
      else
        response.code = 1
        response.output = "Unable to find the lease file '#{Fission.config['lease_file']}'"
      end

      response
    end

    # Public: Get lease information for a specific MAC address.
    #
    # mac_address - MAC address to search for.
    #
    # Examples
    #
    #   Fission::Lease.find_by_mac
    #
    # Returns a Response object.  If the Response is successful and the MAC
    # address was found, the data attribute of the Response object will be a
    # Lease object.  If the MAC address was not found, then the data attribute
    # of the Response object will be nil.
    def self.find_by_mac_address(mac_address)
      all_response = all

      if all_response.successful?
        response = Response.new :code => 0
        response.data = all_response.data.find { |l| l.mac_address == mac_address }
      else
        response = all_response
      end

      response
    end

  end
end
