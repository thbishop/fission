module Fission
  class Command
    class Stop < Command

      def execute
        unless @args.count == 1
          output self.class.help
          output ''
          output_and_exit 'Incorrect arguments for stop command', 1
        end

        vm_name = @args.first

        exists_response = VM.exists? vm_name

        if exists_response.successful?
          unless exists_response.data
            output_and_exit "Unable to find the VM '#{vm_name}' (#{VM.path(vm_name)})", 1
          end
        end

        response = VM.all_running

        if response.successful?
          unless response.data.include?(vm_name)
            output ''
            output_and_exit "VM '#{vm_name}' is not running", 0
          end
        else
          output_and_exit "There was an error determining if the VM is already running.  The error was:\n#{response.output}", response.code
        end

        output "Stopping '#{vm_name}'"
        @vm = VM.new vm_name
        response = @vm.stop

        if response.successful?
          output "VM '#{vm_name}' stopped"
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
