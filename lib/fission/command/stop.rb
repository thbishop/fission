module Fission
  class Command
    class Stop < Command

      def execute
        unless @args.count == 1
          Fission.ui.output self.class.help
          Fission.ui.output ""
          Fission.ui.output_and_exit "Incorrect arguments for stop command", 1
        end

        vm_name = @args.first

        exists_response = Fission::VM.exists? vm_name

        if exists_response.successful?
          unless exists_response.data
            Fission.ui.output_and_exit "Unable to find the VM '#{vm_name}' (#{Fission::VM.path(vm_name)})", 1 
          end
        end

        response = Fission::VM.all_running

        if response.successful?
          unless response.data.include?(vm_name)
            Fission.ui.output ''
            Fission.ui.output_and_exit "VM '#{vm_name}' is not running", 0
          end
        else
          Fission.ui.output_and_exit "There was an error determining if the VM is already running.  The error was:\n#{response.output}", response.code
        end

        Fission.ui.output "Stopping '#{vm_name}'"
        @vm = Fission::VM.new vm_name
        response = @vm.stop

        if response.successful?
          Fission.ui.output "VM '#{vm_name}' stopped"
        else
          Fission.ui.output_and_exit "There was an error stopping the VM.  The error was:\n#{response.output}", response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nstop usage: fission stop vm"
        end

        optparse
      end

    end
  end
end
