module Fission
  class VM

    # Public: Gets the name of the VM as a String.
    attr_reader :name

    def initialize(name)
      @name = name
    end

    # Public: Creates a snapshot for a VM.  The VM must be running in order
    # to take a snapshot.
    #
    # name - The desired name of the snapshot.  The name must be unique.
    #
    # Examples
    #
    #   @vm.create_snapshot('foo_snap_1')
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be nil.
    # If there is an error, an unsuccessful Response will be returned.
    def create_snapshot(name)
      conf_file_response = conf_file
      return conf_file_response unless conf_file_response.successful?

      command = "#{vmrun_cmd} snapshot "
      command << "#{conf_file_response.data} \"#{name}\" 2>&1"

      Response.from_command(`#{command}`)
    end

    # Public: Reverts the VM to the specified snapshot.
    #
    # name - The snapshot name to revert to.
    #
    # Examples
    #
    #   @vm.revert_to_snapshot('foo_snap_1')
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be nil.
    # If there is an error, an unsuccessful Response will be returned.
    def revert_to_snapshot(name)
      conf_file_response = conf_file
      return conf_file_response unless conf_file_response.successful?

      command = "#{vmrun_cmd} revertToSnapshot "
      command << "#{conf_file_response.data} \"#{name}\" 2>&1"

      Response.from_command(`#{command}`)
    end

    # Public: List the snapshots for a VM.
    #
    # Examples
    #
    #   @vm.snapshots
    #
    # Returns a Response with the result.
    # If successful, the Repsonse's data attribute will be an Array of the
    # snapshot names (String).
    # If there is an error, an unsuccessful Response will be returned.
    def snapshots
      conf_file_response = conf_file
      return conf_file_response unless conf_file_response.successful?

      command = "#{vmrun_cmd} listSnapshots "
      command << "#{conf_file_response.data} 2>&1"
      output = `#{command}`

      response = Response.new :code => $?.exitstatus

      if response.successful?
        snaps = output.split("\n").select { |s| !s.include? 'Total snapshots:' }
        response.data = snaps.map { |s| s.strip }
      else
        response.output = output
      end

      response
    end

    # Public: Starts a VM.  The VM must not be running in order to start it.
    #
    # options - Hash of options:
    #           :headless - Boolean which specifies to start the VM without a
    #                       GUI console.  If the VMware Fusion GUI interface is
    #                       not running, it will not be started.
    #                       (default: false)
    #
    # Examples
    #
    #   @vm.start
    #
    #   @vm.start(:headless => true)
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be nil.
    # If there is an error, an unsuccessful Response will be returned.
    def start(args={})
      conf_file_response = conf_file
      return conf_file_response unless conf_file_response.successful?

      command = "#{vmrun_cmd} start "
      command << "#{conf_file_response.data} "

      command << (args[:headless].blank? ? 'gui ' : 'nogui ')
      command << '2>&1'

      Response.from_command(`#{command}`)
    end

    # Public: Stops a VM.  The VM must be running in order to stop it.
    #
    # Examples
    #
    #   @vm.stop
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be nil.
    # If there is an error, an unsuccessful Response will be returned.
    def stop
      conf_file_response = conf_file
      return conf_file_response unless conf_file_response.successful?

      command = "#{vmrun_cmd} stop "
      command << "#{conf_file_response.data} 2>&1"

      Response.from_command(`#{command}`)
    end

    # Public: Suspends a VM.  The VM must be running in order to suspend it.
    #
    # Examples
    #
    #   @vm.suspend
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be nil.
    # If there is an error, an unsuccessful Response will be returned.
    def suspend
      conf_file_response = conf_file
      return conf_file_response unless conf_file_response.successful?

      command = "#{vmrun_cmd} suspend "
      command << "#{conf_file_response.data} 2>&1"

      Response.from_command(`#{command}`)
    end

    # Public: MAC addresses for a VM.
    #
    # Examples:
    #
    #   @vm.mac_addresses.data
    #   # => ['00:0c:29:1d:6a:64', '00:0c:29:1d:6a:75']
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be an Array of the MAC
    # addresses found.  If no MAC addresses are found, the Response's data
    # attribute will be an empty Array.
    # If there is an error, an unsuccessful Response will be returned.
    def mac_addresses
      network_response = network_info

      if network_response.successful?
        response = Response.new :code => 0
        response.data = network_response.data.values.collect { |n| n['mac_address'] }
      else
        response = network_response
      end

      response
    end

    # Public: Network information for a VM.  Includes interface name, associated
    # MAC address, and IP address (if applicable).
    #
    # Examples:
    #
    #   # if IP addresses are found in the VMware Fusion DHCP lease file
    #   response = @vm.network_info.data
    #   # => { 'ethernet0' => { 'mac_address' => '00:0c:29:1d:6a:64',
    #                           'ip_address'  => '127.0.0.1' },
    #          'ethernet1' => { 'mac_address' => '00:0c:29:1d:6a:75',
    #                           'ip_address'  => '127.0.0.2' } }
    #
    #   # if IP addresses are not found in the VMware Fusion DHCP lease file
    #   response = @vm.network_info.data
    #   # => { 'ethernet0' => { 'mac_address' => '00:0c:29:1d:6a:64',
    #                           'ip_address'  => nil },
    #          'ethernet1' => { 'mac_address' => '00:0c:29:1d:6a:75',
    #                           'ip_address'  => nil } }
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be a Hash with the
    # interface identifiers as the keys and the associated MAC address.  If an
    # IP address was found in the VMware Fusion DHCP lease file, then it will
    # be included.  If an IP address was not found, then the IP address value
    # will be nil.  If there are no network interfaces, the Response's data
    # attribute will be an empty Hash.
    # If there is an error, an unsuccessful Response will be returned.
    def network_info
      conf_file_response = conf_file
      return conf_file_response unless conf_file_response.successful?

      response = Response.new :code => 0, :data => {}

      interface_pattern = /^ethernet\d+/
      mac_pattern = /(\w\w[:-]\w\w[:-]\w\w[:-]\w\w[:-]\w\w[:-]\w\w)/

      File.open conf_file_response.data, 'r' do |f|
        f.grep(mac_pattern).each do |line|
          int = line.scan(interface_pattern)[0]
          mac = line.scan(mac_pattern)[0].first
          response.data[int] = {}
          response.data[int]['mac_address'] = mac

          lease_response = Fission::Lease.find_by_mac_address mac

          if lease_response.successful?
            response.data[int]['ip_address'] = nil

            if lease_response.data
              response.data[int]['ip_address'] = lease_response.data.ip_address
            end
          else
            return lease_response
          end

        end
      end

      response
    end

    # Public: Provides the state of the VM.
    #
    # Examples
    #
    #   @vm.state.data
    #   # => 'running'
    #
    #   @vm.state.data
    #   # => 'not running'
    #
    #   @vm.state.data
    #   # => 'suspended'
    #
    # Returns a Response with the result.
    # If the Response is successful, the Response's data attribute will
    # be a String of the state.  If the VM is currently powered on, the state
    # will be 'running'.  If the VM is deemed to be suspended, the state will be
    # 'suspended'.  If the VM is not running and not deemed to be suspended, the
    # state will be 'not running'.
    # If there is an error, an unsuccessful Response will be returned.
    def state
      response = Response.new :code => 0

      running_response = self.class.all_running

      return running_response unless running_response.successful?

      if running_response.data.collect { |v| v.name }.include? name
        response.data = 'running'
      else
        suspended_response = suspended?

        return suspended_response unless suspended_response.successful?

        if suspended_response.data
          response.data = 'suspended'
        else
          response.data = 'not running'
        end
      end

      response
    end

    # Public: Determines if the VM exists or not.  This method only looks in the
    # VM directory.
    #
    # Examples
    #
    #   @vm.exists?.data
    #   # => true
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be a Boolean of
    # whether the VM exists or not.
    # If there is an error, an unsuccessful Response will be returned.
    def exists?
      self.class.exists? name
    end

    # Public: Determines if a VM is suspended.
    #
    # Examples
    #
    #   @vm.suspended?.data
    #   # => true
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be a Boolean.  If the VM
    # is not running, then this method will look for a '.vmem' file in the VM's
    # directory.  If a '.vmem' file exists and it matches the name of the VM,
    # then the VM is considered to be suspended.  If the VM is running or if a
    # matching '.vmem' file is not found, then the VM is not considered to be
    # suspended.
    # If there is an error, an unsuccessful Response will be returned.
    def suspended?
      response = Response.new :code => 0, :data => false

      running_response = self.class.all_running

      return running_response unless running_response.successful?

      if running_response.data.collect { |v| v.name }.include? name
        response.data = false
      else
        if File.file?(File.join(self.class.path(name), "#{name}.vmem"))
          response.data = true
        else
          response.data = false
        end
      end

      response
    end

    # Public: Determines the path to the VM's config file ('.vmx').
    #
    # Examples
    #
    #   @vm.conf_file
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be a String which will be
    # escaped for spaces (' ').
    # If there is a single '.vmx' file in the VM's directory, regardless if
    # the name of '.vmx' file matches the VM name, the Response's data
    # attribute will the be the path to the '.vmx' file.
    # If there are multiple '.vmx' files found in the VM's directory, there are
    # a couple of different possible outcomes.
    # If one of the file names matches the VM directory name, then the
    # Response's data attribute will be the path to the matching '.vmx' file.
    # If none of the file names match the VM directory name, then this is deemed
    # an error condition and an unsuccessful Response will be returned.
    # If there is an error, an unsuccessful Response will be returned.
    def conf_file
      vmx_path = File.join(self.class.path(@name), "*.vmx")
      conf_files = Dir.glob(vmx_path)
      response = Response.new

      case conf_files.count
      when 0
        response.code = 1
        response.output = "Unable to find a config file for VM '#{@name}' (in '#{vmx_path}')"
      when 1
        response.code = 0
        response.data = conf_files.first
      else
        if conf_files.include?(File.join(File.dirname(vmx_path), "#{@name}.vmx"))
          response.code = 0
          response.data = File.join(File.dirname(vmx_path), "#{@name}.vmx")
        else
          response.code = 1
          output = "Multiple config files found for VM '#{@name}' ("
          output << conf_files.sort.map { |f| "'#{File.basename(f)}'" }.join(', ')
          output << " in '#{File.dirname(vmx_path)}')"
          response.output = output
        end
      end

      response.data.gsub! ' ', '\ ' if response.successful?

      response
    end

    # Public: Provides all of the VMs which are located in the VM directory.
    #
    # Examples
    #
    #   Fission::VM.all
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be an Array of VM
    # objects.  If no VMs are found, the Response's data attribute will be an
    # empty Array.
    # If there is an error, an unsuccessful Response will be returned.
    def self.all
      vm_dirs = Dir[File.join Fission.config['vm_dir'], '*.vmwarevm'].select do |d|
        File.directory? d
      end

      response = Response.new :code => 0
      response.data = vm_dirs.collect { |d| new(File.basename d, '.vmwarevm') }

      response
    end

    # Public: Provides all of the VMs which are currently running.
    #
    # Examples
    #
    #   Fission::VM.all_running
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be an Array of VM
    # objects which are running.  If no VMs are running, the Response's data
    # attribute will be an empty Array.
    # If there is an error, an unsuccessful Response will be returned.
    def self.all_running
      command = "#{Fission.config['vmrun_cmd']} list"

      output = `#{command}`

      response = Response.new :code => $?.exitstatus

      if response.successful?
        vms = output.split("\n").select do |vm|
          vm.include?('.vmx') && File.exists?(vm) && File.extname(vm) == '.vmx'
        end

        response.data = vms.collect do |vm|
          new File.basename(File.dirname(vm), '.vmwarevm')
        end
      else
        response.output = output
      end

      response
    end

    # Public: Determines if a VM exists or not.  This method only looks in the
    # VM directory.
    #
    # name - The name of the VM to look for.
    #
    # Examples
    #
    #   Fission::VM.exists? 'foo'
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be a Boolean of
    # whether the VM exists or not.
    # If there is an error, an unsuccessful Response will be returned.
    def self.exists?(vm_name)
      Response.new :code => 0, :data => (File.directory? path(vm_name))
    end

    # Public: Provides the expected path to a VM.  This does not imply that the
    # VM exists.
    #
    # name - The name of the VM to provide the path for.
    #
    # Examples
    #   Fission::VM.path 'foo'
    #
    # Returns the path (String) to the VM's directory.
    def self.path(vm_name)
      File.join Fission.config['vm_dir'], "#{vm_name}.vmwarevm"
    end

    # Public: Creates a new VM which is a clone of an existing VM.  As Fusion
    # doesn't provide a native cloning mechanism, this is a best
    # effort.  This essentially is a directory copy with updates to relevant
    # files.  It's recommended to clone VMs which are not running.
    #
    # source_vm - The name of the VM to clone.
    # target_vm - The name of the VM to be created.
    #
    # Examples
    #
    #   Fission::VM.clone 'foo', 'bar'
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be nil.
    # If there is an error, an unsuccessful Response will be returned.
    def self.clone(source_vm, target_vm)
      FileUtils.cp_r path(source_vm), path(target_vm)

      rename_vm_files source_vm, target_vm
      update_config source_vm, target_vm

      Response.new :code => 0
    end

    # Public: Deletes a VM.  As there are a number issues with the Fusion
    # command line tool for deleting VMs, this is a best effort.  The VM should
    # not be running when this method is called.  This essentially deletes the
    # VM directory and attempts to remove the relevant entries from the Fusion
    # plist file.  It's highly recommended to delete VMs without the Fusion GUI
    # application running.  If the Fusion GUI is running this method should
    # succeed, but it's been observed that Fusion will recreate the plist data
    # which is deleted.  This leads to 'missing' VMs in the Fusion GUI.
    #
    # Examples
    #
    #   @vm.delete
    #
    # Returns a Response with the result.
    # If successful, the Response's data attribute will be nil.
    # If there is an error, an unsuccessful Response will be returned.
    def delete
      FileUtils.rm_rf VM.path(@name)
      Metadata.delete_vm_info(VM.path(@name))

      Response.new :code => 0
    end

    private
    # Private: Renames the files of a newly cloned VM.
    #
    # from - The VM name that was used as the source of the clone.
    # to   - The name of the newly cloned VM.
    #
    # Examples
    #
    #   Fission::VM.rename_vm_files 'foo', 'bar'
    #
    # Returns nothing.
    def self.rename_vm_files(from, to)
      files_to_rename(from, to).each do |file|
        text_to_replace = File.basename(file, File.extname(file))

        if File.extname(file) == '.vmdk'
          if file.match /\-s\d+\.vmdk/
            text_to_replace = file.partition(/\-s\d+.vmdk/).first
          end
        end

        unless File.exists?(File.join(path(to), file.gsub(text_to_replace, to)))
          FileUtils.mv File.join(path(to), file),
                       File.join(path(to), file.gsub(text_to_replace, to))
        end
      end
    end

    # Private: Provides the list of files which need to be renamed in a newly
    # cloned VM directory.
    #
    # from - The VM name that was used as the source of the clone.
    # to   - The name of the newly cloned VM.
    #
    # Examples
    #
    #   Fission::VM.files_to_rename 'foo', 'bar'
    #   # => ['/vms/vm1/foo.vmdk', '/vms/vm1/foo.vmx', 'vms/vm1/blah.other']
    #
    # Returns an Array containing the paths (String) to the files to rename.
    # The paths which match the from name will preceed any other files found in
    # the newly cloned VM directory.
    def self.files_to_rename(from, to)
      files_which_match_source_vm = []
      other_files = []

      Dir.entries(path(to)).each do |f|
        unless f == '.' || f == '..'
          f.include?(from) ? files_which_match_source_vm << f : other_files << f
        end
      end

      files_which_match_source_vm + other_files
    end

    # Private: Provides the list of file extensions for VM related files.
    #
    # Examples
    #
    #   Fission::VM.vm_file_extension
    #   # => ['.nvram', '.vmdk', '.vmem']
    #
    # Returns an Array containing the file extensions of VM realted files.
    # The file extensions returned are Strings and include a '.'.
    def self.vm_file_extensions
      ['.nvram', '.vmdk', '.vmem', '.vmsd', '.vmss', '.vmx', '.vmxf']
    end

    # Private: Updates config files for a newly cloned VM.  This will update any
    # files with the extension of '.vmx', '.vmxf', and '.vmdk'.  Any binary
    # '.vmdk' files will be skipped.
    #
    # from - The VM name that was used as the source of the clone.
    # to   - The name of the newly cloned VM.
    #
    # Examples
    #
    #   Fission::VM.update_config 'foo', 'bar'
    #
    # Returns nothing.
    def self.update_config(from, to)
      ['.vmx', '.vmxf', '.vmdk'].each do |ext|
        file = File.join path(to), "#{to}#{ext}"

        unless File.binary?(file)
          text = (File.read file).gsub from, to
          File.open(file, 'w'){ |f| f.print text }
        end

        clean_up_conf_file(file) if ext == '.vmx'
      end
    end

    # Private: Cleans up the conf file (*.vmx) for a newly cloned VM.  This
    # includes removing generated MAC addresses, setting up for a new UUID, and
    # disable VMware tools warning.
    #
    # conf_file_path - Aboslute path to the VM's conf file (.vmx).
    #
    # Examples
    #
    #   VM.clean_up_conf_file '/vms/foo/foo.vmx'
    #
    # Returns nothing.
    def self.clean_up_conf_file(conf_file_path)
      conf_items_patterns = [ /^tools\.remindInstall.*\n/,
                              /^uuid\.action.*\n/,
                              /^ethernet\.+generatedAddress.*\n/ ]

      content = File.read conf_file_path

      conf_items_patterns.each do |pattern|
        content.gsub(pattern, '').strip
      end

      content << "\n"
      content << "tools.remindInstall = \"FALSE\"\n"
      content << "uuid.action = \"create\"\n"

      File.open(conf_file_path, 'w') { |f| f.print content }
    end

    # Private: Helper for getting the configured vmrun_cmd value.
    #
    # Examples
    #
    #   @vm.vmrun_cmd
    #   # => "/foo/bar/vmrun -T fusion"
    #
    # Returns a String for the configured value of Fission.config['vmrun_cmd'].
    def vmrun_cmd
      Fission.config['vmrun_cmd']
    end

  end
end
