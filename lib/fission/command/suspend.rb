module Fission
  class Command
    class Suspend < Command

      def initialize(args=[])
        super
        @options.all = false
      end

      def execute
        option_parser.parse! @args

        if @args.count != 1 && !@options.all
          Fission.ui.output self.class.help
          Fission.ui.output ""
          Fission.ui.output_and_exit "Incorrect arguments for suspend command", 1
        end

        vms_to_suspend.each do |vm_name|
          Fission.ui.output "Suspending '#{vm_name}'"
          response = Fission::VM.new(vm_name).suspend

          if response.successful?
            Fission.ui.output "VM '#{vm_name}' suspended"
          else
            Fission.ui.output_and_exit "There was an error suspending the VM.  The error was:\n#{response.output}", response.code
          end
        end
      end

      def vms_to_suspend
        if @options.all
          response = Fission::VM.all_running
          if response.successful?
            vms = response.data
          end
        else
          vm_name = @args.first

          exists_response = Fission::VM.exists? vm_name

          if exists_response.successful?
            unless exists_response.data
              Fission.ui.output ''
              Fission.ui.output_and_exit "Unable to find the VM '#{vm_name}' (#{Fission::VM.path(vm_name)})", 1
            end
          end

          response = Fission::VM.all_running

          if response.successful?
            unless response.data.include?(vm_name)
              Fission.ui.output ''
              Fission.ui.output_and_exit "VM '#{vm_name}' is not running", 1
            end
          else
            Fission.ui.output_and_exit "There was an error getting the list of running VMs.  The error was:\n#{response.output}", response.code
          end

          vms = [vm_name]
        end

        vms
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nsuspend usage: fission suspend [vm | --all]"

          opts.on '--all', 'Suspend all running VMs' do
            @options.all = true
          end
        end

        optparse
      end

    end
  end
end
