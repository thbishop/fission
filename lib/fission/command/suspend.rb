module Fission
  class Command
    class Suspend < Command

      def initialize(args=[])
        super
        @options.all = false
      end

      def execute
        option_parser.parse! @args

        if args.count != 1 && !@options.all
          Fission.ui.output self.class.help
          Fission.ui.output ""
          Fission.ui.output_and_exit "Incorrect arguments for suspend command", 1
        end

        vms_to_suspend.each do |vm_name|
          Fission.ui.output "suspending '#{vm_name}'"
          Fission::VM.new(vm_name).suspend
        end
      end

      def vms_to_suspend
        if @options.all
          vms_to_suspend = VM.all_running
        else
          vm_name = args.first
          unless Fission::VM.exists? vm_name
            Fission.ui.output ''
            Fission.ui.output_and_exit "Unable to find the VM #{vm_name} (#{Fission::VM.path(vm_name)})", 1
          end

          unless VM.all_running.include?(vm_name)
            Fission.ui.output ''
            Fission.ui.output_and_exit "VM '#{vm_name}' is not running", 1
          end

          vms_to_suspend = [vm_name]
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nsuspend usage: fission suspend vm"

          opts.on '--all', 'Suspend all running VMs' do
            @options.all = true
          end
        end

        optparse
      end

    end
  end
end
