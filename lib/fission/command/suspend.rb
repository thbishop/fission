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

        if @args.count != 1 && !@options.all
          output self.class.help
          output ''
          output_and_exit 'Incorrect arguments for suspend command', 1
        end

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
          end
        else
          vm = VM.new @args.first

          ensure_vm_exists vm

          state_response = vm.state

          if state_response.successful?
            if state_response.data != 'running'
              output ''
              output_and_exit "VM '#{vm.name}' is not running", 1
            end
          else
            output_and_exit "There was an error getting the list of running VMs.  The error was:\n#{state_response.message}", state_response.code
          end

          vms = [vm]
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
