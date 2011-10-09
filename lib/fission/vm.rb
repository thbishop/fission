module Fission
  class VM

    # Public: Returns the name (String).
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
    # Returns a Fission ResponseObject with the result.
    # If successful, the ResponseObject's data attribute will be nil.
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
    # Returns a Fission ResponseObject with the result.
    # If successful, the ResponseObject's data attribute will be nil.
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
    # Returns a Fission ResponseObject with the result.
    # If successful, the RepsonseObject's data attribute will be an array of 
    # the snapshot names (String)
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
    # Returns a Fission ResponseObject with the result.
    # If successful, the ResponseObject's data attribute will be nil.
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
    # Returns a Fission ResponseObject with the result.
    # If successful, the ResponseObject's data attribute will be nil.
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
    # Returns a Fission ResponseObject with the result.
    # If successful, the ResponseObject's data attribute will be nil.
    def suspend
      conf_file_response = conf_file
      return conf_file_response unless conf_file_response.successful?

      command = "#{vmrun_cmd} suspend "
      command << "#{conf_file_response.data} 2>&1"

      Response.from_command(`#{command}`)
    end

    # Public: Network information for a VM.  Includes interface name and
    # associated mac address.
    #
    # Examples:
    #
    #   response = @vm.network_info.data
    #   # => { 'ethernet0' => { 'mac' => '00:0c:29:1d:6a:64' },
    #          'ethernet1' => { 'mac' => '00:0c:29:1d:6a:75'} }
    #
    # Returns a Fission ResponseObject with the result.
    # If successful, the ResponseObject's data attribute will be a Hash with
    # the interface identifiers as the keys and the associated mac address as
    # the value.  If there are no network interfaces, the ResponseObject's data
    # attribute will be an empty Hash.
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
          response.data[int]['mac'] = mac
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
    # Returns a Fission ResponseObject with the result.
    # If there is a single '.vmx' file in the VM's directory, regardless if
    # the name of '.vmx' file matches the VM name, the ResponseObject's data
    # attribute will the path to the '.vmx' file (String).
    # If there are multiple '.vmx' files found in the VM's directory, there are
    # a couple of different outcomes.
    # If one of the file names matches the VM directory name, then the
    # ReponseObject's data attribute will be the path to the matching '.vmx'
    # file (String).
    # If none of the file names match the VM directory name, then the
    # ReponseObject's data attribute will be set to nil as this is deemed an
    # error condition.
    # When a path (String) is returned, it will be escaped for spaces (' ').
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
    # Returns a Fission ResponseObject with the result.
    # If successful, the ResponseObject's data attribute will be an array with
    # the VM names (String).
    def self.all
      vm_dirs = Dir[File.join Fission.config['vm_dir'], '*.vmwarevm'].select do |d|
        File.directory? d
      end

      response = Response.new :code => 0
      response.data = vm_dirs.map { |d| File.basename d, '.vmwarevm' }

      response
    end

    # Public: Provides all of the VMs which are currently running.
    #
    # Examples
    #
    #   Fission::VM.all_running
    #
    # Returns a Fission ResponseObject with the result.
    # If successful, the ResponseObject's data attribute will be an arry with
    # the names of the VMs (String) which are running.
    def self.all_running
      command = "#{Fission.config['vmrun_cmd']} list"

      output = `#{command}`

      response = Response.new :code => $?.exitstatus

      if response.successful?
        vms = output.split("\n").select do |vm|
          vm.include?('.vmx') && File.exists?(vm) && File.extname(vm) == '.vmx'
        end

        response.data = vms.map { |vm| File.basename(File.dirname(vm), '.vmwarevm') }
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
    # Returns a Fission ResponseObject with the result.
    # If successful, the ResponseObject's data attribute will be a Boolean of
    # whether the VM exists or not.
    def self.exists?(vm_name)
      Response.new :code => 0, :data => (File.directory? path(vm_name))
    end

    # Public: Provides the path to a VM.
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
    # Returns a Fission ResponseObject with the result.
    # If successful, the ResponseObject's data attribute will be nil.
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
    # Returns a Fission ResponseObject with the result.
    # If successful, the ResponseObject's data attribute will be nil.
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
      end
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
