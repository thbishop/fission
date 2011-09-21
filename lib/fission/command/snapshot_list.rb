module Fission
  class Command
    class SnapshotList < Command

      def initialize(args=[])
        super
      end

      def execute
        unless @args.count == 1
          Fission.ui.output self.class.help
          Fission.ui.output ""
          Fission.ui.output_and_exit "Incorrect arguments for snapshot list command", 1
        end

        vm_name = @args.first

        unless Fission::VM.exists? vm_name
          Fission.ui.output_and_exit "Unable to find the VM #{vm_name} (#{Fission::VM.path(vm_name)})", 1 
        end

        @vm = Fission::VM.new vm_name
        response = @vm.snapshots

        if response.successful?
          snaps = response.data

          if snaps.any?
            Fission.ui.output snaps.join("\n")
          else
            Fission.ui.output "No snapshots found for VM '#{vm_name}'"
          end
        else
          Fission.ui.output_and_exit "There was an error listing the snapshots.  The error was:\n#{response.output}", response.code
        end
      end

      def option_parser
        optparse = OptionParser.new do |opts|
          opts.banner = "\nsnapshot list: fission snapshot list my_vm"
        end

        optparse
      end

    end
  end
end
