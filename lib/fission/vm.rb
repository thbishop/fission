module Fission
  class VM
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def start
      command = "#{Fission.config.attributes['vmrun_cmd']} start #{conf_file.gsub ' ', '\ '} gui 2>&1"
      output = `#{command}`

      if $?.exitstatus == 0
        Fission.ui.output "VM started"
      else
        Fission.ui.output "There was a problem starting the VM.  The error was:\n#{output}"
      end
    end

    def stop
      command = "#{Fission.config.attributes['vmrun_cmd']} stop #{conf_file.gsub ' ', '\ '} 2>&1"
      output = `#{command}`

      if $?.exitstatus == 0
        Fission.ui.output "VM stopped"
      else
        Fission.ui.output "There was a problem stopping the VM.  The error was:\n#{output}"
      end
    end

    def suspend
      command = "#{Fission.config.attributes['vmrun_cmd']} suspend #{conf_file.gsub ' ', '\ '} 2>&1"
      output = `#{command}`

      if $?.exitstatus == 0
        Fission.ui.output "VM suspended"
      else
        Fission.ui.output "There was a problem suspending the VM.  The error was:\n#{output}"
      end
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

      vm_dirs.map { |d| File.basename d, '.vmwarevm' }
    end

    def self.all_running
      command = "#{Fission.config.attributes['vmrun_cmd']} list"

      output = `#{command}`

      vms = []

      if $?.exitstatus == 0
        output.split("\n").each do |vm|
          if vm.include?('.vmx')
            if File.exists?(vm) && (File.extname(vm) == '.vmx')
              vms << File.basename(vm, '.vmx')
            end
          end
        end
      else
        Fission.ui.output_and_exit "Unable to determine the list of running VMs", 1
      end

      vms
    end

    def self.exists?(vm_name)
      File.directory? path(vm_name)
    end

    def self.path(vm_name)
      File.join Fission.config.attributes['vm_dir'], "#{vm_name}.vmwarevm"
    end

    def self.clone(source_vm, target_vm)
      Fission.ui.output "Cloning #{source_vm} to #{target_vm}"
      FileUtils.cp_r path(source_vm), path(target_vm)

      Fission.ui.output "Configuring #{target_vm}"
      rename_vm_files source_vm, target_vm
      update_config source_vm, target_vm
    end

    private
    def self.rename_vm_files(from, to)
      files_to_rename(from, to).each do |file|
        FileUtils.mv File.join(path(to), file), File.join(path(to), file.gsub(from, to))
      end
    end

    def self.files_to_rename(from, to)
      Dir.entries(path(to)).select { |f| f.include?(from) }
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
