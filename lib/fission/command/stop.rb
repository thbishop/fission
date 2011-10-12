module Fission
  class Command
    class Stop < Command
      include Fission::CommandHelpers

      def execute
        unless @args.count == 1
          output self.class.help
          output ''
          output_and_exit 'Incorrect arguments for stop command', 1
        end

        vm_name = @args.first

        ensure_vm_exists vm_name

        vm = VM.new vm_name

        state_response = vm.state

        if state_response.successful?
          if state_response.data != 'running'
            output ''
            output_and_exit "VM '#{vm.name}' is not running", 0
          end
        else
          output_and_exit "There was an error determining if the VM is already running.  The error was:\n#{state_response.output}", state_response.code
        end

        output "Stopping '#{vm.name}'"
        response = vm.stop

        if response.successful?
          output "VM '#{vm.name}' stopped"
        else
          output_and_exit "There was an error stopping the VM.  The error was:\n#{response.output}", response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nstop usage: fission stop vm_name"
        end

        optparse
      end

    end
  end
end
