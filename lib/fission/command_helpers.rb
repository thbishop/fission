module Fission
  module CommandHelpers

    # Public: Checks for the existence of a VM.
    #
    # vm - Fission VM object to look for.
    #
    # Examples
    #
    #   ensure_vm_exists 'foo'
    #
    # Returns nothing.
    # If the VM does not exist, then an error will be output and it will exit
    # with an exit code of 1.
    # If the VM exists, nothing will be output.
    def ensure_vm_exists(vm)
      unless vm.exists?
        output_and_exit "Unable to find the VM '#{vm.name}' (#{VM.path(vm.name)})", 1
      end
    end

  end
end
