module Fission
  class VM
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def create_snapshot(name)
      command = "#{Fission.config.attributes['vmrun_cmd']} snapshot #{conf_file.gsub ' ', '\ '} \"#{name}\" 2>&1"
      output = `#{command}`

      response = Fission::Response.new :code => $?.exitstatus
      response.output = output unless response.successful?
      response
    end

    def revert_to_snapshot(name)
      command = "#{Fission.config.attributes['vmrun_cmd']} revertToSnapshot #{conf_file.gsub ' ', '\ '} \"#{name}\" 2>&1"
      output = `#{command}`

      response = Fission::Response.new :code => $?.exitstatus
      response.output = output unless response.successful?
      response
    end

    def snapshots
      command = "#{Fission.config.attributes['vmrun_cmd']} listSnapshots #{conf_file.gsub ' ', '\ '} 2>&1"
      output = `#{command}`

      response = Fission::Response.new :code => $?.exitstatus

      if response.successful?
        snaps = output.split("\n").select { |s| !s.include? 'Total snapshots:' }
        response.data = snaps.map { |s| s.strip }
      else
        response.output = output
      end

      response
    end

    def start(args={})
      command = "#{Fission.config.attributes['vmrun_cmd']} start #{conf_file.gsub ' ', '\ '} "

      if !args[:headless].blank? && args[:headless]
        command << "nogui 2>&1"
      else
        command << "gui 2>&1"
      end

      output = `#{command}`

      response = Fission::Response.new :code => $?.exitstatus
      response.output = output unless response.successful?
      response
    end

    def stop
      command = "#{Fission.config.attributes['vmrun_cmd']} stop #{conf_file.gsub ' ', '\ '} 2>&1"
      output = `#{command}`

      response = Fission::Response.new :code => $?.exitstatus
      response.output = output unless response.successful?
      response
    end

    def suspend
      command = "#{Fission.config.attributes['vmrun_cmd']} suspend #{conf_file.gsub ' ', '\ '} 2>&1"
      output = `#{command}`

      response = Fission::Response.new :code => $?.exitstatus
      response.output = output unless response.successful?
      response
    end

    def conf_file
      vmx_path = File.join(self.class.path(@name), "*.vmx")
      conf_files = Dir.glob(vmx_path)

      case conf_files.count
      when 0
        Fission.ui.output_and_exit "Unable to find a config file for VM '#{@name}' (in '#{vmx_path}')", 1
      when 1
        conf_files.first
      else
        if conf_files.include?(File.join(File.dirname(vmx_path), "#{@name}.vmx"))
          File.join(File.dirname(vmx_path), "#{@name}.vmx")
        else
          output = "Multiple config files found for VM '#{@name}' ("
          output << conf_files.sort.map { |f| "'#{File.basename(f)}'" }.join(', ')
          output << " in '#{File.dirname(vmx_path)}')"
          Fission.ui.output_and_exit output, 1
        end
      end
    end

    def self.all
      vm_dirs = Dir[File.join Fission.config.attributes['vm_dir'], '*.vmwarevm'].select do |d|
        File.directory? d
      end

      response = Fission::Response.new :code => 0
      response.data = vm_dirs.map { |d| File.basename d, '.vmwarevm' }

      response
    end

    def self.all_running
      command = "#{Fission.config.attributes['vmrun_cmd']} list"

      output = `#{command}`

      response = Fission::Response.new :code => $?.exitstatus

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

    def self.exists?(vm_name)
      Response.new :code => 0, :data => (File.directory? path(vm_name))
    end

    def self.path(vm_name)
      File.join Fission.config.attributes['vm_dir'], "#{vm_name}.vmwarevm"
    end

    def self.clone(source_vm, target_vm)
      FileUtils.cp_r path(source_vm), path(target_vm)

      rename_vm_files source_vm, target_vm
      update_config source_vm, target_vm

      response = Response.new :code => 0
    end

    def self.delete(vm_name)
      FileUtils.rm_rf path(vm_name)
      Fission::Metadata.delete_vm_info(path(vm_name))

      Response.new :code => 0
    end

    private
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

    def self.vm_file_extensions
      ['.nvram', '.vmdk', '.vmem', '.vmsd', '.vmss', '.vmx', '.vmxf']
    end

    def self.update_config(from, to)
      ['.vmx', '.vmxf', '.vmdk'].each do |ext|
        file = File.join path(to), "#{to}#{ext}"

        unless File.binary?(file)
          text = (File.read file).gsub from, to
          File.open(file, 'w'){ |f| f.print text }
        end
      end
    end

  end
end
