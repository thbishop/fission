module Fission
  module CommandHelpers

    # Public: Checks for the existence of a VM and outputs and error and exits
    # if it is not found.
    #
    # vm_name - The name of the VM to look for.
    #
    # Examples
    #
    #   ensure_vm_exists 'foo'
    #
    # Returns nothing.
    def ensure_vm_exists(vm_name)
      exists_response = VM.exists? vm_name

      if exists_response.successful?
        unless exists_response.data
          output_and_exit "Unable to find the VM '#{vm_name}' (#{VM.path(vm_name)})", 1
        end
      end

    end

  end
end
