module Fission
  class Command
    class Stop < Command
      include Fission::CommandHelpers

      def execute
        incorrect_arguments 'stop' unless @args.count == 1

        vm = VM.new @args.first

        output "Stopping '#{vm.name}'"
        response = vm.stop

        if response.successful?
          output "VM '#{vm.name}' stopped"
        else
          output_and_exit "There was an error stopping the VM.  The error was:\n#{response.message}", response.code
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
