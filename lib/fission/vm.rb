module Fission
  class VM

    def self.exists?(vm_name)
      File.directory? path(vm_name)
    end

    def self.path(vm_name)
      File.join(Fission.config.attributes['vm_dir'], "#{vm_name}.vmwarevm").gsub '\\', ''
    end

    def self.clone(source_vm, target_vm)
      FileUtils.cp_r path(source_vm), path(target_vm)

      rename_vm_files(source_vm, target_vm)
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

  end
end
