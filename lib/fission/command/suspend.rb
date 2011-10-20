module Fission
  class Command
    class Suspend < Command
      include Fission::CommandHelpers

      def initialize(args=[])
        super
        @options.all = false
      end

      def execute
        option_parser.parse! @args

        incorrect_arguments 'suspend' if @args.count != 1 && !@options.all

        vms_to_suspend.each do |vm|
          output "Suspending '#{vm.name}'"
          response = vm.suspend

          if response.successful?
            output "VM '#{vm.name}' suspended"
          else
            output_and_exit "There was an error suspending the VM.  The error was:\n#{response.message}", response.code
          end
        end
      end

      def vms_to_suspend
        if @options.all
          response = VM.all_running

          if response.successful?
            vms = response.data
          else
            output_and_exit "There was an error getting the list of running VMs.  The error was:\n#{response.message}", response.code
          end
        else
          vms = [ VM.new(@args.first) ]
        end

        vms
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nsuspend usage: fission suspend [vm_name | --all]"

          opts.on '--all', 'Suspend all running VMs' do
            @options.all = true
          end
        end

        optparse
      end

    end
  end
end
